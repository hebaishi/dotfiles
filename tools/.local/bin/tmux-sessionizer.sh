#!/bin/bash
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

selected=$(list_dirs | fzf --color=16)
if [[ -z $selected ]]; then
    exit 0
fi
selected_path=$(echo $selected | sed -e 's/:/\//')
selected=$(echo $selected | cut -f2 -d:)

selected_name=$(echo "$selected" | tr . _)
tmux_running=$(pgrep tmux | grep -v $(basename $0))

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -u -s $selected_name -c $selected_path
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
