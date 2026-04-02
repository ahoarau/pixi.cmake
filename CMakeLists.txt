cmake_minimum_required(VERSION 3.20)

project(pixi_cmake VERSION 1.0.0 LANGUAGES NONE)

# Make it compatible with fetchcontent
include(${CMAKE_CURRENT_SOURCE_DIR}/pixi.cmake)

option(PIXI_CMAKE_BUILD_TESTING "Enable integration tests" ${PROJECT_IS_TOP_LEVEL})

if(PIXI_CMAKE_BUILD_TESTING)
    message(STATUS "[pixi.cmake] Building tests")

    include(CTest)
    enable_testing()

    add_subdirectory(tests)
endif()
