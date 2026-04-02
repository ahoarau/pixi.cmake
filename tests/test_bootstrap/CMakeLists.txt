cmake_minimum_required(VERSION 3.19)

include(../../pixi.cmake)

# Bootstrap pixi locally (downloads into .pixi-bin/ next to this file)
pixi_bootstrap(INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/.pixi-bin")

# Verify the variable was set and the binary actually exists
if(NOT DEFINED PIXI_EXECUTABLE OR NOT EXISTS "${PIXI_EXECUTABLE}")
    message(FATAL_ERROR "pixi_bootstrap did not produce a valid PIXI_EXECUTABLE (got: '${PIXI_EXECUTABLE}').")
endif()

# Run pixi --version to confirm the binary works
execute_process(
    COMMAND "${PIXI_EXECUTABLE}" --version
    OUTPUT_VARIABLE PIXI_VERSION_OUTPUT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE PIXI_VERSION_RESULT
)
if(NOT PIXI_VERSION_RESULT EQUAL 0)
    message(FATAL_ERROR "pixi_bootstrap: '${PIXI_EXECUTABLE} --version' failed.")
endif()

message(STATUS "pixi_bootstrap OK — ${PIXI_VERSION_OUTPUT}")

project(TestPixiCMakeBootstrap LANGUAGES NONE)
