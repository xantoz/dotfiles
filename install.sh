#!/usr/bin/env bash

PROGRAM_NAME="$0"
# Ensure we run with the correct current directory
cd "$(dirname $(realpath "$0"))"

#### LOG THINGS ####
echo_err()
{
    >&2 echo "$@"
}

printf_err()
{
    >&2 printf "$@"
}

log_info()
{
    >&2 printf -- "%s\n" "$(tput bold)[INFO] $(tput sgr 0)$@"
}

log_warn()
{
    >&2 printf -- "%s\n" "$(tput bold)$(tput setaf 3)[WARNING] $(tput sgr 0)$(tput setaf 3)$@$(tput sgr 0)"
}

log_err()
{
    >&2 printf -- "%s\n" "$(tput bold)$(tput setaf 1)[ERR] $(tput sgr 0)$(tput setaf 1)$@$(tput sgr 0)"
}

die()
{
    log_err "Fatal error: $@"
    exit 1
}
#### END LOG THINGS ####

#### FS MANIPULATION ####
PARTIAL=''
TROUBLE=''

do_symlink()
{
    from="$(realpath $1)"
    to="$2"

    if [ -e "${to}" ]; then
        log_warn "File '${to}' already exists. Not overwriting"
        TROUBLE=y
        PARTIAL=y
        return 1
    fi

    log_info "Symlinking '${from}' -> '${to}'"
    (set -x; ln -vs "${from}" "${to}")
}

# remove, but only if symlink
rm_symlink()
{
    path="$1"

    if ! [ -L "$path" ]; then
        log_warn "File '${path}' is not a symlink. It was probably not installed by this script. Leaving untouched."
        TROUBLE=y
        PARTIAL=y
        return 1
    fi

    log_info "Removing symlink '${path}'"
    (set -x; rm "${path}")
}
#### END FS MANIPULATION

#### MODULES
MODULES=''

MODULES="${MODULES} screenrc"
install_screenrc()
{
    do_symlink "src/.screenrc" "${HOME}/.screenrc"
}
uninstall_screenrc()
{
    rm_symlink "${HOME}/.screenrc"
}

MODULES="${MODULES} youtube-dl"
install_youtube-dl()
{
    do_symlink "src/youtube-dl" "${HOME}/.config/youtube-dl"
}
uninstall_youtube-dl()
{
    rm_symlink "${HOME}/.config/youtube-dl"
}

MODULES="${MODULES} feh"
install_feh()
{
    do_symlink "src/feh" "${HOME}/.config/feh"
}
uninstall_feh()
{
    rm_symlink "${HOME}/.config/feh"
}

MODULES="${MODULES} zile"
install_zile()
{
    do_symlink "src/.zile" "${HOME}/.zile"
}
uninstall_zile()
{
    rm_symlink "${HOME}/.zile"
}

MODULES="${MODULES} dunst"
install_dunst()
{
    do_symlink "src/dunst" "${HOME}/.config/dunst"
}
uninstall_dunst()
{
    rm_symlink "${HOME}/.config/dunst"
}

MODULES="${MODULES} mako"
install_mako()
{
    do_symlink "src/mako" "${HOME}/.config/mako"
}
uninstall_mako()
{
    rm_symlink "${HOME}/.config/mako"
}

MODULES="${MODULES} waybar"
install_waybar()
{
    do_symlink "src/waybar" "${HOME}/.config/waybar"
}
uninstall_waybar()
{
    rm_symlink "${HOME}/.config/waybar"
}

MODULES="${MODULES} redshift"
install_redshift()
{
    suffix=''
    case "${HOSTNAME}" in
        colgate)      suffix='-colgate' ;;
        usbee-ubuntu) suffix='-usbee' ;;
        *)            suffix=''         ;;
    esac
    do_symlink "src/redshift${suffix}.conf" "${HOME}/.config/redshift.conf"
}
uninstall_redshift()
{
    rm_symlink "${HOME}/.config/redshift.conf"
}

MODULES="${MODULES} kitty"
install_kitty()
{
    do_symlink "src/kitty" "${HOME}/.config/kitty"
}
uninstall_kitty()
{
    rm_symlink "${HOME}/.config/kitty"
}

MODULES="${MODULES} alacritty"
install_alacritty()
{
    do_symlink "src/alacritty" "${HOME}/.config/alacritty"
}
uninstall_alacritty()
{
    rm_symlink "${HOME}/.config/alacritty"
}
#### END MODULES

register_module_installed()
{
    touch installed-modules.log
    grep -Fq "$1" installed-modules.log || printf -- '%s\n' "$1" >> installed-modules.log
}

register_module_uninstalled()
{
    touch installed-modules.log
    sed -i "/^${1}$/d" installed-modules.log
}

install()
{
    for i in "$@"; do
        log_info "Installing '$i' module"
        TROUBLE=''
        install_${i}
        if [ -n "${TROUBLE}" ]; then
            log_err "Trouble installing '$i' module"
        else
            register_module_installed "$i"
        fi
    done

    if [ -n "${PARTIAL}" ]; then
        log_err "Not able to install all files."
    fi
}

uninstall()
{
    for i in "$@"; do
        log_info "Uninstalling '$i' module"
        TROUBLE=''
        uninstall_${i}
        if [ -n "${TROUBLE}" ]; then
            log_err "Trouble uninstalling '$i' module"
        else
            register_module_uninstalled "$i"
        fi
    done

    if [ -n "${PARTIAL}" ]; then
        log_err "Not able to remove all files. Probably there was some files not installed by this script."
    fi
}

usage()
{
    echo_err "$PROGRAM_NAME { install | uninstall } [ MODULENAME ]"
    echo_err ""
    echo_err "Available modules:"
    printf_err -- '  %s\n' ${MODULES}
    exit 2
}

check_variables()
{
    [ -n "${HOME}" ] || die "Environment variable HOME is not set"
    [ -n "${HOSTNAME}" ] || die "Environment variable HOSTNAME is not set"
}

[ $# -ge 1 ] || usage

check_variables

arg="$1"
shift
case "${arg}" in
    install)
        if [ $# -ge 1 ]; then
            install "$@"
        else
            install ${MODULES}
        fi
        ;;
    uninstall)
        if [ $# -ge 1 ]; then
            uninstall "$@"
        else
            if [ -f installed-modules.log ] && [ $(cat installed-modules.log | wc -l) -ge 1 ]; then
                uninstall $(cat installed-modules.log)
            else
                die "
No modules to uninstall (according to installed-modules.log)
(You can force uninstallation by specifying the module name directly)
"
            fi
        fi
        ;;
    *)
        usage
        ;;
esac
