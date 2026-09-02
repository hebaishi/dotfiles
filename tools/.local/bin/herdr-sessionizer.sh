#!/bin/bash
# herder-sessionizer.sh
# tmux-sessionizer, but for herdr (https://herdr.dev).
#
# When run from inside a herdr pane, it creates/focuses a herdr *workspace*
# for the selected project (like a tmux window per project in a shared
# session). When run outside herdr, it creates/attaches a named herdr
# *session* for the selected project (like a tmux session per project).
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

if [[ -n $HERDR_ENV ]]; then
  # Already inside a herdr session: manage workspaces (herdr's equivalent
  # of tmux windows) instead of nesting another session.
  existing_id=$(herdr workspace list \
    | jq -r --arg lbl "$selected_name" \
      '.result.workspaces[] | select(.label == $lbl) | .workspace_id' \
    | head -n1)

  if [[ -z $existing_id ]]; then
    existing_id=$(herdr workspace create --cwd "$selected_path" --label "$selected_name" --no-focus \
      | jq -r '.result.workspace.workspace_id')
  fi

  herdr workspace focus "$existing_id"
  exit 0
fi

# Outside herdr: manage named persistent sessions (herdr's equivalent of
# tmux sessions).
session_exists=$(herdr session list --json \
  | jq -r --arg name "$selected_name" \
    '.sessions[] | select(.name == $name) | .name' \
  | head -n1)

if [[ -n $session_exists ]]; then
  exec herdr session attach "$selected_name"
else
  cd "$selected_path" || exit 1
  exec herdr --session "$selected_name"
fi
