#!/usr/bin/env bash

#source lib.sh

function initialise_version() {
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
function is_git_repository() {
  [ -d ".git" ]
}

function sanitise_version {
  raw_version=$1
  no_v=${raw_version#v}
  no_sha=${no_v%-*}
  if [[ $no_sha != "$no_v" ]]; then
    no_extra_patch=${no_sha%-*}
    major=$(echo "$no_sha" | cut -d '.' -f1)
    minor=$(echo "$no_sha" | cut -d '.' -f2)
    patch_number=$(echo "$no_extra_patch" | cut -d '.' -f3)
    if [[ $major -lt $future_major ]]; then
      echo "${future_major}.${future_minor}.0"
    else
      if [[ $minor -lt $future_minor ]]; then
        echo "${major}.${future_minor}.0"
      else
        git_generated_version="${major}.${minor}.${patch_number}"
        echo "$git_generated_version"
      fi
    fi
  else
    major=$(echo "$no_sha" | cut -d '.' -f1)
    minor=$(echo "$no_sha" | cut -d '.' -f2)
    patch_number=$(echo "$no_sha" | cut -d '.' -f3)
    if [[ $major -lt $future_major ]]; then
      echo "${future_major}.${future_minor}.0"
    else
      if [[ $minor -lt $future_minor ]]; then
        echo "${major}.${future_minor}.0"
      else
        git_generated_version="${major}.${minor}.${patch_number}"
        echo "$git_generated_version"
      fi
    fi
  fi
}

function calculate_version {
  git_branch=$1
  git_generated_version=$2
  future_major=$3
  future_minor=$4
  default_branch=$5
  if [[ ! "${git_generated_version}" =~ ^v?.+\..+\.[^-]+ ]]; then
    git_generated_version="${future_major}.${future_minor}.0"
  fi
  final_version=$git_generated_version
  if [[ $git_branch == "$default_branch" ]]; then
    final_version=$(sanitise_version "$git_generated_version")
  else
    final_version="${git_generated_version}-${git_branch}"
    final_version=${final_version#v}
  fi

  echo "$final_version" | tr -d '[:space:]'
}

function extract_branch_name {
  git_branch=$(git branch --show-current)
  if [[ ! $git_branch ]]; then
    git_branch=$(git name-rev --name-only $(git show -s --format=%H))
  fi
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
  initialise_version

  git_branch=$(extract_branch_name)

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

  final_version=$(calculate_version "$git_branch" "$next_version" "$next_major" "$next_minor" "$default_branch")
  echo "$final_version"
}


if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  semver "$(is_git_repository)"
fi
