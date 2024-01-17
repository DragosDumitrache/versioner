#!/usr/bin/env bash

#source lib.sh

function _initialise_version() {
  # This will initialise your repository for versioner to be able to consume
  if [[ ! -f "version.json" ]]; then
    cat <<EOF >version.json
    {
      "default_branch": "master",
      "major": "0",
      "minor": "0"
    }
EOF
  fi
}

# Function to check if the current directory is a git repository
function _is_git_repository() {
  [ -d ".git" ]
}

function _calculate_version {
  git_branch=$1
  git_generated_version=$2
  next_major=$3
  next_minor=$4
  default_branch=$5
  if [[ ! "${git_generated_version}" =~ ^v?.+\..+\.[^-]+ ]]; then
    # This case should never happen
    git_generated_version="${next_major}.${next_minor}.0"
  fi
  final_version=$git_generated_version
  if [[ $git_branch == "$default_branch" ]]; then
    major=$(echo "$final_version" | cut -d '.' -f1)
    minor=$(echo "$final_version" | cut -d '.' -f2)
    patch_number=$(echo "$final_version" | cut -d '.' -f3)
    if [[ $major -lt $next_major ]]; then
        final_version="${next_major}.${next_minor}.0"
    else
      if [[ $minor -lt $next_minor ]]; then
        final_version="${major}.${next_minor}.0"
      else
        final_version="${major}.${minor}.${patch_number}"
      fi
    fi
  else
    final_version="${git_generated_version}-${git_branch}"
  fi
  echo "$final_version" | tr -d '[:space:]'
}

function _extract_branch_name {
  git_branch=$(git branch --show-current)
  if [[ ! $git_branch ]]; then
    git_branch="$(git name-rev --name-only $(git show -s --format=%H))"
  fi
  git_branch=${git_branch/$to_remove/""}
  to_remove="remotes/origin/"
  git_branch=${git_branch/$to_remove/""}
  to_remove="remotes/heads/"
  git_branch=${git_branch////"-"}
  echo $git_branch
}

function semver {
  local git_branch latest_tag major_minor patch commits new_patch  default_branch final_version
  local next_major next_minor next_patch next_version
  is_git_repo=$1

  if [ "$is_git_repo" ]; then
    echo "1.0.0-SNAPSHOT"
    return 0
  fi

  # If no version.json file is present, add it, then proceed to calculate the version
  _initialise_version

  git_branch=$(_extract_branch_name)

  next_major=$(cat version.json | jq ".major" --raw-output)
  next_minor=$(cat version.json | jq ".minor" --raw-output)
  next_patch=0
  default_branch=$(cat version.json | jq ".default_branch" --raw-output)

  # Get the latest tag
  latest_tag=$(git tag -l --sort=-creatordate | head -n 1)
  if [ $latest_tag ]; then
    major_minor=$(echo "$latest_tag" | cut -d '.' -f -2)
    patch=$(echo "$latest_tag" | cut -d '.' -f 3)
    # Get the list of commits since the latest tag
    commits=$(git rev-list --count "$latest_tag"..HEAD)
    # shellcheck disable=SC2004
    next_patch=$(($commits + $patch))
    next_version="${major_minor}.${next_patch}"
  else
    next_version="${next_major}.${next_minor}.${next_patch}"
  fi

  final_version=$(_calculate_version "$git_branch" "$next_version" "$next_major" "$next_minor" "$default_branch")
  echo "$final_version"
}


if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  semver "$(_is_git_repository)"
fi
