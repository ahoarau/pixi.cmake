# pixi.cmake

**pixi.cmake** is a single-file CMake utility that uses [pixi](https://prefix.dev/) to install your project's dependencies and automatically wire them into `CMAKE_PREFIX_PATH`, so `find_package` just works.

Public functions: `pixi_bootstrap`, `pixi_install_dependencies`, and `pixi_dependencies`.

## Requirements

- CMake ≥ 3.20
- [pixi](https://prefix.dev/) installed and in `PATH` — **or** use `pixi_bootstrap` below to download it automatically
- A `pixi.toml` in your project root when using `pixi_install_dependencies`
- No source-tree `pixi.toml` is required when using `pixi_dependencies`

## Usage

### Bootstrap pixi locally

If pixi is not (yet) installed on the system, `pixi_bootstrap` downloads the correct binary from GitHub and sets `PIXI_EXECUTABLE`:

```cmake
cmake_minimum_required(VERSION 3.20)

include(pixi.cmake)

# Download latest pixi into .pixi-bin/ (skipped if already present)
pixi_bootstrap()
# pixi_bootstrap(VERSION v0.44.0)           # pin a specific version
# pixi_bootstrap(INSTALL_DIR /opt/pixi-bin) # custom install directory

pixi_install_dependencies()
project(MyProject)
```

Supported platforms: Linux x86_64/ARM64, macOS x86_64/ARM64, Windows x86_64.

### Install dependencies from pixi.toml

Copy `pixi.cmake` into your project (or reference it directly), then call `pixi_install_dependencies` **before** your `project()` declaration:

```cmake
cmake_minimum_required(VERSION 3.20)

include(pixi.cmake)
pixi_install_dependencies()          # uses the "default" pixi environment
# pixi_install_dependencies(ENVIRONMENT dev)  # or a named environment
# pixi_install_dependencies(PROJECT_DIR ${CMAKE_SOURCE_DIR}/third_party/deps)  # custom pixi.toml location
# pixi_install_dependencies(ENVIRONMENT dev PROJECT_DIR ${CMAKE_SOURCE_DIR}/third_party/deps)

project(MyProject)

find_package(Boost REQUIRED)            # resolved from the pixi prefix
```

At configure time, pixi.cmake will:

1. **Fast path** — if CMake is invoked via `pixi run cmake` or inside `pixi shell`, the active environment prefix is read directly from `$CONDA_PREFIX`/`$PIXI_ENVIRONMENT_NAME` and steps 2–3 are skipped.
2. Run `pixi install` to lock and install all dependencies declared in `pixi.toml`.
    If `PROJECT_DIR` is provided, that directory is used instead of `CMAKE_CURRENT_SOURCE_DIR`.
3. Resolve the environment prefix via `pixi info --json`.
4. Extend `CMAKE_PREFIX_PATH` and `PATH` so every subsequent `find_package`/`find_program` call can locate the installed packages.

### Install dependencies directly from CMake

If you do not want a source-tree `pixi.toml`, use `pixi_dependencies` to generate one in the build directory and install from that generated project:

```cmake
cmake_minimum_required(VERSION 3.20)

include(pixi.cmake)
pixi_dependencies(
    CHANNELS "conda-forge"
    PLATFORMS "linux-64" "osx-64" "osx-arm64" "win-64"
    DEPENDENCIES [[
libboost-devel = ">=1.85.0,<2"
]]
)

project(MyProject)
```

## Options

### `pixi_bootstrap`

| Argument | Description |
| --- | --- |
| `INSTALL_DIR <dir>` | Directory to download pixi into (default: `.pixi-bin/`). |
| `VERSION <tag>` | Pin a specific release tag, e.g. `v0.44.0` (default: latest). |

### `pixi_install_dependencies`

| Argument | Description |
| --- | --- |
| `ENVIRONMENT <name>` | Use a named pixi environment instead of `default`. |
| `PIXI_VERSION <tag>` | Pin a specific pixi version for auto-bootstrap, e.g. `v0.44.0`. |
| `PROJECT_DIR <dir>` | Use a project directory other than `CMAKE_CURRENT_SOURCE_DIR` (must contain `pixi.toml`). |
| `NO_FETCH_PIXI` | Fail with a fatal error if pixi is not already in `PATH` instead of bootstrapping it automatically. |

### `pixi_dependencies`

| Argument | Description |
| --- | --- |
| `CHANNELS <name...>` | Optional. Channel names for the generated pixi workspace (default: `conda-forge`). |
| `PLATFORMS <name...>` | Optional. Platform identifiers for the generated pixi workspace (default: `linux-64`, `osx-64`, `osx-arm64`, `win-64`). |
| `DEPENDENCIES <toml-entries>` | Required. TOML entries written under `[dependencies]` in the generated manifest. |
| `ENVIRONMENT <name>` | Optional environment name (default: `default`). |
| `PIXI_VERSION <tag>` | Optional pixi version for auto-bootstrap. |
| `NO_FETCH_PIXI` | Optional. Do not auto-bootstrap pixi if missing from `PATH`. |

## Example

See [tests/test_boost/CMakeLists.txt](tests/test_boost/CMakeLists.txt) for a minimal working example that finds Boost via a pixi environment.

See [tests/test_inline_dependencies/CMakeLists.txt](tests/test_inline_dependencies/CMakeLists.txt) for a generated-manifest example using `pixi_dependencies`.

See [tests/test_inline_dependencies_defaults/CMakeLists.txt](tests/test_inline_dependencies_defaults/CMakeLists.txt) for a `pixi_dependencies` example that only specifies `DEPENDENCIES` and relies on default channels/platforms.

See [tests/test_inline_dependencies_dev/CMakeLists.txt](tests/test_inline_dependencies_dev/CMakeLists.txt) for a `pixi_dependencies` example using `ENVIRONMENT dev`.
