# ----------------------------------------------------------------------------
# external-main -- third-party-style consumer for the `demo` package
#
# This is intentionally NOT added to the root CMakeLists.txt. It mimics
# an external downstream project that uses the installed `demo` package:
#
#   1. Install the root project first:
#        cmake --install build --prefix ./install
#
#   2. Then build this project independently:
#        CC=clang CXX=clang++ \
#        cmake -S examples/external-main -B examples/external-main/build -G Ninja
#        cmake --build examples/external-main/build
#
# It only depends on `demo` via find_package(); no add_subdirectory().
# ----------------------------------------------------------------------------
cmake_minimum_required(VERSION 3.30)
project(external-main CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_SCAN_FOR_MODULES ON)

# Clang is required to consume the `core` module (the install was built
# with Clang and contains a clang-style BMI). Fail fast with a clear
# message if a different compiler is selected.
if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND
   NOT CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    message(FATAL_ERROR
        "external-main requires Clang to consume the C++23 modules in "
        "`demo`. Re-run with: CC=clang CXX=clang++ cmake -S examples/external-main -B ... ")
endif()

# Locate the installed `demo` package.
# In real use, this would be set by the user:
#   CC=clang CXX=clang++ \
#   cmake -S examples/external-main -B examples/external-main/build -G Ninja \
#         -DCMAKE_PREFIX_PATH=/path/to/demo/install
# We also default to `<project-root>/install` for convenience.
if(NOT CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../install"
        CACHE PATH "Path to the demo install tree")
endif()

find_package(demo CONFIG REQUIRED)

add_executable(third_party_consumer third_party_consumer.cpp)
target_link_libraries(third_party_consumer PRIVATE demo::core)
target_compile_features(third_party_consumer PRIVATE cxx_std_23)

# Optional: skip install of this test binary (it's a verifier only).
