# golangci-lint Buildkite Plugin

A Buildkite plugin for running [golangci-lint](https://golangci-lint.run/) to lint and format Go code in your CI/CD pipeline.

## Quick Start

Add the plugin to your Buildkite pipeline:

```yaml
steps:
  - label: ":golang: Lint"
    plugins:
      - golangci-lint#v1.0.0: ~
```

This will run golangci-lint with default settings using Docker.

## Configuration Options

All options are optional unless specified otherwise.

### Docker Options

#### `use_docker` (boolean)

Use Docker to run golangci-lint. If set to `false`, golangci-lint must be available in `$PATH`.

**Default:** `true`

#### `docker_image` (string)

Docker image to use for golangci-lint.

**Default:** `golangci/golangci-lint:latest`

### Linter Options

#### `ignore_linter_errors` (boolean)

Whether to ignore linter errors and allow the step to pass even if issues are found.

**Default:** `false`

#### `create_annotations` (boolean)

Create Buildkite annotations to visibly display the outcome of the linter.

**Default:** `true`

#### `timeout` (string)

Timeout duration for the linter run command (e.g., `5m`, `1h`, `30s`). Maps to `--timeout` flag.

**Example:** `5m`

#### `config` (string)

Path to golangci-lint config file (`.golangci.yml`, `.golangci.yaml`, `.golangci.toml`, `.golangci.json`). Maps to `--config` flag.

**Example:** `.golangci.yml`

#### `issues_exit_code` (number)

Exit code when issues are found. Allows for control of soft_fail steps. Maps to `--issues-exit-code` flag.

**Default:** `1`

#### `cache_dir` (string)

Directory to use for golangci-lint cache. Maps to `--cache-dir` flag.

**Absolute paths** (e.g., `/tmp/golangci-lint-cache`) are mounted to the same path in the container.
**Relative paths** (e.g., `.cache/golangci-lint`) are resolved relative to the working directory and mounted under `/app/` in the container.

See [golangci-lint cache documentation](https://golangci-lint.run/docs/configuration/cli/#cache) for more details.

**Example (absolute):** `/tmp/golangci-lint-cache`
**Example (relative):** `.cache/golangci-lint`

### Formatter Options

#### `run_formatter` (boolean)

Run `golangci-lint fmt --diff` to check Go source file formatting.

**Default:** `false`

#### `ignore_formatter_errors` (boolean)

Whether to ignore formatter errors and allow the step to pass. Only applies if `run_formatter` is `true`.

**Default:** `false`

### Other Options

#### `working_directory` (string)

Working directory to run golangci-lint in.

**Default:** Current directory

## Examples

### Basic usage with defaults

Minimal configuration using Docker with default settings:

```yaml
steps:
  - label: ":golang: Lint Go code"
    plugins:
      - golangci-lint#v1.0.0: ~
```

### With custom timeout and config

Using a custom configuration file and timeout:

```yaml
steps:
  - label: ":golang: Lint Go code"
    plugins:
      - golangci-lint#v1.0.0:
          timeout: "5m"
          config: ".golangci.yml"
```

### Using local golangci-lint binary

Run golangci-lint without Docker (requires golangci-lint in PATH):

```yaml
steps:
  - label: ":golang: Lint Go code"
    plugins:
      - golangci-lint#v1.0.0:
          use_docker: false
```

### With formatter check

Enable formatting check in addition to linting:

```yaml
steps:
  - label: ":golang: Lint and format check"
    plugins:
      - golangci-lint#v1.0.0:
          run_formatter: true
```

### Soft fail (ignore errors)

Allow the step to pass even if linter finds issues:

```yaml
steps:
  - label: ":golang: Lint Go code (soft fail)"
    plugins:
      - golangci-lint#v1.0.0:
          ignore_linter_errors: true
```

### Custom Docker image

Use a specific version of golangci-lint:

```yaml
steps:
  - label: ":golang: Lint Go code"
    plugins:
      - golangci-lint#v1.0.0:
          docker_image: "golangci/golangci-lint:v1.55.2"
```

### With custom cache directory

Configure a custom cache directory for faster subsequent runs:

```yaml
steps:
  - label: ":golang: Lint Go code"
    plugins:
      - golangci-lint#v1.0.0:
          cache_dir: ".cache/golangci-lint"
```

### Without annotations

Disable Buildkite annotations:

```yaml
steps:
  - label: ":golang: Lint Go code"
    plugins:
      - golangci-lint#v1.0.0:
          create_annotations: false
```

### Complete example with all options

Full configuration showing all available options:

```yaml
steps:
  - label: ":golang: Comprehensive lint"
    plugins:
      - golangci-lint#v1.0.0:
          use_docker: true
          docker_image: "golangci/golangci-lint:v1.55.2"
          timeout: "10m"
          config: ".golangci.yml"
          issues_exit_code: 1
          cache_dir: ".cache/golangci-lint"
          ignore_linter_errors: false
          create_annotations: true
          run_formatter: true
          ignore_formatter_errors: false
          working_directory: "."
```

### Debug mode

Enable verbose logging for troubleshooting:

```yaml
steps:
  - label: ":golang: Lint Go code (debug)"
    plugins:
      - golangci-lint#v1.0.0: ~
    env:
      BUILDKITE_PLUGIN_DEBUG: "true"
```

## Annotations

When `create_annotations` is enabled (default), the plugin creates Buildkite annotations to display:

- **Success**: Green annotation showing the linter passed
- **Errors**: Red annotation with the full linter output showing issues found

If `run_formatter` is enabled, separate annotations are created for:

- Linter results (context: `golangci-lint`)
- Formatter results (context: `golangci-lint-fmt`)

## Exit Codes

The plugin respects golangci-lint exit codes:

- **0**: No issues found
- **1** (default): Issues found
- **Custom**: Set via `issues_exit_code` option

When `ignore_linter_errors` or `ignore_formatter_errors` is `true`, the step will always exit with 0 regardless of issues found.

## Compatibility

| Elastic Stack | Agent Stack K8s | Hosted (Mac) | Hosted (Linux) | Notes |
| :-----------: | :-------------: | :----------: | :------------: | :---- |
|       ✅       |        ⚠️        |      ⚠️       |       ✅        | **K8s**: Requires use of Docker-in-Docker or for `use_docker` to be set to `false` and a `golangci-lint` binary to be available in `PATH` <br> **Hosted (Mac)**: Requires a `golangci-lint` binary to be available in `PATH` and `use_docker` set to `false` as Docker is unavailable.   |

- ✅ Fully supported (all combinations of attributes have been tested to pass)
- ⚠️ Partially supported (some combinations cause errors/issues)

## Development

### Run tests

```bash
docker run --rm -v "$PWD:/plugin:ro" buildkite/plugin-tester
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.
