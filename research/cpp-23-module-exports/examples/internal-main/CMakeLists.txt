add_executable(main)

target_sources(main
    PRIVATE
        main.cpp
)

target_link_libraries(main PRIVATE core)

target_compile_features(main PRIVATE cxx_std_23)

# Install the executable.
install(TARGETS main
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT Runtime
)
