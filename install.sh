#!/bin/bash
# Change as needed
GITDIR="${HOME}/git"
rv="$(lsb_release -d)"
descr="${rv##Description:}"
distro="${descr%% *}"

# look for package manager
if ! pkgbin="$(which apt-get 2>/dev/null)"; then
    if ! pkgbin="$(which dnf 2>/dev/null)"; then
        if ! pkgbin="$(which yum 2>/dev/null)"; then
            pkgbin="$(which zypper 2>/dev/null)"
        fi
    fi
fi
pkgmgr="${pkgbin##*/}"
if [ ${#pkgbin[@]} -eq 0 ]; then
    echo "No package manager found."
    exit 1
fi

datestr=$(date +"%Y%m%d%H%M")
logfile="/tmp/dotfiles.install.${datestr}"

WMIIIGIT="https://github.com/baua/wmiii.git"
DOTGIT="https://github.com/baua/dotfiles.git"
ATOMGIT="https://github.com/nima/atomicles.git"
BASHOGIT="https://github.com/nima/bashophilia.git"

echo "Starting install. See ${logfile} for more details."
echo

if [ ${#pkgmgr} -eq 0 ]; then
    echo "No package manager found."
    exit 1
fi

declare -A packages
packages['apt-get']="acpi alsa-utils convert feh htop libxft-dev fonts-dejavu-core gawk gxmessage libatasmart-bin ttf-dejavu xbindkeys sed ssh-askpass tmux vim wmii wpasupplicant xautolock xclip xinit xsel xterm xtrlock"
packages['yum']="acpi alsa-utils ImageMagick feh htop libXft-devel dejavu-fonts-common gawk gxmessage libatasmart xbindkeys sed x11-ssh-askpass tmux vim wmii wpa_supplicant xautolock xclip xinit xsel xterm xlockmore"
packages['dnf']="acpi alsa-utils ImageMagick feh htop libXft-devel dejavu-fonts-common gawk gxmessage libatasmart xbindkeys sed x11-ssh-askpass tmux vim wmii wpa_supplicant xautolock xclip xinit xsel xterm xlockmore"

echo -n "Installing necessary packages ... "
case "${pkgmgr}" in
    apt-get|dnf)
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
declare bkpdir="${HOME}/tmp/dotfiles.backup.${datestr}"
mkdir -p "${bkpdir}"
for file in files/generic/*; do
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
[ -f "${HOME}/.bashrc" ] && source "${HOME}/.bashrc"

if [ "$(find ${bkpdir} -type -d -empty)" == "${bkpdir}" ]; then
    rm -rf "${bkpdir}"
else
    echo "All pre-existing files have been saved under ${bkpdir}."
fi

[ ! -d "${HOME}/bin" ]  && mkdir -p "${HOME}/bin"
[ ! -d "${HOME}/.config" ]  && mkdir -p "${HOME}/.config"
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
        if [ -d "${HOME}/.wmii-hg" ]; then
            "${HOME}/.wmii-hg already exists. Relink or remove."
        else
            ln -sf "${PWD}/wmiii" "${HOME}/.wmii-hg" && ln -sf "${HOME}/.wmii-hg" "${HOME}/.wmii"
            if [ $? -eq 0 ]; then
                echo "Created ${HOME}/.wmii-hg -> ${CWD}/wmiii."
                pushd "${HOME}/.wmii-hg"
                make install
                make installx
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

echo -n "Getting bashophilia from github  ... "
if [ ! -d "bashophilia" ]; then
    git clone "${BASHOGIT}" > "${logfile}" 2>&1
    if [ $? -eq 0 ]; then
        echo " Done."
    else
        echo " Failed."
        exit 1
    fi
else
    echo "directory bashophilia already exists."
fi
ln -sf "${PWD}/bashophilia" "${HOME}/.config/bashophilia"
cp "${PWD}/bashophilia/share/dot.boprc" "${HOME}/.boprc"

echo -n "Create .xbindkeyrc ... "
xbindkeys --defaults > ${HOME}/.xbindkeysrc
echo " Done."

echo "(1) Add the following line into /etc/fstab"
echo "      shm /dev/shm/wmii tmpfs defaults,user,noexec,nodev,nosuid,noauto,noatime,size=1024M,nr_inodes=8k,mode=777 0 0"

popd
