# pixi.cmake

**pixi.cmake** is a single-file CMake utility that uses [pixi](https://prefix.dev/) to install your project's dependencies and automatically wire them into `CMAKE_PREFIX_PATH` to make regular `find_package` calls just work.

Currently `pixi` is mostly used as a meta package manager that **calls** CMake via tasks, making the IDE support like VSCode difficult.

`pixi.cmake` reverts the way `pixi` is used: now `CMake` **calls** pixi.
That way, your `CMake` project stay a native `CMake` project.

Please note that you can always use `pixi shell` and start vscode from there to achieve the same result.

## Install dependencies directly from CMake (without pixi.toml)

For prototyping, you can declare the dependencies directly in your `CMakeLists.txt`.
It will generate a `pixi.toml` and download the dependencies in the build directory.

```cmake
cmake_minimum_required(VERSION 3.20)

include(pixi.cmake)

pixi_dependencies(
    DEPENDENCIES [[
libboost-devel = ">=1.85.0,<2"
eigen = ">=3.4.0"
]]
)

project(MyProject)

find_package(Eigen3 CONFIG REQUIRED)
find_package(Boost REQUIRED)
```

## Install dependencies from pixi.toml

A more long-term way to integrate `pixi.cmake` is to use the `pixi.toml`:

`pixi.toml`
```toml
[workspace]
name = "test_pixi_boost"
version = "0.1.0"
description = "Test project for pixi.cmake"
authors = ["Test <test@example.com>"]
channels = ["conda-forge"]
platforms = ["linux-64", "osx-64", "osx-arm64", "win-64"]

[dependencies]
libboost-devel= ">=1.85.0,<2"
```

`CMakeLists.txt`
```cmake
cmake_minimum_required(VERSION 3.20)

include(pixi.cmake)
pixi_install_dependencies()  # This will call 'pixi install -e default'

project(MyProject)

find_package(Boost REQUIRED)
```

## API Documentation

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
