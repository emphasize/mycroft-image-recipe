#!/bin/bash
# NEON AI (TM) SOFTWARE, Software Development Kit & Application Framework
# All trademark and other rights reserved by their respective owners
# Copyright 2008-2022 Neongecko.com Inc.
# Contributors: Daniel McKnight, Guy Daniels, Elon Gasper, Richard Leeds,
# Regina Bloomstine, Casimiro Ferreira, Andrii Pernatii, Kirill Hrymailo
# BSD-3 License
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS;  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE,  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

BASE_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${BASE_DIR}" || exit 10
dist=$(grep "^Distributor ID:" <<<"$(lsb_release -a)" | cut -d':' -f 2 | tr -d '[:space:]')

# Copy overlay files
cp -r overlay/* /

if [ "${dist}" == 'Ubuntu' ]; then
    # Install gui base dependencies
    apt update
    apt install -y git-core g++ cmake extra-cmake-modules gettext pkg-config qml-module-qtwebengine pkg-kde-tools \
         qtbase5-dev qtdeclarative5-dev libkf5kio-dev libqt5websockets5-dev libkf5i18n-dev libkf5notifications-dev \
         libkf5plasma-dev libqt5webview5-dev qtmultimedia5-dev gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
         gstreamer1.0-libav qml-module-qtwayland-compositor libqt5multimedia5-plugins qml-module-qtmultimedia plasma-pa xorg \
         qtwayland5 qml-module-qtwebchannel \
         qml-module-qt-labs-folderlistmodel qt5ct qml-module-qtquick-shapes qml-module-qtquick-particles2 \
         qml-module-qtquick-templates2 qml-module-qtquick-xmllistmodel qml-module-qtquick-localstorage \
         qml-module-qmltermwidget qml-module-qttest qml-module-qtlocation qml-module-qtpositioning \
         qml-module-qtgraphicaleffects qml-module-qtqml-models2 kirigami2-dev breeze-icon-theme kdeconnect \
         qml-module-qtquick-virtualkeyboard libinput-tools --no-install-recommends
        # qtvirtualkeyboard
fi
# TODO: Above should be if not debos image
# Themes need kf 5.8x+

# Install embedded-shell
git clone https://github.com/OpenVoiceOS/ovos-shell

# Add customized splash screen
cp -f neon_splashscreen.png ovos-shell/application/qml/background.png
cp -f neon_logo.svg ovos-shell/application/icons/ovos-egg.svg

cd ovos-shell || exit 10
cmake .
bash prefix.sh
make ovos-shell
make install ovos-shell || exit 10
cd "${BASE_DIR}" || exit 10
rm -rf ovos-shell

# Install GUI
git clone https://github.com/mycroftai/mycroft-gui
#bash mycroft-gui/dev_setup.sh
cd mycroft-gui || exit 10
TOP=$( pwd -L )

echo "Building Mycroft GUI"
if [[ ! -d build-testing ]] ; then
  mkdir build-testing
fi
cd build-testing || exit 10
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib -DKDE_INSTALL_USE_QT_SYS_PATHS=ON
make -j${MAKE_THREADS}
make install

# TODO: This can be moved to debos recipe
echo "Installing Lottie-QML"
cd "$TOP" || exit 10
if [[ ! -d lottie-qml ]] ; then
    git clone https://github.com/kbroulik/lottie-qml
    cd lottie-qml || exit 10
    mkdir build
else
    cd lottie-qml || exit 10
    git pull
fi

cd build || exit 10
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib -DKDE_INSTALL_USE_QT_SYS_PATHS=ON
make
make install

cd "${BASE_DIR}" || exit 10
rm -rf mycroft-gui

# Permission overlay files and enable gui service
chmod -R ugo+x /usr/bin
chown -R neon:neon /home/neon
systemctl enable gui-shell

echo "GUI Embedded Shell Configured"
