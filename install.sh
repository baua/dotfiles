#!/bin/bash

# Change as needed
GITDIR="${HOME}/git"

pkgbin="$(which apt-get)" || pkgbin="$(which yum)" || pkgbin="$(which zypper)"
datestr=$(date +"%Y%m%d%H%M")
logfile="/tmp/dotfiles.install.${datestr}"

WMIIIGIT="https://github.com/baua/wmiii.git"
DOTGIT="https://github.com/baua/dotfiles.git"
ATOMGIT="https://github.com/nima/atomicles.git"

echo "Starting install. See ${logfile} for more details."
echo

if [ ${#pgkbin[@]} -eq 0 ]; then
    echo "No package manager found."
    exit 1
fi

declare -A packages
packages['apt']="git wmii feh libxft-dev fonts-dejavu-core ttf-dejavu"

echo -n "Installing necessary packages ... "
case "${pgkbin}" in
    apt)
        sudo apt-get install "${packages[@]}"
        if [ $? -eq 0 ]; then
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


echo "Linking dot files  ... "
local filename
local bkpdir="${CWD}/tmp/dotfiles.backup.${datestr}"
for file in files/*; do
    filename="files/${file}"
    linkname="${HOME}/${file}"
    if [ -e "${linkname}" ]; then
        mkdir -p "${bkpdir}"
        mv "${linkname}" "${bkpdir}"/
    fi
    ln -sf "${filename}" "${linkname}" > "${logfile}" 2>&1
    if [ $? -eq 0 ]; then
        echo "Created ${linkname} -> ${filename}."
    else
        echo "Link creation ${linkname} -> ${filename} failed."
    fi
done

pushd "${GITDIR}"
echo "Getting wmiii from github  ... "
git clone "${WMIIIGIT}" > "${logfile}" 2>&1
if [ $? -eq 0 ]; then
    echo " Done."
else
    echo " Failed."
    exit 1
fi
popd
