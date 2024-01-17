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
    result=$(_calculate_version "master" "vskd341" "0" "0" "master")
    [ "$result" == "0.0.0" ]
}

@test "Version on second commit default branch" {
    result=$(_calculate_version "master" "0.0.2" "0" "0" "master")
    [ "$result" == "0.0.2" ]
}

@test "Version on fifth commit default branch" {
  result=$(_calculate_version "master" "0.0.6" "0" "0" "master")
  [ "$result" == "0.0.6" ]
}

@test "Version on with different minor on default branch" {
  result=$(_calculate_version "master" "0.0.1-5-aaghas27" "0" "1" "master")
  [ "$result" == "0.1.0" ]
}

@test "Version on with different major on default branch" {
  result=$(_calculate_version "master" "0.0.1-5-aaghas27" "1" "0" "master")
  [ "$result" == "1.0.0" ]
}

@test "Version on with different major and minor on default branch" {
  result=$(_calculate_version "master" "0.0.1-5-aaghas27" "1" "1" "master")
  [ "$result" == "1.1.0" ]
}

@test "Version on second commit on feature branch" {
  result=$(_calculate_version "feature" "0.0.1-1-aaghas27" "0" "0" "master")
  [ "$result" == "0.0.1-1-aaghas27+feature" ]
}

@test "Version on fifth commit on feature branch" {
  result=$(_calculate_version "feature" "0.0.1-5-aaghas27" "0" "0" "master")
  [ "$result" == "0.0.1-5-aaghas27+feature" ]
}

@test "Version on feature branch with different minor" {
  result=$(_calculate_version "feature" "0.0.1-5-aaghas27" "0" "1" "master")
  [ "$result" == "0.0.1-5-aaghas27+feature" ]
}

@test "Version on feature branch with different major" {
  result=$(_calculate_version "feature" "0.0.1-5-aaghas27" "1" "0" "master")
  [ "$result" == "0.0.1-5-aaghas27+feature" ]
}

@test "Version on feature branch with different major and minor" {
  result=$(_calculate_version "feature" "0.0.1-5-aaghas27" "1" "1" "master")
  [ "$result" == "0.0.1-5-aaghas27+feature" ]
}
