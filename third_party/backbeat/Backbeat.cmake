include_guard(GLOBAL)

if(TARGET Backbeat::Backbeat)
    return()
endif()

# Prefer a package supplied through Backbeat_DIR or CMAKE_PREFIX_PATH.
find_package(Backbeat CONFIG QUIET)

if(Backbeat_FOUND)
    return()
endif()

set(BACKBEAT_SDK_ROOT "" CACHE PATH
    "Path to an extracted Backbeat C SDK; skips the SDK download when set")

if(BACKBEAT_SDK_ROOT)
    set(_backbeat_sdk "${BACKBEAT_SDK_ROOT}")
else()
    if(WIN32)
        set(_backbeat_target "x86_64-pc-windows-msvc")
        set(_backbeat_release_sha256
            "df49c4e560c9c79face4d6bb426808d6567cdb8d9e4a7fe039af22ce337256f6")
    elseif(APPLE)
        if(CMAKE_OSX_ARCHITECTURES)
            set(_backbeat_arch "${CMAKE_OSX_ARCHITECTURES}")
        else()
            set(_backbeat_arch "${CMAKE_SYSTEM_PROCESSOR}")
        endif()

        if(_backbeat_arch MATCHES "^(arm64|aarch64)$")
            set(_backbeat_target "aarch64-apple-darwin")
            set(_backbeat_release_sha256
                "8c3d18f5c68df9872a66908c0a955da8d2a436c39d0722808e570a0f6d4c0227")
        elseif(_backbeat_arch STREQUAL "x86_64")
            set(_backbeat_target "x86_64-apple-darwin")
            set(_backbeat_release_sha256
                "d6a10432077f277a2b5148ee801e118c144ff72d67f661af97ffdf2ed6279e97")
        else()
            message(FATAL_ERROR "No Backbeat SDK supports macOS architecture: ${_backbeat_arch}")
        endif()
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm64|aarch64)$")
            set(_backbeat_target "aarch64-unknown-linux-gnu")
            set(_backbeat_release_sha256
                "b73898343b9465e963ee34337deaaacf3b035503fb40b19bba5a6cdaeb61a320")
        elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|amd64|AMD64)$")
            set(_backbeat_target "x86_64-unknown-linux-gnu")
            set(_backbeat_release_sha256
                "6cd03691f9e379f5efc6320a36a7a18afafedd149f94c211dccdb34b33654c10")
        else()
            message(FATAL_ERROR "No Backbeat SDK supports Linux architecture: ${CMAKE_SYSTEM_PROCESSOR}")
        endif()
    else()
        message(FATAL_ERROR "No Backbeat SDK supports this platform")
    endif()

    set(_backbeat_package "backbeat-c-sdk-${_backbeat_target}")
    set(_backbeat_release_url
        "https://github.com/zkldi/backbeat/releases/download/v0.5.0/${_backbeat_package}.zip")
    set(_backbeat_download_root "${CMAKE_BINARY_DIR}/_deps/backbeat-downloads")
    set(_backbeat_release_archive
        "${_backbeat_download_root}/${_backbeat_package}-release.zip")
    set(_backbeat_release_extract_root
        "${_backbeat_download_root}/${_backbeat_package}-release")
    set(_backbeat_archive
        "${_backbeat_release_extract_root}/${_backbeat_package}.zip")

    file(MAKE_DIRECTORY "${_backbeat_download_root}")

    if(EXISTS "${_backbeat_release_archive}")
        file(SHA256 "${_backbeat_release_archive}" _backbeat_actual_sha256)
        if(NOT "${_backbeat_actual_sha256}" STREQUAL "${_backbeat_release_sha256}")
            file(REMOVE "${_backbeat_release_archive}")
            file(REMOVE_RECURSE "${_backbeat_release_extract_root}")
        endif()
    endif()

    if(NOT EXISTS "${_backbeat_release_archive}")
        message(STATUS "Downloading Backbeat SDK ${_backbeat_target}")
        file(DOWNLOAD
            "${_backbeat_release_url}"
            "${_backbeat_release_archive}"
            EXPECTED_HASH "SHA256=${_backbeat_release_sha256}"
            TLS_VERIFY ON
            SHOW_PROGRESS
            STATUS _backbeat_download_status
        )
        list(GET _backbeat_download_status 0 _backbeat_download_result)
        if(NOT _backbeat_download_result EQUAL 0)
            list(GET _backbeat_download_status 1 _backbeat_download_error)
            file(REMOVE "${_backbeat_release_archive}")
            message(FATAL_ERROR "Failed to download the Backbeat SDK: ${_backbeat_download_error}")
        endif()
    endif()

    if(NOT EXISTS "${_backbeat_archive}")
        file(REMOVE_RECURSE "${_backbeat_release_extract_root}")
        file(MAKE_DIRECTORY "${_backbeat_release_extract_root}")
        execute_process(
            COMMAND "${CMAKE_COMMAND}" -E tar xvf "${_backbeat_release_archive}"
            WORKING_DIRECTORY "${_backbeat_release_extract_root}"
            RESULT_VARIABLE _backbeat_release_extract_result
        )
        if(NOT _backbeat_release_extract_result EQUAL 0
                OR NOT EXISTS "${_backbeat_archive}")
            file(REMOVE_RECURSE "${_backbeat_release_extract_root}")
            message(FATAL_ERROR "Failed to extract the Backbeat SDK release archive")
        endif()
    endif()

    set(_backbeat_extract_root "${CMAKE_BINARY_DIR}/_deps/${_backbeat_package}")
    set(_backbeat_sdk "${_backbeat_extract_root}/${_backbeat_package}")
    set(_backbeat_stamp "${_backbeat_extract_root}/.extracted")

    if(NOT EXISTS "${_backbeat_stamp}" OR "${_backbeat_archive}" IS_NEWER_THAN "${_backbeat_stamp}")
        file(REMOVE_RECURSE "${_backbeat_extract_root}")
        file(MAKE_DIRECTORY "${_backbeat_extract_root}")
        execute_process(
            COMMAND "${CMAKE_COMMAND}" -E tar xvf "${_backbeat_archive}"
            WORKING_DIRECTORY "${_backbeat_extract_root}"
            RESULT_VARIABLE _backbeat_extract_result
        )
        if(NOT _backbeat_extract_result EQUAL 0)
            file(REMOVE_RECURSE "${_backbeat_extract_root}")
            file(REMOVE_RECURSE "${_backbeat_release_extract_root}")
            message(FATAL_ERROR "Failed to extract the Backbeat SDK")
        endif()
        file(WRITE "${_backbeat_stamp}" "")
    endif()
endif()

if(WIN32)
    set(_backbeat_library "${_backbeat_sdk}/lib/backbeat_c_sdk.lib")
else()
    set(_backbeat_library "${_backbeat_sdk}/lib/libbackbeat_c_sdk.a")
endif()

if(NOT EXISTS "${_backbeat_library}")
    message(FATAL_ERROR "Backbeat library is missing: ${_backbeat_library}")
endif()

set(Backbeat_DIR "${_backbeat_sdk}/lib/cmake/Backbeat")
find_package(Backbeat CONFIG REQUIRED NO_DEFAULT_PATH)

unset(_backbeat_arch)
unset(_backbeat_actual_sha256)
unset(_backbeat_archive)
unset(_backbeat_download_error)
unset(_backbeat_download_result)
unset(_backbeat_download_root)
unset(_backbeat_download_status)
unset(_backbeat_extract_root)
unset(_backbeat_extract_result)
unset(_backbeat_library)
unset(_backbeat_package)
unset(_backbeat_release_archive)
unset(_backbeat_release_extract_result)
unset(_backbeat_release_extract_root)
unset(_backbeat_release_sha256)
unset(_backbeat_release_url)
unset(_backbeat_sdk)
unset(_backbeat_stamp)
unset(_backbeat_target)
