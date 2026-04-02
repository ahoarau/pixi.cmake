cmake_minimum_required(VERSION 3.20)

include(FetchContent)
FetchContent_Declare(pixi GIT_REPOSITORY https://github.com/ahoarau/pixi.cmake GIT_TAG main)
FetchContent_MakeAvailable(pixi)

pixi_dependencies(
    DEPENDENCIES
        [[
libboost-devel = ">=1.85.0,<2"
eigen = ">=3.4.0"
]]
)

project(MyProject)

find_package(Eigen3 CONFIG REQUIRED)
find_package(Boost REQUIRED)
