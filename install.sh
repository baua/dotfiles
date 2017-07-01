#!/bin/bash
# Change as needed
GITDIR="${HOME}/git"

pkgbin="$(which apt-get)" || pkgbin="$(which yum)" || pkgbin="$(which zypper)"
pkgmgr="${pkgbin##*/}"
datestr=$(date +"%Y%m%d%H%M")
logfile="/tmp/dotfiles.install.${datestr}"

WMIIIGIT="https://github.com/baua/wmiii.git"
DOTGIT="https://github.com/baua/dotfiles.git"
ATOMGIT="https://github.com/nima/atomicles.git"

echo "Starting install. See ${logfile} for more details."
echo

if [ ${#pkgmgr} -eq 0 ]; then
    echo "No package manager found."
    exit 1
fi

declare -A packages
packages['apt-get']="vim wmii feh libxft-dev fonts-dejavu-core gawk gxmessage ttf-dejavu xbindkeys alsa-utils sed ssh-askpass tmux xtrlock xautolock"

echo -n "Installing necessary packages ... "
case "${pkgmgr}" in
    apt-get)
        bash -c "sudo ${pkgbin} -y install ${packages[@]}"
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
        echo "Unsupported package manager (${pkgmgr}).";
        exit 1
esac


echo "Linking dot files  ... "
declare filename
declare bkpdir="${PWD}/tmp/dotfiles.backup.${datestr}"
for file in files/*; do
    filename="${PWD}/${file}"
    linkname="${HOME}/.${file##*/}"
    if [ -f "${linkname}" ]; then
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

[ ! -d "${HOME}/bin" ]  && mkdir -p "${HOME}/bin"
[ ! -d "${GITDIR}" ]  && mkdir -p "${GITDIR}"
pushd "${GITDIR}"
echo -n "Getting atomicales from github  ... "
[ ! -d "/opt/bin" ] && sudo mkdir -p /opt/bin
if [ ! -d "atomicles" ]; then
    git clone "${ATOMGIT}" > "${logfile}" 2>&1
    if [ $? -eq 0 ]; then
        echo " Done."
        pushd atomicles
        make
        sudo make install
        sudo ln -sf /opt/bin/lock /opt/bin/lck
        popd
    else
        echo " Failed."
        exit 1
    fi
else
    echo "directory atomicles already exists."
fi


echo -n "Getting wmiii from github  ... "
if [ ! -d "wmiii" ]; then
    git clone "${WMIIIGIT}" > "${logfile}" 2>&1
    if [ $? -eq 0 ]; then
        echo " Done."
        if [ -d "${HOME}/.wmii" ]; then
            "${HOME}/.wmii already exists. Relink or remove."
        else
            ln -sf "${PWD}/wmiii" "${HOME}/.wmii"
            if [ $? -eq 0 ]; then
                echo "Created ${HOME}/.wmii -> ${CWD}/wmiii."
                pushd "${HOME}/.wmii"
                make install
                popd
            else
                echo "Link creation ${HOME}/.wmii -> ${CWD}/wmiii failed."
            fi
        fi
    else
        echo " Failed."
        exit 1
    fi
else
    echo "directory wmiii already exists."
fi
echo -n "Create .xbindkeyrc ... "
xbindkeys --defaults > ${HOME}/.xbindkeysrc
echo " Done."

echo "(1) Add the following line into /etc/fstab"
echo "      shm /dev/shm/wmii tmpfs defaults,user,noexec,nodev,nosuid,noauto,noatime,size=512M,nr_inodes=8k,mode=777 0 0"
echo "(2) Add /opt/bin:${HOME}/bin to your PATH variable" 
echo "      export PATH=${HOME}/bin:/opt/bin:${PATH} >> ${HOME}/.bash_profile"

popd
