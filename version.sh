#!/usr/bin/env bash

set -euo pipefail

# Initialize version.json with enhanced configuration
function _initialise_version() {
  if [[ ! -f "version.json" ]]; then
    cat <<EOF >version.json
{
  "default_branch": "master",
  "major": "0",
  "minor": "0",
  "tag_prefix": ""
}
EOF
  fi
}

# Check if the current directory is a git repository
function _is_git_repository() {
  [ -d ".git" ]
}

# Get short SHA of current commit
function _get_short_sha() {
  git rev-parse --short=7 HEAD
}

# Extract and normalize branch name
function _extract_branch_name() {
  local git_branch
  git_branch=$(git branch --show-current 2>/dev/null)

  if [[ -z "$git_branch" ]]; then
    git_branch=$(git name-rev --name-only "$(git show -s --format=%H)" 2>/dev/null | sed 's/^tags\///' | sed 's/~.*$//')
  fi

  # Remove remote prefixes
  git_branch=${git_branch#remotes/origin/}
  git_branch=${git_branch#remotes/heads/}

  # Normalize branch name for version string (semver compatible)
  # Replace forward slashes and underscores with hyphens
  git_branch=${git_branch//\//-}
  git_branch=${git_branch//_/-}
  # Remove special characters that might break version parsing
  git_branch=${git_branch//[^a-zA-Z0-9.-]/-}
  # Remove leading/trailing hyphens and collapse multiple hyphens
  git_branch=${git_branch#-}
  git_branch=${git_branch%-}
  git_branch=$(echo "$git_branch" | sed 's/--*/-/g')

  # Fallback to "unknown" if we end up with an empty string
  if [[ -z "$git_branch" ]]; then
    git_branch="unknown"
  fi

  echo "$git_branch"
}

# Get the latest git tag and calculate next version
# Pure function - no git calls, takes latest tag as input for testability
function _calculate_next_version_from_tags() {
  local latest_tag="$1"
  local tag_prefix="$2"
  local commits_since_tag="$3"
  local next_major="$4"
  local next_minor="$5"

  local calculated_version
  if [[ -n "$latest_tag" ]]; then
    # Remove tag prefix and v prefix if present
    local tag_version=${latest_tag#"$tag_prefix"}
    tag_version=${tag_version#v}

    # Validate tag version format
    if [[ ! "$tag_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      calculated_version="${next_major}.${next_minor}.0"
    else
      # Parse version components
      local major minor patch
      major=$(echo "$tag_version" | cut -d '.' -f1)
      minor=$(echo "$tag_version" | cut -d '.' -f2)
      patch=$(echo "$tag_version" | cut -d '.' -f3)

      if [[ $commits_since_tag -eq 0 ]]; then
        # Exactly on a tag
        calculated_version="${major}.${minor}.${patch}"
      else
        # Increment patch version
        local next_patch=$((patch + 1))
        calculated_version="${major}.${minor}.${next_patch}"
      fi
    fi
  else
    # No tags yet, start with configured version
    calculated_version="${next_major}.${next_minor}.0"
  fi

  # Now enforce version minimums on the calculated version
  local major minor patch
  major=$(echo "$calculated_version" | cut -d '.' -f1)
  minor=$(echo "$calculated_version" | cut -d '.' -f2)
  patch=$(echo "$calculated_version" | cut -d '.' -f3)

  # Apply version constraints - ensure we meet minimum requirements
  if [[ $major -lt $next_major ]]; then
    echo "${next_major}.${next_minor}.0"
  elif [[ $major -eq $next_major ]] && [[ $minor -lt $next_minor ]]; then
    echo "${major}.${next_minor}.0"
  else
    echo "$calculated_version"
  fi
}

# Calculate version based on commits since last tag - PURE FUNCTION for testing
function _calculate_version() {
  local git_branch="$1"
  local git_generated_version="$2"
  local next_major="$3"
  local next_minor="$4"
  local default_branch="$5"
  local short_sha="$6"

  # Validate input version format
  if [[ ! "$git_generated_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    git_generated_version="${next_major}.${next_minor}.0"
  fi

  # Note: Version minimums are now enforced in _calculate_next_version_from_tags
  # so git_generated_version already respects next_major/next_minor constraints
  local final_version="$git_generated_version"

  if [[ "$git_branch" == "$default_branch" ]]; then
    # Main branch: use the calculated version as-is
    final_version="$git_generated_version"
  else
    # Feature branch: add pre-release identifier in semver format
    # Example: 1.2.3-dev.branch.sha
    final_version="${git_generated_version}-dev.${git_branch}.${short_sha}"
  fi

  echo "$final_version"
}

# Get git data - separated for easier testing/mocking
function _get_git_data() {
  local tag_prefix="$1"

  # Get tag list sorted by version
  local tag_list
  tag_list=$(git tag -l --sort=-version:refname 2>/dev/null || echo "")

  # Get latest matching tag
  local latest_tag
  latest_tag=$(echo "$tag_list" | grep -E "^${tag_prefix}v?[0-9]+\.[0-9]+\.[0-9]+$" | head -n 1 || true)

  # Calculate commits since tag
  local commits_since_tag=0
  if [[ -n "$latest_tag" ]]; then
    commits_since_tag=$(git rev-list --count "${latest_tag}..HEAD" 2>/dev/null || echo "0")
  fi

  # Output format: latest_tag|commits_since_tag (not all tags!)
  echo "${latest_tag}|${commits_since_tag}"
}

# Check if current commit has uncommitted changes
function _has_dirty_working_tree() {
  # Check for changes in the working directory
  if ! git diff --quiet 2>/dev/null; then
    return 0  # Has unstaged changes
  fi

  return 1  # Clean working tree
}

# Main versioning function
function semver() {
  local is_not_git_repo="$1"

  if [[ -n "$is_not_git_repo" ]]; then
    echo "1.0.0-SNAPSHOT"
    return 0
  fi

  # Initialize version.json if needed
  _initialise_version

  # Read configuration
  local default_branch next_major next_minor tag_prefix

  default_branch=$(jq -r '.default_branch // "master"' version.json)
  next_major=$(jq -r '.major // "0"' version.json)
  next_minor=$(jq -r '.minor // "0"' version.json)
  tag_prefix=$(jq -r '.tag_prefix // ""' version.json)

  # Get current branch and SHA
  local git_branch short_sha
  git_branch=$(_extract_branch_name)
  short_sha=$(_get_short_sha)

  # Get git data
  local git_data latest_tag commits_since_tag
  git_data=$(_get_git_data "$tag_prefix")
  latest_tag=$(echo "$git_data" | cut -d'|' -f1)
  commits_since_tag=$(echo "$git_data" | cut -d'|' -f2)

  # Calculate base version
  local git_generated_version
  git_generated_version=$(_calculate_next_version_from_tags "$latest_tag" "$tag_prefix" "$commits_since_tag" "$next_major" "$next_minor")

  # Calculate final version
  local final_version
  final_version=$(_calculate_version "$git_branch" "$git_generated_version" "$next_major" "$next_minor" "$default_branch" "$short_sha")

  # Add dirty suffix if working tree has uncommitted changes
  if _has_dirty_working_tree; then
    if [[ "$final_version" =~ -dev\. ]]; then
      final_version="${final_version}.dirty"
    else
      final_version="${final_version}-dirty"
    fi
  fi

  # Add tag prefix if configured
  if [[ -n "$tag_prefix" ]]; then
    final_version="${tag_prefix}${final_version}"
  fi

  echo "$final_version"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if ! _is_git_repository; then
    semver "not-git-repo"
  else
    semver ""
  fi
fi
