set(_test_dir "${CMAKE_CURRENT_SOURCE_DIR}")
set(_binary_dir "${CMAKE_CURRENT_BINARY_DIR}")

add_test(
    NAME bootstrap
    COMMAND
        "${CMAKE_CTEST_COMMAND}" --build-and-test "${_test_dir}/test_bootstrap" "${_binary_dir}/test_bootstrap"
        --build-generator "${CMAKE_GENERATOR}"
)

add_test(
    NAME install_dependencies
    COMMAND
        "${CMAKE_CTEST_COMMAND}" --build-and-test "${_test_dir}/test_boost" "${_binary_dir}/test_boost"
        --build-generator "${CMAKE_GENERATOR}"
)

add_test(
    NAME inline_dependencies
    COMMAND
        "${CMAKE_CTEST_COMMAND}" --build-and-test "${_test_dir}/test_inline_dependencies"
        "${_binary_dir}/test_inline_dependencies" --build-generator "${CMAKE_GENERATOR}"
)

add_test(
    NAME inline_dependencies_defaults
    COMMAND
        "${CMAKE_CTEST_COMMAND}" --build-and-test "${_test_dir}/test_inline_dependencies_defaults"
        "${_binary_dir}/test_inline_dependencies_defaults" --build-generator "${CMAKE_GENERATOR}"
)

add_test(
    NAME inline_dependencies_dev
    COMMAND
        "${CMAKE_CTEST_COMMAND}" --build-and-test "${_test_dir}/test_inline_dependencies_dev"
        "${_binary_dir}/test_inline_dependencies_dev" --build-generator "${CMAKE_GENERATOR}"
)

add_test(
    NAME fetchcontent_local_source_dir
    COMMAND
        "${CMAKE_CTEST_COMMAND}" --build-and-test "${_test_dir}/test_fetchcontent_local_source_dir"
        "${_binary_dir}/test_fetchcontent_local_source_dir" --build-generator "${CMAKE_GENERATOR}"
)
