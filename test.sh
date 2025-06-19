#!/usr/bin/env bats
set -e
source ./version.sh

@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "Version if not git repo" {
  result=$(semver "1")
  [ "$result" == "1.0.0-SNAPSHOT" ]
}

@test "Version on first commit default branch" {
  # New signature: _calculate_version "$git_branch" "$git_generated_version" "$next_major" "$next_minor" "$default_branch" "$short_sha"
  result=$(_calculate_version "master" "0.0.0" "0" "0" "master" "vskd341")
  [ "$result" == "0.0.0" ]
}

@test "Version on second commit default branch" {
  result=$(_calculate_version "master" "0.0.2" "0" "0" "master" "abc1234")
  [ "$result" == "0.0.2" ]
}

@test "Version on fifth commit default branch" {
  result=$(_calculate_version "master" "0.0.6" "0" "0" "master" "def5678")
  [ "$result" == "0.0.6" ]
}

@test "Version on with different minor on default branch" {
  # Version enforcement now happens in _calculate_next_version_from_tags
  # so we pass the already-enforced version to _calculate_version
  result=$(_calculate_version "master" "0.1.0" "0" "1" "master" "aaghas27")
  [ "$result" == "0.1.0" ]
}

@test "Version on with different major on default branch" {
  # Version enforcement now happens in _calculate_next_version_from_tags
  result=$(_calculate_version "master" "1.0.0" "1" "0" "master" "aaghas27")
  [ "$result" == "1.0.0" ]
}

@test "Version on with different major and minor on default branch" {
  result=$(_calculate_version "master" "1.1.0" "1" "1" "master" "aaghas27")
  [ "$result" == "1.1.0" ]
}

@test "Version on second commit on feature branch" {
  # Now uses semver pre-release format: version-dev.branch.sha
  result=$(_calculate_version "feature" "0.0.1" "0" "0" "master" "aaghas27")
  echo $result
  [ "$result" == "0.0.1-dev.feature.aaghas27" ]
}

@test "Version on fifth commit on feature branch" {
  result=$(_calculate_version "feature" "0.0.5" "0" "0" "master" "aaghas27")
  [ "$result" == "0.0.5-dev.feature.aaghas27" ]
}

@test "Version on feature branch with different minor" {
  # Feature branches now get the same base version enforcement as master
  result=$(_calculate_version "feature" "0.1.0" "0" "1" "master" "aaghas27")
  [ "$result" == "0.1.0-dev.feature.aaghas27" ]
}

@test "Version on feature branch with different major" {
  result=$(_calculate_version "feature" "1.0.0" "1" "0" "master" "aaghas27")
  [ "$result" == "1.0.0-dev.feature.aaghas27" ]
}

@test "Version on feature branch with different major and minor" {
  result=$(_calculate_version "feature" "1.1.0" "1" "1" "master" "aaghas27")
  [ "$result" == "1.1.0-dev.feature.aaghas27" ]
}

# Additional tests for the new pure functions

@test "Calculate next version from tags - no tags" {
  result=$(_calculate_next_version_from_tags "" "" "0" "0" "1")
  [ "$result" == "0.1.0" ]
}

@test "Calculate next version from tags - with existing tag, no commits" {
  result=$(_calculate_next_version_from_tags "v1.2.3" "v" "0" "0" "1")
  [ "$result" == "1.2.3" ]
}

@test "Calculate next version from tags - with existing tag, 5 commits ahead" {
  result=$(_calculate_next_version_from_tags "v1.2.3" "v" "5" "0" "1")
  [ "$result" == "1.2.4" ]
}

@test "Calculate next version from tags - enforces minimums" {
  # Tag v0.5.0 exists, but minimums are major=1, minor=2
  result=$(_calculate_next_version_from_tags "v0.5.0" "v" "3" "1" "2")
  [ "$result" == "1.2.0" ]
}

@test "Calculate next version from tags - enforces minor only" {
  # Test the specific case from the failing test
  result=$(_calculate_next_version_from_tags "v0.0.0" "v" "1" "0" "1")
  [ "$result" == "0.1.0" ]
}

@test "Calculate next version from tags - enforces major only" {
  result=$(_calculate_next_version_from_tags "v0.0.0" "v" "1" "1" "0")
  [ "$result" == "1.0.0" ]
}

@test "Calculate next version from tags - existing version higher than minimums" {
  # Tag v2.5.0 exists, minimums are major=1, minor=2 (should keep existing)
  result=$(_calculate_next_version_from_tags "v2.5.0" "v" "0" "1" "2")
  [ "$result" == "2.5.0" ]
}

@test "Invalid version input gets corrected" {
  result=$(_calculate_version "master" "invalid.version" "0" "1" "master" "abc1234")
  [ "$result" == "0.1.0" ]
}
