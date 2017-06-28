#!/bin/bash

pkgbin="$(which apt-get)" || pkgbin="$(which yum)" || pkgbin="$(which zypper)"
datestr=$(date +"%Y%m%d%H%M")

GITDIR="${HOME}/git"
WMIIIGIT="https://github.com/baua/wmiii.git"
DOTGIT="https://github.com/baua/dotfiles.git"
ATOMGIT="https://github.com/nima/atomicles.git"

if [ ${#pgkbin[@]} -eq 0 ]; then
    echo "No package manager found."
    exit 1
fi

declare -A packages
packages['apt']="git wmii feh libxft-dev fonts-dejavu-core ttf-dejavu"

echo
echo "Installing necessary packages ... "
echo
case "${pgkbin}" in
    apt)
        sudo apt-get install "${packages[@]}"
        if [ $? -eq 0 ]; then
            echo
            echo " DONE."
            echo
        else
            echo
            echo " FAILED."
            exit 1
        fi
        ;;
    *)
        echo "Unsupported package manager (${pkgbin}).";
        exit 1
esac

echo
echo "Linking dot files  ... "
echo
local filename
local bkpdir="${CWD}/tmp/dotfiles.backup.${datestr}"
for file in "$(ls files)"; do
    filename="files/${file}"
    linkname="${HOME}/${file}"
    if [ -e "${linkname}" ]; then
        mkdir -p "${bkpdir}"
        mv "${linkname}" "${bkpdir}"/
    fi
    ln -sf "${filename}" "${linkname}"
    if [ $? -eq 0 ]; then
        echo "Created ${linkname} -> ${filename}."
    else
        echo "Link creation ${linkname} -> ${filename} failed."
    fi
done



