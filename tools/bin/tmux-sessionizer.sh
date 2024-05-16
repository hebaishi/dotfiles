#!/bin/bash
function list_dirs() {
  top_level_dirs="~/work/git ~"
  result=""
  for dir in $top_level_dirs; do
    dir="${dir/#\~/$HOME}"
    local_result=""
    repos="$repos $(find $dir -maxdepth 3 -name .git -type d)"
    local_result="$local_result $repos"
    for repo in $repos; do
      if [[ -d $repo/worktrees ]]; then
        gitdir_files=$(find $repo/worktrees -maxdepth 2 -name gitdir)
        for file in $gitdir_files; do
          local_result="$local_result $(cat $file)"
        done
      fi
    done
    for full_path_repo in $local_result; do
      root_dir=$(echo $full_path_repo | sed -e 's/\/\.git//')
      result="$result $dir:$(realpath -s --relative-to="$dir" "$root_dir")"
    done
  done
  for item in $result; do echo $item; done
}

selected=$(list_dirs | sort | uniq | fzf)
if [[ -z $selected ]]; then
    exit 0
fi
selected_path=$(echo $selected | sed -e 's/:/\//')
selected=$(echo $selected | cut -f2 -d:)

selected_name=$(echo "$selected" | tr . _)
tmux_running=$(pgrep tmux | grep -v $(basename $0))

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s $selected_name -c $selected_path
    exit 0
fi

if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected_path
fi

if [[ -z $TMUX ]]; then
  tmux attach -t $selected_name
else
  tmux switch-client -t $selected_name
fi
