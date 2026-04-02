# pixi.cmake

**pixi.cmake** is a single-file CMake utility that uses [pixi](https://prefix.dev/) to install your project's dependencies and automatically wire them into `CMAKE_PREFIX_PATH`, so `find_package` just works.

Public functions: `pixi_bootstrap` and `pixi_install_dependencies`.

## Requirements

- CMake ≥ 3.20
- [pixi](https://prefix.dev/) installed and in `PATH` — **or** use `pixi_bootstrap` below to download it automatically
- A `pixi.toml` in your project root

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

project(MyProject)

find_package(Boost REQUIRED)            # resolved from the pixi prefix
```

At configure time, pixi.cmake will:

1. **Fast path** — if CMake is invoked via `pixi run cmake` or inside `pixi shell`, the active environment prefix is read directly from `$CONDA_PREFIX`/`$PIXI_ENVIRONMENT_NAME` and steps 2–3 are skipped.
2. Run `pixi install` to lock and install all dependencies declared in `pixi.toml`.
3. Resolve the environment prefix via `pixi info --json`.
4. Extend `CMAKE_PREFIX_PATH`, `CMAKE_PROGRAM_PATH`, `PATH`, and `PKG_CONFIG_PATH` so every subsequent `find_package`/`find_program` call can locate the installed packages.

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
| `NO_FETCH_PIXI` | Fail with a fatal error if pixi is not already in `PATH` instead of bootstrapping it automatically. |

## Example

See [tests/test_boost/CMakeLists.txt](tests/test_boost/CMakeLists.txt) for a minimal working example that finds Boost via a pixi environment.
