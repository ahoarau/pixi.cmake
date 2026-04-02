cmake_minimum_required(VERSION 3.20)

include(../../pixi.cmake)

# Only dependencies are specified; CHANNELS and PLATFORMS use defaults.
pixi_dependencies(
    DEPENDENCIES
        [[
libboost-devel = ">=1.85.0,<2"
eigen = ">=3.4.0"
]]
)

project(TestPixiInlineDependenciesDefaults)

find_package(Eigen3 CONFIG REQUIRED)
message(STATUS "Eigen3 version: ${Eigen3_VERSION}")

find_package(Boost 1.74 CONFIG REQUIRED COMPONENTS filesystem)
message(STATUS "Boost version: ${Boost_VERSION}")

add_executable(main ../test_boost/main.cpp)
target_link_libraries(main PRIVATE Boost::filesystem)
