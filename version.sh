#!/usr/bin/env bash

function initialise_version {
  if [[ ! -f "version.json" ]]
then
  cat << EOF > version.json
  {
    "default_branch": "master",
    "major": "0",
    "minor": "0"
  }
EOF
fi
}

function is_git_repository {
    [ -d ".git" ]
}


function sanitise_version {
    maybe_starts_with_v=$1
    no_v=${maybe_starts_with_v#v}
    no_sha=${no_v%-*}
    if [[ $no_sha != "$no_v" ]]
    then
        no_extra_patch=${no_sha%-*}
        patch_number=${no_extra_patch##*.}

        patch_count=${no_sha#*-*}
        major_minor=${no_sha%.*}
        major=${major_minor%.*}
        minor=${major_minor#*.}

        if [[ $major -lt $future_major ]]
        then
            echo "${future_major}.${future_minor}.0"
        else
            if [[ $minor -lt $future_minor ]]
            then
                echo "${major}.${future_minor}.0"
            else
                new_patch=$((patch_count + patch_number))
                git_generated_version="${major_minor}.${new_patch}"
                echo "$git_generated_version"
            fi
        fi
    else
        echo "$no_sha"
    fi
}
function current_branch {
  git rev-parse --abbrev-ref HEAD
}

function semver {
  is_git_repo=$1
  if [ "$is_git_repo" ]
  then
      echo "1.0.0-SNAPSHOT"
      return 0
  fi

  initialise_version
  git_branch=$(current_branch)

  git_generated_version=$(git describe --always)

  future_major=$(grep "major" version.json | cut -d\" -f4)
  future_minor=$(grep "minor" version.json | cut -d\" -f4)
  default_branch=$(grep "default_branch" version.json | cut -d\" -f4)

  final_version=$(calculate_version "$git_branch" "$git_generated_version" "$future_major" "$future_minor" "$default_branch")
  echo "$final_version"
}

function calculate_version {
  git_branch=$1
  git_generated_version=$2
  future_major=$3
  future_minor=$4
  default_branch=$5

  if [[ ! "${git_generated_version}" =~ ^v?.+\..+\.[^-]+ ]]
  then
    git_generated_version="${future_major}.${future_minor}.1"
  fi
  final_version=$git_generated_version
  if [[ $git_branch == "$default_branch" ]]
  then
      final_version=$(sanitise_version "$git_generated_version")
  else
      final_version="${git_generated_version}-${git_branch}"
      final_version=${final_version#v}
  fi

  echo "$final_version" | tr -d '[:space:]'
}

semver "$(is_git_repository)"
