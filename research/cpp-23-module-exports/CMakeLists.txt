cmake_minimum_required(VERSION 3.30)

project(demo
    VERSION 0.1.0
    DESCRIPTION "A standard C++23 modules project"
    LANGUAGES CXX
)

# ----------------------------------------------------------------------------
# Global project settings
# ----------------------------------------------------------------------------
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Generate compile_commands.json (clangd, IDEs, etc.)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
        Debug Release RelWithDebInfo MinSizeRel)
endif()

# Output binaries into a single bin/ directory at the project root
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# ----------------------------------------------------------------------------
# Install layout (GNU standard):
#   <prefix>/lib/<libname>/...    -- static / shared libraries
#   <prefix>/lib/cmake/<project>  -- CMake package config
# ----------------------------------------------------------------------------
include(GNUInstallDirs)
set(CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_LIBDIR} CACHE PATH "Library directory")
set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR} CACHE PATH "Header directory")

# Allow consumer projects to import installed targets via
# find_package(demo) without needing add_subdirectory().
include(CMakePackageConfigHelpers)

# ----------------------------------------------------------------------------
# Sub-projects
#
#   src/                       -- the `core` library (named module)
#   examples/internal-main/    -- bundled `main` binary (built as part of demo)
#
# `examples/external-main/` is intentionally NOT added: it is a
# stand-alone third-party consumer that only depends on the installed
# `demo` package via find_package().
# ----------------------------------------------------------------------------
add_subdirectory(src)
add_subdirectory(examples/internal-main)

# ----------------------------------------------------------------------------
# Install: top-level exports (run after all subdirs so the package
# config can reference the `core` and `main` targets).
# ----------------------------------------------------------------------------
install(EXPORT demo-targets
    FILE demo-targets.cmake
    NAMESPACE demo::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/demo
    COMPONENT Development
)

# Package configuration: lets consumers do
#   find_package(demo CONFIG REQUIRED)
#   target_link_libraries(myapp PRIVATE demo::core)
include(CMakePackageConfigHelpers)
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/demoConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/demoConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/demo
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/demo-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/demoConfig.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/demo-config-version.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/demo
    COMPONENT Development
)
