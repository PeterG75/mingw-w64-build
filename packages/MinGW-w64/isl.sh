#!/bin/bash

PKG_NAME="isl"
PKG_VERSION="0.22"
PKG_IDENTIFIER=${PKG_NAME}-${PKG_VERSION}

function pkg_download() {
    local PKG_SRC_FILENAME="${PKG_IDENTIFIER}.tar.xz"
    local PKG_SRC_URL="http://isl.gforge.inria.fr/${PKG_SRC_FILENAME}"
    local PKG_SRC_CHECKSUM="6c8bc56c477affecba9c59e2c9f026967ac8bad01b51bdd07916db40a517b9fa"

    if [[ ${SCRIPT_OPTION_FORCE_UPDATE} == "yes" && -f ${SCRIPT_DOWNLOADS_PATH}/${PKG_SRC_FILENAME} ]]; then
        rm -fv ${SCRIPT_DOWNLOADS_PATH}/${PKG_SRC_FILENAME}
    fi
    if [[ ! -f ${SCRIPT_DOWNLOADS_PATH}/${PKG_SRC_FILENAME} ]]; then
        func_create_directory ${SCRIPT_DOWNLOADS_PATH}
        func_download ${PKG_SRC_URL} ${SCRIPT_DOWNLOADS_PATH}/${PKG_SRC_FILENAME}
    fi

    func_verify sha256sum \
        ${SCRIPT_DOWNLOADS_PATH}/${PKG_SRC_FILENAME} \
        ${PKG_SRC_CHECKSUM}
}

function pkg_extract() {
    local PKG_SRC_FILENAME="${PKG_IDENTIFIER}.tar.xz"
    local PKG_SOURCE_PATH=${SCRIPT_MINGW_W64_SOURCES_PATH}/${SCRIPT_MINGW_W64_IDENTIFIER}/${PKG_IDENTIFIER}
    local PKG_PATCH_PATH=${SCRIPT_MINGW_W64_PATCHES_PATH}/${PKG_NAME}

    if [[ ${SCRIPT_OPTION_FORCE_UPDATE} == "yes" && -d ${PKG_SOURCE_PATH} ]]; then
        rm -rfv ${PKG_SOURCE_PATH}
    fi

    if [[ ! -d ${PKG_SOURCE_PATH} ]]; then
        func_create_directory ${SCRIPT_MINGW_W64_SOURCES_PATH}/${SCRIPT_MINGW_W64_IDENTIFIER}

        func_extract ${SCRIPT_DOWNLOADS_PATH}/${PKG_SRC_FILENAME} ${SCRIPT_MINGW_W64_SOURCES_PATH}/${SCRIPT_MINGW_W64_IDENTIFIER}

        func_enter_directory ${PKG_SOURCE_PATH}
            func_apply_patch -p1 ${PKG_PATCH_PATH}/isl-0.14.1-no-undefined.patch
        func_leave_directory
    fi
}

function pkg_configure() {
    local PKG_BUILD=${SCRIPT_OPTION_BUILD}
    local PKG_HOST=${SCRIPT_OPTION_HOST}
    local PKG_SOURCE_PATH=${SCRIPT_MINGW_W64_SOURCES_PATH}/${SCRIPT_MINGW_W64_IDENTIFIER}/${PKG_IDENTIFIER}
    local PKG_CONFIGURE_PATH=${SCRIPT_MINGW_W64_CONFIGURES_PATH}/${SCRIPT_MINGW_W64_IDENTIFIER}/${PKG_IDENTIFIER}
    local PKG_PREFIX_PATH=${SCRIPT_MINGW_W64_DEPENDENCIES_PATH}/${SCRIPT_MINGW_W64_IDENTIFIER}/${PKG_NAME}

    if [[ ${SCRIPT_OPTION_FORCE_UPDATE} == "yes" && -d ${PKG_CONFIGURE_PATH} ]]; then
        rm -rfv ${PKG_CONFIGURE_PATH}
    fi

    if [[ ! -x ${PKG_CONFIGURE_PATH}/config.status ]]; then
        func_log_message "Configure" MinGW-w64/${SCRIPT_MINGW_W64_IDENTIFIER}/${PKG_IDENTIFIER}

        func_create_directory ${PKG_CONFIGURE_PATH}
        func_create_directory ${PKG_PREFIX_PATH}

        func_enter_directory ${PKG_CONFIGURE_PATH}
            ${PKG_SOURCE_PATH}/configure \
                --build=${PKG_BUILD} \
                --host=${PKG_HOST} \
                --prefix=${PKG_PREFIX_PATH} \
                --with-gmp-prefix=${SCRIPT_MINGW_W64_DEPENDENCIES_PATH}/${SCRIPT_MINGW_W64_IDENTIFIER}/gmp \
                --enable-static \
                --disable-shared
        func_leave_directory
    fi
}

function pkg_build() {
    local PKG_CONFIGURE_PATH=${SCRIPT_MINGW_W64_CONFIGURES_PATH}/${SCRIPT_MINGW_W64_IDENTIFIER}/${PKG_IDENTIFIER}

    func_log_message "Build" MinGW-w64/${SCRIPT_MINGW_W64_IDENTIFIER}/${PKG_IDENTIFIER}

    func_enter_directory ${PKG_CONFIGURE_PATH}
        make -j${SCRIPT_OPTION_JOBS} all
        make -j${SCRIPT_OPTION_JOBS} install-strip
    func_leave_directory
}

function pkg_final() {
    :
}

function pkg_clean_env() {
    unset -f pkg_clean_env
    unset -f pkg_final
    unset -f pkg_build
    unset -f pkg_configure
    unset -f pkg_extract
    unset -f pkg_download
    unset PKG_IDENTIFIER
    unset PKG_VERSION
    unset PKG_NAME
}
