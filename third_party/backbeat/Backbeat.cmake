include_guard(GLOBAL)

if(WIN32)
    set(_backbeat_target "x86_64-pc-windows-msvc")
elseif(APPLE)
    if(CMAKE_OSX_ARCHITECTURES)
        set(_backbeat_arch "${CMAKE_OSX_ARCHITECTURES}")
    else()
        set(_backbeat_arch "${CMAKE_SYSTEM_PROCESSOR}")
    endif()

    if(_backbeat_arch MATCHES "^(arm64|aarch64)$")
        set(_backbeat_target "aarch64-apple-darwin")
    elseif(_backbeat_arch STREQUAL "x86_64")
        set(_backbeat_target "x86_64-apple-darwin")
    else()
        message(FATAL_ERROR "No vendored Backbeat SDK supports macOS architecture: ${_backbeat_arch}")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm64|aarch64)$")
        set(_backbeat_target "aarch64-unknown-linux-gnu")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$")
        set(_backbeat_target "x86_64-unknown-linux-gnu")
    else()
        message(FATAL_ERROR "No vendored Backbeat SDK supports Linux architecture: ${CMAKE_SYSTEM_PROCESSOR}")
    endif()
else()
    message(FATAL_ERROR "No vendored Backbeat SDK supports this platform")
endif()

set(_backbeat_package "backbeat-c-sdk-${_backbeat_target}")

# Temporary private-SDK bootstrap. Place the matching CI ZIP beside this file.
# Replace this local-file lookup with the hosted SDK URL before public release.
set(_backbeat_archive "${CMAKE_CURRENT_LIST_DIR}/${_backbeat_package}.zip")
set(_backbeat_extract_root "${CMAKE_BINARY_DIR}/_deps/${_backbeat_package}")
set(_backbeat_sdk "${_backbeat_extract_root}/${_backbeat_package}")
set(_backbeat_stamp "${_backbeat_extract_root}/.extracted")

if(WIN32)
    set(_backbeat_library "${_backbeat_sdk}/lib/backbeat_c_sdk.lib")
else()
    set(_backbeat_library "${_backbeat_sdk}/lib/libbackbeat_c_sdk.a")
endif()

if(NOT EXISTS "${_backbeat_archive}")
    message(FATAL_ERROR
        "Temporary local Backbeat SDK ZIP is missing: ${_backbeat_archive}")
endif()

if(NOT EXISTS "${_backbeat_stamp}" OR "${_backbeat_archive}" IS_NEWER_THAN "${_backbeat_stamp}")
    file(REMOVE_RECURSE "${_backbeat_extract_root}")
    file(MAKE_DIRECTORY "${_backbeat_extract_root}")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E tar xvf "${_backbeat_archive}"
        WORKING_DIRECTORY "${_backbeat_extract_root}"
        RESULT_VARIABLE _backbeat_extract_result
    )
    if(NOT _backbeat_extract_result EQUAL 0)
        message(FATAL_ERROR "Failed to extract the vendored Backbeat SDK")
    endif()
    file(WRITE "${_backbeat_stamp}" "")
endif()

if(NOT EXISTS "${_backbeat_library}")
    message(FATAL_ERROR "Vendored Backbeat library is missing after extraction")
endif()

set(Backbeat_DIR "${_backbeat_sdk}/lib/cmake/Backbeat")
find_package(Backbeat CONFIG REQUIRED NO_DEFAULT_PATH)

unset(_backbeat_arch)
unset(_backbeat_archive)
unset(_backbeat_extract_root)
unset(_backbeat_extract_result)
unset(_backbeat_library)
unset(_backbeat_package)
unset(_backbeat_sdk)
unset(_backbeat_stamp)
unset(_backbeat_target)
