cmake_minimum_required(VERSION 3.20)

# Include the pixi.cmake utility from the parent directory
include(../../pixi.cmake)

# Install dependencies using pixi and configure CMAKE_PREFIX_PATH
# Pixi is downloaded automatically if not found in PATH (pass NO_FETCH_PIXI to disable)
pixi_install_dependencies()

project(TestPixiBoost)

# Find Boost
find_package(Boost 1.74 CONFIG REQUIRED COMPONENTS filesystem)
message(STATUS "Found Boost: ${Boost_FOUND}")
message(STATUS "Boost include dirs: ${Boost_INCLUDE_DIRS}")

# Add the executable
add_executable(main main.cpp)
target_link_libraries(main PRIVATE Boost::headers)
