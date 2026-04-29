#!/usr/bin/env python3
"""
opencode_switch.py - Find idle/error opencode instances and switch to their tmux sessions.

Workflow:
  1. Find all opencode processes that expose an HTTP API (started with --port).
  2. For each, resolve its listening port and working directory.
  3. Query the API to find the most recently updated session for that directory.
  4. Determine whether the session is idle or in an error state.
  5. Locate the exact tmux pane running that opencode process by walking the
     process tree upward and matching against `tmux list-panes -a` pane PIDs.
  6. Present matching instances via fzf and switch to the corresponding tmux
     session:window.pane.
"""

import json
import os
import subprocess
import sys
import urllib.request
import urllib.error
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------

@dataclass
class OpencodeInstance:
    pid: int
    port: int
    cwd: Path


@dataclass
class SessionInfo:
    session_id: str
    slug: str
    directory: str
    state: str          # "idle" | "error" | "in_progress" | "awaiting_input" | "unknown"
    title: str


@dataclass
class TmuxTarget:
    """Identifies an exact tmux pane by session name, window index, and pane index."""
    session: str
    window: int
    pane: int

    def address(self) -> str:
        """Return the tmux target address string, e.g. 'mysession:0.1'."""
        return f"{self.session}:{self.window}.{self.pane}"


@dataclass
class Candidate:
    instance: OpencodeInstance
    session: SessionInfo
    tmux_target: Optional[TmuxTarget]


# ---------------------------------------------------------------------------
# Step 1 & 2: Discover opencode processes and their ports
# ---------------------------------------------------------------------------

def find_opencode_instances() -> list[OpencodeInstance]:
    """Return opencode processes that are listening on a TCP port."""
    instances: list[OpencodeInstance] = []

    try:
        pids = subprocess.check_output(["pgrep", "-x", "opencode"], text=True).split()
    except subprocess.CalledProcessError:
        return instances  # no opencode processes running

    for pid_str in pids:
        pid = int(pid_str.strip())

        # Find the listening TCP port for this PID
        port = _get_listening_port(pid)
        if port is None:
            continue

        # Resolve working directory
        try:
            cwd = Path(os.readlink(f"/proc/{pid}/cwd"))
        except OSError:
            continue

        instances.append(OpencodeInstance(pid=pid, port=port, cwd=cwd))

    return instances


def _get_listening_port(pid: int) -> Optional[int]:
    """Use `ss` to find the TCP port that the given PID is listening on."""
    try:
        out = subprocess.check_output(
            ["ss", "-tlnp"],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

    for line in out.splitlines():
        if f"pid={pid}," not in line:
            continue
        # Local address field is the 4th column: 127.0.0.1:4096
        parts = line.split()
        if len(parts) < 4:
            continue
        local_addr = parts[3]
        if ":" in local_addr:
            try:
                return int(local_addr.rsplit(":", 1)[1])
            except ValueError:
                continue

    return None


# ---------------------------------------------------------------------------
# Step 3 & 4: Query sessions and determine state
# ---------------------------------------------------------------------------

def _http_get(url: str, timeout: int = 5) -> Optional[object]:
    """Perform a GET request and return parsed JSON, or None on failure."""
    try:
        with urllib.request.urlopen(url, timeout=timeout) as resp:
            return json.load(resp)
    except (urllib.error.URLError, json.JSONDecodeError, OSError):
        return None


def get_current_session(instance: OpencodeInstance) -> Optional[SessionInfo]:
    """
    Find the most recently updated session whose directory matches the instance CWD.
    Falls back to the globally most-recent session if nothing matches the CWD.
    """
    base = f"http://127.0.0.1:{instance.port}"
    sessions = _http_get(f"{base}/session")
    if not isinstance(sessions, list) or not sessions:
        return None

    cwd_str = str(instance.cwd)

    # Filter to sessions whose directory starts with (or equals) the instance CWD
    matching = [s for s in sessions if s.get("directory", "").startswith(cwd_str)]

    # If nothing matched, fall back to most-recently-updated globally
    pool = matching if matching else sessions
    pool_sorted = sorted(pool, key=lambda s: s.get("time", {}).get("updated", 0), reverse=True)

    for candidate in pool_sorted:
        sid = candidate.get("id", "")
        if not sid:
            continue
        messages = _http_get(f"{base}/session/{sid}/message")
        if not isinstance(messages, list):
            continue
        state = _determine_state(messages)
        return SessionInfo(
            session_id=sid,
            slug=candidate.get("slug", sid),
            directory=candidate.get("directory", ""),
            state=state,
            title=candidate.get("title", ""),
        )

    return None


def _determine_state(messages: list) -> str:
    """
    Infer the session state from the message list.

    States:
      idle          - assistant finished (finish=stop, time.completed set)
      in_progress   - assistant is actively generating (finish=None, time.completed absent)
      error         - message was interrupted (finish=None, time.completed set) or info.error present
      awaiting_input - last message is from the user (no assistant reply yet)
      unknown       - empty message list or unrecognised pattern
    """
    if not messages:
        return "unknown"

    # Check the tail message first.
    #
    # Opencode appends a skeleton assistant message at the start of each step
    # (cost=0, no finish, no time.completed) and fills it in when the step
    # completes.  If the tail is a skeleton, a turn is actively in flight —
    # report in_progress immediately without inspecting history.
    #
    # The previous approach walked backwards to find the "last substantive
    # message", but that inadvertently skipped user messages (which also have
    # no cost/finish/completed) and landed on the previous *completed* assistant
    # turn, producing a spurious "idle" result while the LLM was generating.
    tail_info = messages[-1].get("info", {})
    tail_cost = tail_info.get("cost")
    tail_completed = tail_info.get("time", {}).get("completed")
    tail_finish = tail_info.get("finish")

    if not tail_cost and tail_completed is None and tail_finish is None:
        # Tail is a skeleton — generation is in progress.
        return "in_progress"

    # Tail is a substantive message — evaluate it directly.
    role = tail_info.get("role", "")
    has_error = bool(tail_info.get("error"))

    if role == "user":
        return "awaiting_input"

    if has_error:
        return "error"

    if role == "assistant":
        if tail_finish is not None and tail_completed is not None:
            return "idle"
        if tail_finish is None and tail_completed is None:
            return "in_progress"
        if tail_finish is None and tail_completed is not None:
            # Message completed but finish reason was never set — treat as error/interrupted
            return "error"

    return "unknown"


# ---------------------------------------------------------------------------
# Step 5: Find matching tmux pane via process-tree walk
# ---------------------------------------------------------------------------

def get_pane_map() -> dict[int, TmuxTarget]:
    """
    Return a mapping of pane_pid -> TmuxTarget for every pane in every tmux
    session, by running ``tmux list-panes -a``.

    Returns an empty dict if tmux is not running or list-panes fails.
    """
    pane_map: dict[int, TmuxTarget] = {}
    try:
        out = subprocess.check_output(
            [
                "tmux", "list-panes", "-a",
                "-F", "#{pane_pid} #{session_name} #{window_index} #{pane_index}",
            ],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return pane_map

    for line in out.splitlines():
        parts = line.split(" ", 3)
        if len(parts) != 4:
            continue
        pid_str, session_name, window_str, pane_str = parts
        try:
            pane_map[int(pid_str)] = TmuxTarget(
                session=session_name,
                window=int(window_str),
                pane=int(pane_str),
            )
        except ValueError:
            continue

    return pane_map


def get_ancestor_pids(pid: int) -> list[int]:
    """
    Walk the process tree upward from *pid* (exclusive) and return the list of
    ancestor PIDs in order (parent first), stopping at PID 1.
    """
    ancestors: list[int] = []
    current = pid
    seen: set[int] = {pid}

    while True:
        try:
            status = Path(f"/proc/{current}/status").read_text()
        except OSError:
            break

        ppid: Optional[int] = None
        for line in status.splitlines():
            if line.startswith("PPid:"):
                try:
                    ppid = int(line.split()[1])
                except (IndexError, ValueError):
                    pass
                break

        if ppid is None or ppid <= 1 or ppid in seen:
            break

        ancestors.append(ppid)
        seen.add(ppid)
        current = ppid

    return ancestors


def find_tmux_target(pid: int) -> Optional[TmuxTarget]:
    """
    Find the tmux pane that owns *pid* by walking the process tree upward and
    matching each ancestor PID against the pane map returned by
    ``tmux list-panes -a``.

    Returns a :class:`TmuxTarget` identifying the session, window, and pane,
    or ``None`` if no match is found.
    """
    pane_map = get_pane_map()
    if not pane_map:
        return None

    for ancestor in get_ancestor_pids(pid):
        if ancestor in pane_map:
            return pane_map[ancestor]

    return None


# ---------------------------------------------------------------------------
# Step 6: fzf selection
# ---------------------------------------------------------------------------

_STATE_LABEL = {
    "idle": "idle",
    "error": "error",
    "awaiting_input": "awaiting input",
    "in_progress": "in progress",
    "unknown": "unknown",
}

_NEEDS_ATTENTION = {"idle", "error", "awaiting_input"}


def pick_candidate(candidates: list[Candidate]) -> Optional[Candidate]:
    """Present candidates via fzf and return the selected one."""
    if not candidates:
        return None

    if len(candidates) == 1:
        return candidates[0]

    lines = []
    for idx, c in enumerate(candidates):
        state_label = _STATE_LABEL.get(c.session.state, c.session.state)
        tmux = c.tmux_target.address() if c.tmux_target else "(no tmux pane found)"
        title = c.session.title or c.session.slug
        line = (
            f"{idx}\t"
            f"[{state_label}]  "
            f"{title[:60]:<60}  "
            f"tmux:{tmux}  "
            f"port:{c.instance.port}"
        )
        lines.append(line)

    fzf_input = "\n".join(lines)

    try:
        with open("/dev/tty", "w") as tty:
            result = subprocess.run(
                ["fzf", "--ansi", "--with-nth=2..", "--delimiter=\t", "--prompt=opencode> "],
                input=fzf_input,
                stdout=subprocess.PIPE,
                stderr=tty,
                text=True,
            )
    except FileNotFoundError:
        print("error: fzf not found. Install fzf or select manually.", file=sys.stderr)
        for line in lines:
            print(line.split("\t", 1)[1])
        return None

    if result.returncode != 0 or not result.stdout.strip():
        return None  # user cancelled

    selected_line = result.stdout.strip()
    idx_str = selected_line.split("\t", 1)[0]
    try:
        return candidates[int(idx_str)]
    except (ValueError, IndexError):
        return None


# ---------------------------------------------------------------------------
# Step 7: Switch tmux session
# ---------------------------------------------------------------------------

def switch_to_tmux(target: TmuxTarget) -> None:
    """Switch to the exact tmux pane identified by *target*."""
    address = target.address()
    inside_tmux = bool(os.environ.get("TMUX"))
    if inside_tmux:
        subprocess.run(["tmux", "switch-client", "-t", target.session])
        subprocess.run(["tmux", "select-window", "-t", f"{target.session}:{target.window}"])
        subprocess.run(["tmux", "select-pane", "-t", address])
    else:
        subprocess.run(["tmux", "attach", "-t", address])


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    instances = find_opencode_instances()

    if not instances:
        print("No opencode instances with an HTTP server found.")
        return 0

    candidates: list[Candidate] = []

    for inst in instances:
        session = get_current_session(inst)
        if session is None:
            print(
                f"  port {inst.port} ({inst.cwd}): could not retrieve session info",
                file=sys.stderr,
            )
            continue

        tmux_target = find_tmux_target(inst.pid)

        if session.state in _NEEDS_ATTENTION:
            candidates.append(Candidate(instance=inst, session=session, tmux_target=tmux_target))
        else:
            state_label = _STATE_LABEL.get(session.state, session.state)
            print(
                f"  port {inst.port} ({inst.cwd.name}): {state_label} — skipping",
                file=sys.stderr,
            )

    if not candidates:
        print("All opencode instances are busy or have no sessions needing attention.")
        return 0

    chosen = pick_candidate(candidates)
    if chosen is None:
        return 0

    if chosen.tmux_target is None:
        print(
            f"No tmux pane found for opencode pid {chosen.instance.pid} ({chosen.instance.cwd}). "
            f"opencode is at http://127.0.0.1:{chosen.instance.port}",
            file=sys.stderr,
        )
        return 1

    switch_to_tmux(chosen.tmux_target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
