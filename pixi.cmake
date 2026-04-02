# pixi.cmake
# A utility to allow people to use pixi to install dependencies for their CMake project.
# Requires CMake >= 3.20.
#
# ---------------------------------------------------------------------------
# pixi_install_dependencies(
#   [ENVIRONMENT <name>]    # pixi environment to install (default: "default")
#   [PIXI_VERSION <tag>]    # pin a pixi version for auto-bootstrap, e.g. v0.44.0
#   [PROJECT_DIR <dir>]     # project directory containing pixi.toml (default: CMAKE_CURRENT_SOURCE_DIR)
#   [NO_FETCH_PIXI]         # fatal error if pixi is not in PATH instead of bootstrapping
# )
#
# Calls `pixi install` and extends CMAKE_PREFIX_PATH and PATH so that
# find_package and find_program work out of the box. When invoked via
# `pixi run cmake` or inside `pixi shell` the
# active environment prefix is read from $CONDA_PREFIX / $PIXI_ENVIRONMENT_NAME
# and the pixi install + info steps are skipped entirely.
#
# ---------------------------------------------------------------------------
# pixi_dependencies(
#   DEPENDENCIES <toml-entries>
#   [CHANNELS <name...>]    # default: conda-forge
#   [PLATFORMS <name...>]   # default: linux-64 osx-64 osx-arm64 win-64
#   [ENVIRONMENT <name>]    # optional named environment (default: "default")
#   [PIXI_VERSION <tag>]    # pin a pixi version for auto-bootstrap, e.g. v0.44.0
#   [NO_FETCH_PIXI]         # fatal error if pixi is not in PATH instead of bootstrapping
# )
#
# Generates a pixi.toml under CMAKE_CURRENT_BINARY_DIR/.pixi-cmake/<hash>/
# and delegates to pixi_install_dependencies(PROJECT_DIR ...).
#
# ---------------------------------------------------------------------------
# pixi_bootstrap(
#   [INSTALL_DIR <dir>]     # download directory (default: .pixi-bin/)
#   [VERSION <tag>]         # pin a specific release, e.g. v0.44.0 (default: latest)
# )
#
# Downloads the correct pixi binary for the current platform from GitHub into
# <dir> and sets PIXI_EXECUTABLE in the parent scope. The download is skipped
# if the binary already exists. Supported: Linux x86_64/ARM64, macOS
# x86_64/ARM64, Windows x86_64.

# ---------------------------------------------------------------------------
# Internal helper: prepend <path> to an environment variable if not already
# present. Uses the OS-native list separator (';' on Windows, ':' elsewhere)
# and cmake_path for portable path normalization — no regex required.
# ---------------------------------------------------------------------------
function(_pixi_prepend_env_path ENV_VAR NEW_PATH)
    set(_p "${NEW_PATH}")
    cmake_path(NATIVE_PATH _p NORMALIZE _native)
    if(CMAKE_HOST_WIN32)
        set(_sep ";")
    else()
        set(_sep ":")
    endif()
    string(REPLACE "${_sep}" ";" _entries "$ENV{${ENV_VAR}}")
    if(NOT "${_native}" IN_LIST _entries)
        if("$ENV{${ENV_VAR}}" STREQUAL "")
            set(ENV{${ENV_VAR}} "${_native}")
        else()
            set(ENV{${ENV_VAR}} "${_native}${_sep}$ENV{${ENV_VAR}}")
        endif()
    endif()
endfunction()

# ---------------------------------------------------------------------------
# Internal helper: ensure a required CMake variable is defined and non-empty.
# ---------------------------------------------------------------------------
function(_pixi_require_cmake_var VAR_NAME)
    if(NOT DEFINED ${VAR_NAME} OR "${${VAR_NAME}}" STREQUAL "")
        message(FATAL_ERROR "pixi.cmake: required CMake variable '${VAR_NAME}' is not set.")
    endif()
endfunction()

# ---------------------------------------------------------------------------
# pixi_bootstrap([INSTALL_DIR <dir>] [VERSION <tag>])
#
# Downloads the latest pixi release from GitHub (or a pinned <tag> such as
# "v0.44.0") into <dir> (default: ${CMAKE_CURRENT_SOURCE_DIR}/.pixi-bin).
# After the call, PIXI_EXECUTABLE is set in the parent scope to the path of
# the downloaded binary, so you can pass it to pixi_install_dependencies
# or use it directly.
# ---------------------------------------------------------------------------
function(pixi_bootstrap)
    set(options "")
    set(oneValueArgs INSTALL_DIR VERSION)
    set(multiValueArgs "")
    cmake_parse_arguments(arg "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # --- resolve install directory ------------------------------------------
    if(DEFINED arg_INSTALL_DIR AND NOT "${arg_INSTALL_DIR}" STREQUAL "")
        set(_install_dir "${arg_INSTALL_DIR}")
    else()
        set(_install_dir "${CMAKE_CURRENT_SOURCE_DIR}/.pixi-bin")
    endif()

    # --- resolve target asset name for this platform ------------------------
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
        if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
            set(_asset_stem "pixi-aarch64-apple-darwin")
        else()
            set(_asset_stem "pixi-x86_64-apple-darwin")
        endif()
        set(_archive_ext ".tar.gz")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
        if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
            set(_asset_stem "pixi-aarch64-unknown-linux-musl")
        else()
            set(_asset_stem "pixi-x86_64-unknown-linux-musl")
        endif()
        set(_archive_ext ".tar.gz")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        set(_asset_stem "pixi-x86_64-pc-windows-msvc")
        set(_archive_ext ".zip")
    else()
        message(FATAL_ERROR "pixi_bootstrap: unsupported platform '${CMAKE_HOST_SYSTEM_NAME}'.")
    endif()

    set(_asset_name "${_asset_stem}${_archive_ext}")

    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        set(_binary_name "pixi.exe")
    else()
        set(_binary_name "pixi")
    endif()

    set(_pixi_exe "${_install_dir}/${_binary_name}")

    # --- skip download if the binary already exists -------------------------
    if(EXISTS "${_pixi_exe}")
        message(STATUS "pixi_bootstrap: pixi already present at ${_pixi_exe}, skipping download.")
        set(PIXI_EXECUTABLE "${_pixi_exe}" PARENT_SCOPE)
        return()
    endif()

    file(MAKE_DIRECTORY "${_install_dir}")

    # --- resolve download URL -----------------------------------------------
    if(DEFINED arg_VERSION AND NOT "${arg_VERSION}" STREQUAL "")
        set(_download_url "https://github.com/prefix-dev/pixi/releases/download/${arg_VERSION}/${_asset_name}")
    else()
        # Use the /latest/download/ redirect — no API call required
        set(_download_url "https://github.com/prefix-dev/pixi/releases/latest/download/${_asset_name}")
    endif()

    # --- download archive ---------------------------------------------------
    set(_archive_file "${_install_dir}/${_asset_name}")
    message(STATUS "pixi_bootstrap: downloading ${_download_url} ...")
    file(DOWNLOAD "${_download_url}" "${_archive_file}" SHOW_PROGRESS STATUS _dl_status)
    list(GET _dl_status 0 _dl_code)
    if(NOT _dl_code EQUAL 0)
        list(GET _dl_status 1 _dl_err)
        message(FATAL_ERROR "pixi_bootstrap: download failed: ${_dl_err}")
    endif()

    # --- extract binary -----------------------------------------------------
    message(STATUS "pixi_bootstrap: extracting ${_asset_name} ...")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xf "${_archive_file}"
        WORKING_DIRECTORY "${_install_dir}"
        RESULT_VARIABLE _extract_result
    )
    file(REMOVE "${_archive_file}")
    if(NOT _extract_result EQUAL 0)
        message(FATAL_ERROR "pixi_bootstrap: extraction failed.")
    endif()

    if(NOT EXISTS "${_pixi_exe}")
        message(FATAL_ERROR "pixi_bootstrap: expected binary not found at ${_pixi_exe} after extraction.")
    endif()

    # Make executable on Unix
    if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
        execute_process(COMMAND chmod +x "${_pixi_exe}")
    endif()

    message(STATUS "pixi_bootstrap: pixi installed at ${_pixi_exe}")
    set(PIXI_EXECUTABLE "${_pixi_exe}" PARENT_SCOPE)
endfunction()

# ---------------------------------------------------------------------------
# pixi_install_dependencies([ENVIRONMENT <name>] [PIXI_VERSION <tag>]
#                               [PROJECT_DIR <dir>] [NO_FETCH_PIXI])
#
# Runs `pixi install` for the given environment and extends:
#   CMAKE_PREFIX_PATH   — so find_package / find_library / find_path work
#   PATH (env)          — so find_program also finds tools via the env PATH
#
# If CMake is invoked through `pixi run cmake` or inside `pixi shell`, the
# active environment prefix is read directly from $CONDA_PREFIX /
# $PIXI_ENVIRONMENT_NAME and the `pixi install` + `pixi info` calls are
# skipped entirely.
#
# If pixi is not found in PATH, it is bootstrapped automatically via
# pixi_bootstrap() unless NO_FETCH_PIXI is set.
# ---------------------------------------------------------------------------
function(pixi_install_dependencies)
    _pixi_require_cmake_var(CMAKE_CURRENT_SOURCE_DIR)

    set(options NO_FETCH_PIXI)
    set(oneValueArgs ENVIRONMENT PIXI_VERSION PROJECT_DIR)
    set(multiValueArgs "")
    cmake_parse_arguments(pixi "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(_project_dir "${CMAKE_CURRENT_SOURCE_DIR}")
    if(DEFINED pixi_PROJECT_DIR AND NOT "${pixi_PROJECT_DIR}" STREQUAL "")
        set(_project_dir "${pixi_PROJECT_DIR}")
    endif()

    set(_env_name "default")
    if(DEFINED pixi_ENVIRONMENT AND NOT "${pixi_ENVIRONMENT}" STREQUAL "")
        set(_env_name "${pixi_ENVIRONMENT}")
    endif()

    # --- Fast path: already running inside the target pixi environment ------
    # When cmake is invoked via `pixi run cmake` or inside `pixi shell`,
    # CONDA_PREFIX holds the active environment prefix and PIXI_ENVIRONMENT_NAME
    # holds its name — skip `pixi install` and `pixi info` entirely.
    if(
        "${_project_dir}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}"
        AND DEFINED ENV{CONDA_PREFIX}
        AND DEFINED ENV{PIXI_ENVIRONMENT_NAME}
        AND "$ENV{PIXI_ENVIRONMENT_NAME}" STREQUAL "${_env_name}"
    )
        set(_prefix "$ENV{CONDA_PREFIX}")
        message(STATUS "Already inside pixi environment '${_env_name}': ${_prefix}")
    else()
        # --- resolve pixi executable ----------------------------------------
        if(NOT PIXI_EXECUTABLE)
            find_program(PIXI_EXECUTABLE pixi)
        endif()
        if(NOT PIXI_EXECUTABLE)
            if(pixi_NO_FETCH_PIXI)
                message(FATAL_ERROR "pixi executable not found. Please ensure it is installed and in your PATH.")
            endif()
            message(STATUS "pixi not found in PATH — bootstrapping via pixi_bootstrap()")
            if(DEFINED pixi_PIXI_VERSION AND NOT "${pixi_PIXI_VERSION}" STREQUAL "")
                pixi_bootstrap(VERSION "${pixi_PIXI_VERSION}")
            else()
                pixi_bootstrap()
            endif()
            if(NOT PIXI_EXECUTABLE)
                message(FATAL_ERROR "pixi_bootstrap() did not set PIXI_EXECUTABLE.")
            endif()
        endif()

        if(NOT EXISTS "${_project_dir}/pixi.toml")
            message(FATAL_ERROR "No pixi.toml found in ${_project_dir}.")
        endif()

        set(_env_args "")
        if(NOT "${_env_name}" STREQUAL "default")
            set(_env_args "-e" "${_env_name}")
        endif()

        message(STATUS "Running pixi install...")
        execute_process(
            COMMAND ${PIXI_EXECUTABLE} install ${_env_args}
            WORKING_DIRECTORY ${_project_dir}
            RESULT_VARIABLE _install_result
        )
        if(NOT _install_result EQUAL 0)
            message(FATAL_ERROR "pixi install failed with error code ${_install_result}.")
        endif()

        # --- resolve environment prefix via pixi info --json ----------------
        # `pixi info --json` returns a JSON object whose "environments_info" key
        # is an array of objects, one per environment, e.g.:
        #   {
        #     "environments_info": [
        #       { "name": "default", "prefix": "/path/to/.pixi/envs/default", ... },
        #       { "name": "dev",     "prefix": "/path/to/.pixi/envs/dev",     ... }
        #     ]
        #   }
        # We iterate the array to find the entry whose "name" matches _env_name
        # and read its "prefix" — the on-disk conda environment root we need.
        execute_process(
            COMMAND ${PIXI_EXECUTABLE} info --json
            WORKING_DIRECTORY ${_project_dir}
            OUTPUT_VARIABLE _info_json
            OUTPUT_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE _info_result
        )

        set(_prefix "")
        if(_info_result EQUAL 0)
            string(JSON _count ERROR_VARIABLE _err LENGTH "${_info_json}" "environments_info")
            if(NOT _err AND _count GREATER 0)
                math(EXPR _last "${_count} - 1")
                foreach(_i RANGE ${_last})
                    string(JSON _name ERROR_VARIABLE _err GET "${_info_json}" "environments_info" ${_i} "name")
                    if(NOT _err AND _name STREQUAL _env_name)
                        string(JSON _prefix ERROR_VARIABLE _err GET "${_info_json}" "environments_info" ${_i} "prefix")
                        break()
                    endif()
                endforeach()
            endif()
        endif()

        if("${_prefix}" STREQUAL "")
            set(_prefix "${_project_dir}/.pixi/envs/${_env_name}")
        endif()
    endif()

    if(NOT EXISTS "${_prefix}")
        message(FATAL_ERROR "Pixi environment prefix '${_prefix}' does not exist.")
    endif()

    message(STATUS "Pixi environment prefix: ${_prefix}")

    # --- CMAKE_PREFIX_PATH (find_package / find_library / find_path) --------
    list(APPEND CMAKE_PREFIX_PATH "${_prefix}")
    if(CMAKE_HOST_WIN32)
        # conda-based environments install headers/libs under Library/
        cmake_path(APPEND _prefix "Library" OUTPUT_VARIABLE _win_lib)
        list(APPEND CMAKE_PREFIX_PATH "${_win_lib}")
    endif()
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)

    # --- tool directories inside the pixi prefix ---------------------------
    cmake_path(APPEND _prefix "bin" OUTPUT_VARIABLE _bin_dir)
    if(CMAKE_HOST_WIN32)
        cmake_path(APPEND _prefix "Library" "bin" OUTPUT_VARIABLE _lib_bin_dir)
        cmake_path(APPEND _prefix "Scripts" OUTPUT_VARIABLE _scripts_dir)
    endif()

    # --- PATH (env) — find_program() also searches PATH ---------------------
    _pixi_prepend_env_path(PATH "${_bin_dir}")
    if(CMAKE_HOST_WIN32)
        _pixi_prepend_env_path(PATH "${_lib_bin_dir}")
        _pixi_prepend_env_path(PATH "${_scripts_dir}")
    endif()
endfunction()

# ---------------------------------------------------------------------------
# pixi_dependencies(
#   DEPENDENCIES <toml-entries>
#   [CHANNELS <name...>]   # default: conda-forge
#   [PLATFORMS <name...>]  # default: linux-64 osx-64 osx-arm64 win-64
#   [ENVIRONMENT <name>]
#   [PIXI_VERSION <tag>]
#   [NO_FETCH_PIXI]
# )
#
# Creates a generated pixi.toml in the build tree and installs dependencies
# from that generated project. This is useful when all dependency data should
# live inside CMake and no source-tree pixi.toml is desired.
# ---------------------------------------------------------------------------
function(pixi_dependencies)
    _pixi_require_cmake_var(CMAKE_CURRENT_SOURCE_DIR)
    _pixi_require_cmake_var(CMAKE_CURRENT_BINARY_DIR)

    set(options NO_FETCH_PIXI)
    set(oneValueArgs ENVIRONMENT PIXI_VERSION DEPENDENCIES)
    set(multiValueArgs CHANNELS PLATFORMS)
    cmake_parse_arguments(pixi "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT DEFINED pixi_DEPENDENCIES OR "${pixi_DEPENDENCIES}" STREQUAL "")
        message(FATAL_ERROR "pixi_dependencies: DEPENDENCIES is required.")
    endif()

    if(NOT pixi_CHANNELS)
        set(pixi_CHANNELS "conda-forge")
    endif()
    if(NOT pixi_PLATFORMS)
        set(pixi_PLATFORMS "linux-64" "osx-64" "osx-arm64" "win-64")
    endif()

    set(_env_name "default")
    if(DEFINED pixi_ENVIRONMENT AND NOT "${pixi_ENVIRONMENT}" STREQUAL "")
        set(_env_name "${pixi_ENVIRONMENT}")
    endif()

    set(_channels_toml "")
    foreach(_channel IN LISTS pixi_CHANNELS)
        if("${_channels_toml}" STREQUAL "")
            string(APPEND _channels_toml "\"${_channel}\"")
        else()
            string(APPEND _channels_toml ", \"${_channel}\"")
        endif()
    endforeach()

    set(_platforms_toml "")
    foreach(_platform IN LISTS pixi_PLATFORMS)
        if("${_platforms_toml}" STREQUAL "")
            string(APPEND _platforms_toml "\"${_platform}\"")
        else()
            string(APPEND _platforms_toml ", \"${_platform}\"")
        endif()
    endforeach()

    set(_manifest_seed "${_channels_toml}|${_platforms_toml}|${_env_name}|${pixi_DEPENDENCIES}")
    string(SHA256 _manifest_hash "${_manifest_seed}")
    string(SUBSTRING "${_manifest_hash}" 0 12 _manifest_suffix)

    set(_generated_project_dir "${CMAKE_CURRENT_BINARY_DIR}/.pixi-cmake/${_manifest_suffix}")
    file(MAKE_DIRECTORY "${_generated_project_dir}")

    set(_environments_toml "")
    if(NOT "${_env_name}" STREQUAL "default")
        set(_environments_toml
            "
[environments]
${_env_name} = []
"
        )
    endif()

    set(_generated_toml
        "
[workspace]
name = \"pixi_cmake_${_manifest_suffix}\"
channels = [${_channels_toml}]
platforms = [${_platforms_toml}]

${_environments_toml}

[dependencies]
${pixi_DEPENDENCIES}
"
    )
    file(WRITE "${_generated_project_dir}/pixi.toml" "${_generated_toml}")

    set(_forwarded_args PROJECT_DIR "${_generated_project_dir}")
    if(DEFINED pixi_ENVIRONMENT AND NOT "${pixi_ENVIRONMENT}" STREQUAL "")
        list(APPEND _forwarded_args ENVIRONMENT "${pixi_ENVIRONMENT}")
    endif()
    if(DEFINED pixi_PIXI_VERSION AND NOT "${pixi_PIXI_VERSION}" STREQUAL "")
        list(APPEND _forwarded_args PIXI_VERSION "${pixi_PIXI_VERSION}")
    endif()
    if(pixi_NO_FETCH_PIXI)
        list(APPEND _forwarded_args NO_FETCH_PIXI)
    endif()

    pixi_install_dependencies(${_forwarded_args})
endfunction()
