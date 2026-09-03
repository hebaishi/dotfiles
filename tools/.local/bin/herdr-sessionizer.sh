#!/bin/bash
# herder-sessionizer.sh
# tmux-sessionizer, but for herdr (https://herdr.dev).
#
# Always operates against a single persistent herdr session named
# 'default' (starting it headlessly if needed) and creates/focuses a
# per-project herdr *workspace* inside it (like a tmux window per
# project in a shared session). This works the same whether it's run
# from inside a herdr pane or from a plain shell outside herdr.
function find_wrapper() {
  name=$1
  location=$2
  search_type=$3
  max_depth=$4
  if command -v fd &> /dev/null; then
      fd -H --max-depth $max_depth --type $search_type "^$name\$" $location
  else
      find $location -maxdepth $max_depth -name $name -type $search_type
  fi
}

function list_dirs() {
  top_level_dirs="~/personal/git ~/work/git ~"
  for dir in $top_level_dirs; do
    dir="${dir/#\~/$HOME}"
    local_result=""
    repos="$(find_wrapper .git $dir d 4)"
    local_result="$local_result $repos"
    for repo in $repos; do
      if [[ -d $repo/worktrees ]]; then
        gitdir_files=$(find_wrapper gitdir $repo/worktrees f 2)
        for file in $gitdir_files; do
          local_result="$local_result $(cat $file)"
        done
      fi
    done
    for full_path_repo in $local_result; do
      root_dir=$(echo $full_path_repo | sed -e 's/\/\.git//')
      echo "$dir:$(realpath -s --relative-to="$dir" "$root_dir")"
    done
  done
}

if ! command -v herdr &> /dev/null; then
  echo "herdr is not installed or not on PATH" >&2
  exit 1
fi

selected=$(list_dirs | fzf --color=16)
if [[ -z $selected ]]; then
    exit 0
fi
selected_path=$(echo $selected | sed -e 's/:/\//')
selected=$(echo $selected | cut -f2 -d:)

selected_name=$(echo "$selected" | tr -c 'A-Za-z0-9._-' '_')

# Always operate against a single persistent session named 'default', with
# one workspace per project (herdr's equivalent of a tmux window). This is
# true whether we're already inside herdr or launching from the outside.
herdr_session="default"

session_running=$(herdr session list --json \
  | jq -r --arg name "$herdr_session" \
    '.sessions[] | select(.name == $name and .running == true) | .name' \
  | head -n1)

if [[ -z $session_running ]]; then
  herdr server --session "$herdr_session" \
    </dev/null >/dev/null 2>&1 &
  disown

  for _ in $(seq 1 50); do
    session_running=$(herdr session list --json \
      | jq -r --arg name "$herdr_session" \
        '.sessions[] | select(.name == $name and .running == true) | .name' \
      | head -n1)
    [[ -n $session_running ]] && break
    sleep 0.1
  done

  if [[ -z $session_running ]]; then
    echo "Timed out waiting for herdr session '$herdr_session' to start" >&2
    exit 1
  fi
fi

existing_id=$(herdr --session "$herdr_session" workspace list \
  | jq -r --arg lbl "$selected_name" \
    '.result.workspaces[] | select(.label == $lbl) | .workspace_id' \
  | head -n1)

if [[ -z $existing_id ]]; then
  existing_id=$(herdr --session "$herdr_session" workspace create \
    --cwd "$selected_path" --label "$selected_name" --no-focus \
    | jq -r '.result.workspace.workspace_id')
fi

herdr --session "$herdr_session" workspace focus "$existing_id" > /dev/null

if [[ -n $HERDR_ENV ]]; then
  # Already inside a herdr pane. herdr disallows nested/recursive attach
  # (attaching to another session from within one errors out), so the
  # best we can do from here is focus the workspace via the socket API
  # above. If we're inside the 'default' session itself that's enough to
  # bring it on screen; if we're inside a different session, the focus
  # takes effect in 'default' and will be visible next time it's attached.
  if [[ $HERDR_SESSION == "$herdr_session" ]]; then
    exit 0
  fi
  echo "Workspace '$selected_name' is ready in the '$herdr_session' herdr session." >&2
  echo "(Currently inside session '$HERDR_SESSION'; nested attach is disabled, so switch sessions manually to view it.)" >&2
  exit 0
fi

# Outside herdr entirely: attach to the 'default' session.
exec herdr session attach "$herdr_session"
