# ----------------------------------------------------------------------------
# core -- the project library (named module `core`)
#
# Module file layout (all in this directory):
#   core.cppm                 # primary interface (re-exports partitions)
#   functions.cppm            # partition: free functions
#   functions-impl.cpp        # partition definitions
#   variables.cppm
#   variables.cpp
#   classes.cppm
#   classes-impl.cpp
#   structs.cppm
#   structs-impl.cpp
#   enums.cppm
#   enums-impl.cpp
#   impl.cpp                  # module-internal helpers
# ----------------------------------------------------------------------------
add_library(core)

# C++23 modules: the primary interface and all partitions form one
# named module. `BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}` is the
# include root used for module scanning.
target_sources(core
    PUBLIC
        FILE_SET CXX_MODULES
        BASE_DIRS
            ${CMAKE_CURRENT_SOURCE_DIR}
        FILES
            # primary interface
            core.cppm
            # partitions
            functions.cppm
            variables.cppm
            classes.cppm
            structs.cppm
            enums.cppm
)

# Module implementation units: both `module core;` and
# `module core;`+`import :xxx;` forms. CMake recognizes them and
# compiles them in the right order against the BMI dependencies.
target_sources(core
    PRIVATE
        impl.cpp
        variables.cpp
        functions-impl.cpp
        classes-impl.cpp
        structs-impl.cpp
        enums-impl.cpp
)

# Public include path (for any conventional headers -- currently
# none, but consumers of the installed package still get this).
target_include_directories(core
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/demo/core>
)

target_compile_features(core PUBLIC cxx_std_23)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------
# install(TARGETS) handles:
#   - the static library archive (.a)
#   - the CXX_MODULES file set (interface .cppm files, listed in
#     target_sources(... FILES ...))
#
# Note: implementation-unit `.cpp` files are NOT installed. They are
# linked into the static library at build time, and consumers use the
# prebuilt library + .cppm interfaces -- they don't need our .cpp
# sources. This keeps `include/` clean (only .cppm files, as
# conceptually `include/` is for public "header-like" content).
install(TARGETS core
    EXPORT demo-targets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}/demo
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/demo
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    FILE_SET CXX_MODULES
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/demo/core
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/demo
)
