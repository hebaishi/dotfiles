#!/usr/bin/env python3
"""
opencode_switch.py - Find idle/error opencode instances and switch to their tmux sessions.

Workflow:
  1. Find all opencode processes that expose an HTTP API (started with --port).
  2. For each, resolve its listening port and working directory.
  3. Query the API to find the most recently updated session for that directory.
  4. Determine whether the session is idle or in an error state.
  5. Present matching instances via fzf and switch to the corresponding tmux session.
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
class Candidate:
    instance: OpencodeInstance
    session: SessionInfo
    tmux_session: Optional[str]


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

        # Check if this process has --port in its cmdline
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as fh:
                cmdline = fh.read().decode(errors="replace").split("\x00")
        except OSError:
            continue

        if "--port" not in cmdline:
            continue  # TUI-only instance, skip

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

    last = messages[-1]
    info = last.get("info", {})
    role = info.get("role", "")
    finish = info.get("finish")
    completed = info.get("time", {}).get("completed")
    has_error = bool(info.get("error"))

    if role == "user":
        return "awaiting_input"

    if has_error:
        return "error"

    if role == "assistant":
        if finish == "stop" and completed is not None:
            return "idle"
        if finish is None and completed is None:
            return "in_progress"
        if finish is None and completed is not None:
            # Message completed but finish reason was never set — treat as error/interrupted
            return "error"

    return "unknown"


# ---------------------------------------------------------------------------
# Step 5: Find matching tmux session
# ---------------------------------------------------------------------------

# Common git root prefixes to strip when deriving the tmux session name.
# These mirror the `top_level_dirs` in tmux-sessionizer.sh.
_GIT_ROOTS = [
    Path.home() / "personal" / "git",
    Path.home() / "work" / "git",
    Path.home(),
]


def find_tmux_session(cwd: Path) -> Optional[str]:
    """
    Derive a tmux session name from the process CWD by stripping known path
    prefixes, then verify the session exists with `tmux has-session`.
    """
    candidates: list[str] = []

    for root in _GIT_ROOTS:
        try:
            rel = cwd.relative_to(root)
            name = str(rel).replace(".", "_")
            candidates.append(name)
        except ValueError:
            continue

    # Also try the bare basename as a last resort
    candidates.append(cwd.name.replace(".", "_"))

    for name in candidates:
        result = subprocess.run(
            ["tmux", "has-session", "-t", name],
            capture_output=True,
        )
        if result.returncode == 0:
            return name

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
        tmux = c.tmux_session or "(no tmux session found)"
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

def switch_to_tmux(session_name: str) -> None:
    inside_tmux = bool(os.environ.get("TMUX"))
    if inside_tmux:
        subprocess.run(["tmux", "switch-client", "-t", session_name])
    else:
        subprocess.run(["tmux", "attach", "-t", session_name])


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

        tmux_name = find_tmux_session(inst.cwd)

        if session.state in _NEEDS_ATTENTION:
            candidates.append(Candidate(instance=inst, session=session, tmux_session=tmux_name))
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

    if chosen.tmux_session is None:
        print(
            f"No tmux session found for {chosen.instance.cwd}. "
            f"opencode is at http://127.0.0.1:{chosen.instance.port}",
            file=sys.stderr,
        )
        return 1

    switch_to_tmux(chosen.tmux_session)
    return 0


if __name__ == "__main__":
    sys.exit(main())
