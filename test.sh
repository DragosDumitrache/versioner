#!/usr/bin/env bash
source /work/version.sh

source critic.sh


_describe "Version if not git repo"
    _test "Should be 1.0.0-SNAPSHOT" semver "1"
        _assert _output_equals "1.0.0-SNAPSHOT"

_describe "Version on first commit default branch"
    _test "Should be 0.0.0" calculate_version "master" "vskd341" "0" "0" "master"
        _assert _output_equals "0.0.0"

_describe "Version on second commit default branch"
    _test "Should be 0.0.2" calculate_version "master" "0.0.2" "0" "0" "master"
        _assert _output_equals "0.0.2"

_describe "Version on fifth commit default branch"
    _test "Should be 0.0.6" calculate_version "master" "0.0.6" "0" "0" "master"
        _assert _output_equals "0.0.6"

_describe "Version on with different minor on default branch"
    _test "Should be 0.1.0" calculate_version "master" "0.0.1-5-aaghas27" "0" "1" "master"
        _assert _output_equals "0.1.0"

_describe "Version on with different major on default branch"
    _test "Should be 1.0.0" calculate_version "master" "0.0.1-5-aaghas27" "1" "0" "master"
        _assert _output_equals "1.0.0"

_describe "Version on with different major and minor on default branch"
    _test "Should be 1.1.0" calculate_version "master" "0.0.1-5-aaghas27" "1" "1" "master"
        _assert _output_equals "1.1.0"

_describe "Version on second commit on feature branch"
    _test "Should be 0.0.1-1-aaghas27-feature" calculate_version "feature" "0.0.1-1-aaghas27" "0" "0" "master"
        _assert _output_equals "0.0.1-1-aaghas27-feature"

_describe "Version on fifth commit on feature branch"
    _test "Should be 0.0.1-5-aaghas27-feature" calculate_version "feature" "0.0.1-5-aaghas27" "0" "0" "master"
        _assert _output_equals "0.0.1-5-aaghas27-feature"

_describe "Version on feature branch with different minor"
    _test "Should be 0.0.1-5-aaghas27-feature" calculate_version "feature" "0.0.1-5-aaghas27" "0" "1" "master"
        _assert _output_equals "0.0.1-5-aaghas27-feature"

_describe "Version on feature branch with different major"
    _test "Should be 0.0.1-5-aaghas27-feature" calculate_version "feature" "0.0.1-5-aaghas27" "1" "0" "master"
        _assert _output_equals "0.0.1-5-aaghas27-feature"

_describe "Version on feature branch with different major and minor"
    _test "Should be 0.0.1-5-aaghas27-feature" calculate_version "feature" "0.0.1-5-aaghas27" "1" "1" "master"
        _assert _output_equals "0.0.1-5-aaghas27-feature"

_describe "Version on default branch even if tag starts with v"
    _test "Should be 0.0.2" calculate_version "master" "0.0.2" "0" "0" "master"
        _assert _output_equals "0.0.2"