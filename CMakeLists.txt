cmake_minimum_required(VERSION 3.16)
set(CMAKE_AUTORCC ON)

project(SightReadingApp VERSION 0.1 LANGUAGES CXX)

# C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)



# Find packages
find_package(Qt6 6.9 REQUIRED COMPONENTS Core Gui Quick Qml Concurrent Multimedia)
find_package(Qt6 REQUIRED COMPONENTS Core)

qt_standard_project_setup(REQUIRES 6.9)



set(PROJECT_HEADERS
    src/MicrophoneInput.h
    src/NoteSelector.h
    src/PitchDetector.h
    src/AppSettings.h
    src/AppSettings.cpp
    src/WinStreakModel.h
    src/WinStreakModel.cpp

)

set(PROJECT_SOURCES
    src/main.cpp
    src/NoteSelector.cpp
    src/PitchDetector.cpp


    SightReadingApp-Assets.qrc
    SightReadingApp-UI.qrc
)


qt_add_executable(SightReadingApp
    MANUAL_FINALIZATION
    ${PROJECT_HEADERS}
    ${PROJECT_SOURCES}
)

# Link libraries
if(ANDROID)
    target_link_libraries(SightReadingApp
        PRIVATE
            Qt6::Core
            Qt6::Gui
            Qt6::Qml
            Qt6::Quick
            Qt6::Multimedia
            Qt6::Concurrent
            Qt6::CorePrivate
    )
    set_property(TARGET SightReadingApp APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
        ${CMAKE_CURRENT_SOURCE_DIR}/android)
endif()

target_link_libraries(SightReadingApp
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
        Qt6::Multimedia
        Qt6::Concurrent
        Qt6::CorePrivate
)
# Platform properties
set_target_properties(SightReadingApp PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
)

# Install
include(GNUInstallDirs)
install(TARGETS SightReadingApp
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_finalize_executable(SightReadingApp)
qt_finalize_project()
