
function initialise_version {
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

function is_git_repository {
  [ -d ".git" ]
}

function sanitise_version {
  maybe_starts_with_v=$1
  no_v=${maybe_starts_with_v#v}
  no_sha=${no_v%-*}
  if [[ $no_sha != "$no_v" ]]; then
    no_extra_patch=${no_sha%-*}
    patch_count=$(echo "$no_sha" | cut -d '-' -f2)
    major=$(echo "$no_sha" | cut -d '.' -f1)
    minor=$(echo "$no_sha" | cut -d '.' -f2)
    patch_number=$(echo "$no_extra_patch" | cut -d '.' -f3)
    if [[ $major -lt $future_major ]]; then
      echo "${future_major}.${future_minor}.0"
    else
      if [[ $minor -lt $future_minor ]]; then
        echo "${major}.${future_minor}.0"
      else
        new_patch=$((patch_count + patch_number))
        git_generated_version="${major}.${minor}.${new_patch}"
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
        new_patch=$((1 + patch_number))
        git_generated_version="${major}.${minor}.${new_patch}"
        echo "$git_generated_version"
      fi
    fi
  fi
}

function semver {
  is_git_repo=$1
  if [ "$is_git_repo" ]; then
    echo "1.0.0-SNAPSHOT"
    return 0
  fi

  initialise_version
  git_branch=$(git rev-parse --abbrev-ref HEAD)

  # Get the latest tag
  latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1))
  major_minor=$(echo $latest_tag | cut -d '.' -f -2)
  # Get the list of commits since the latest tag
  commits=$(git rev-list --count $latest_tag..HEAD)
  git_generated_version="${major_minor}.${commits}"
  future_major=$(cat version.json | jq ".major" --raw-output)
  future_minor=$(cat version.json | jq ".minor" --raw-output)
  default_branch=$(cat version.json | jq ".default_branch" --raw-output)

  final_version=$(calculate_version "$git_branch" "$git_generated_version" "$future_major" "$future_minor" "$default_branch")
  echo "$final_version"
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