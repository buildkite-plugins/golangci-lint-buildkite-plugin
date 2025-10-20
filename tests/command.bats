#!/usr/bin/env bats

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"

  # Uncomment to enable stub debugging
  # export DOCKER_STUB_DEBUG=/dev/tty
  # export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

  # Set default environment variables
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_USE_DOCKER='true'
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_DOCKER_IMAGE='golangci/golangci-lint:latest'
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_MOUNT_GIT='false'  # Disable for tests to simplify stubs
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_IGNORE_LINTER_ERRORS='false'
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_CREATE_ANNOTATIONS='false'  # Disable for most tests
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_RUN_FORMATTER='false'
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_ISSUES_EXIT_CODE='1'
}

@test "Runs golangci-lint with Docker by default" {
  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --issues-exit-code 1 : echo 'Running linter'"

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Running golangci-lint'
  assert_output --partial 'Using Docker image: golangci/golangci-lint:latest'

  unstub docker
}

@test "Uses custom Docker image when specified" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_DOCKER_IMAGE='golangci/golangci-lint:v1.55.2'

  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:v1.55.2 golangci-lint run --issues-exit-code 1 : echo 'Running linter'"

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Using Docker image: golangci/golangci-lint:v1.55.2'

  unstub docker
}

@test "Runs golangci-lint without Docker when use_docker is false" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_USE_DOCKER='false'

  stub golangci-lint \
    "run --issues-exit-code 1 : echo 'Running linter without Docker'"

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Using golangci-lint from PATH'

  unstub golangci-lint
}

@test "Fails when golangci-lint not in PATH and use_docker is false" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_USE_DOCKER='false'

  run "$PWD"/hooks/command

  assert_failure
  assert_output --partial 'golangci-lint not found in PATH'
}

@test "Passes timeout flag when specified" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_TIMEOUT='5m'

  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --timeout 5m --issues-exit-code 1 : echo 'Running with timeout'"

  run "$PWD"/hooks/command

  assert_success

  unstub docker
}

@test "Passes config flag when specified" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_CONFIG='.golangci.yml'

  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --config .golangci.yml --issues-exit-code 1 : echo 'Running with config'"

  run "$PWD"/hooks/command

  assert_success

  unstub docker
}

@test "Passes custom issues_exit_code when specified" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_ISSUES_EXIT_CODE='0'

  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --issues-exit-code 0 : echo 'Running with custom exit code'"

  run "$PWD"/hooks/command

  assert_success

  unstub docker
}

@test "Passes cache_dir flag when specified" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_CACHE_DIR="/tmp/golangci-lint-$$"

  # Create the cache directory so it can be mounted
  mkdir -p "/tmp/golangci-lint-$$"

  stub docker \
    "run --rm -v ${PWD}:/app -w /app -v /tmp/golangci-lint-$$:/cache golangci/golangci-lint:latest golangci-lint run --issues-exit-code 1 --cache-dir /tmp/golangci-lint-$$ : echo 'Running with cache dir'"

  run "$PWD"/hooks/command

  assert_success

  rm -rf "/tmp/golangci-lint-$$"

  unstub docker
}

@test "Runs formatter when run_formatter is true" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_RUN_FORMATTER='true'

  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --issues-exit-code 1 : echo 'Running linter'" \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint fmt --diff : echo 'Running formatter'"

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Checking Go code formatting'

  unstub docker
}

@test "Fails when linter finds issues and ignore_linter_errors is false" {
  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --issues-exit-code 1 : exit 1"

  run "$PWD"/hooks/command

  assert_failure 1
  assert_output --partial 'Linting found issues'

  unstub docker
}

@test "Succeeds when linter finds issues but ignore_linter_errors is true" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_IGNORE_LINTER_ERRORS='true'

  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --issues-exit-code 1 : exit 1"

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Linter errors ignored'

  unstub docker
}

@test "Fails when formatter finds issues and ignore_formatter_errors is false" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_RUN_FORMATTER='true'

  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --issues-exit-code 1 : echo 'Linter passed'" \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint fmt --diff : exit 1"

  run "$PWD"/hooks/command

  assert_failure 1
  assert_output --partial 'Formatting issues found'

  unstub docker
}

@test "Succeeds when formatter finds issues but ignore_formatter_errors is true" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_RUN_FORMATTER='true'
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_IGNORE_FORMATTER_ERRORS='true'

  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --issues-exit-code 1 : echo 'Linter passed'" \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint fmt --diff : exit 1"

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Formatter errors ignored'

  unstub docker
}

@test "Creates annotations when create_annotations is true and buildkite-agent is available" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_CREATE_ANNOTATIONS='true'

  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --issues-exit-code 1 : echo 'No issues found'"

  stub buildkite-agent \
    "annotate --style success --context golangci-lint : echo 'Annotation created'"

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Created annotation for linter results'

  unstub docker
  unstub buildkite-agent
}

@test "Creates formatter annotations when run_formatter and create_annotations are true" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_RUN_FORMATTER='true'
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_CREATE_ANNOTATIONS='true'

  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --issues-exit-code 1 : echo 'No issues found'" \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint fmt --diff : echo 'No formatting issues'"

  stub buildkite-agent \
    "annotate --style success --context golangci-lint : echo 'Linter annotation created'" \
    "annotate --style success --context golangci-lint-fmt : echo 'Formatter annotation created'"

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Created annotation for linter results'
  assert_output --partial 'Created annotation for formatter results'

  unstub docker
  unstub buildkite-agent
}

@test "Skips annotations when buildkite-agent is not available" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_CREATE_ANNOTATIONS='true'

  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --issues-exit-code 1 : echo 'No issues found'"

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'buildkite-agent not found, skipping annotation creation'

  unstub docker
}

@test "Combines all options correctly" {
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_TIMEOUT='10m'
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_CONFIG='.golangci.yml'
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_ISSUES_EXIT_CODE='2'
  export BUILDKITE_PLUGIN_GOLANGCI_LINT_CACHE_DIR="/tmp/golangci-lint-combined-$$"

  # Create the cache directory so it can be mounted
  mkdir -p "/tmp/golangci-lint-combined-$$"

  stub docker \
    "run --rm -v ${PWD}:/app -w /app -v /tmp/golangci-lint-combined-$$:/cache golangci/golangci-lint:latest golangci-lint run --timeout 10m --config .golangci.yml --issues-exit-code 2 --cache-dir /tmp/golangci-lint-combined-$$ : echo 'Running with all options'"

  run "$PWD"/hooks/command

  assert_success

  rm -rf "/tmp/golangci-lint-combined-$$"

  unstub docker
}

@test "Succeeds when linter passes" {
  stub docker \
    "run --rm -v ${PWD}:/app -w /app golangci/golangci-lint:latest golangci-lint run --issues-exit-code 1 : echo 'No issues found'"

  run "$PWD"/hooks/command

  assert_success
  assert_output --partial 'Linting completed successfully'
  assert_output --partial 'All checks passed'

  unstub docker
}
