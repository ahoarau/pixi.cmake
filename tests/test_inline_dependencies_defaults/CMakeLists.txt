cmake_minimum_required(VERSION 3.20)

include(../../pixi.cmake)

# Only dependencies are specified; CHANNELS and PLATFORMS use defaults.
pixi_dependencies(
    DEPENDENCIES [[
libboost-devel = ">=1.85.0,<2"
cmake = ">=3.29.3,<4"
]]
)

project(TestPixiInlineDependenciesDefaults)

find_package(Boost 1.74 CONFIG REQUIRED COMPONENTS filesystem)
message(STATUS "Found Boost: ${Boost_FOUND}")
message(STATUS "Boost include dirs: ${Boost_INCLUDE_DIRS}")

add_executable(main ../test_boost/main.cpp)
target_link_libraries(main PRIVATE Boost::headers)
