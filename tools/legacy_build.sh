#
# Copyright (C) 2015 Mu Weiyang <young.mu@aliyun.com>
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranties of
# MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
# PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

#!/bin/bash

# build a whole Android application
# wrapper of android/ndk-build/ant/adb tools

if [[ $# -ne 0 ]] && [[ $# -ne 1 ]] && [[ $# -ne 2 ]]; then
    echo "Usage: ./make <id> <release>"
    echo "example: ./make android-23 1"
    exit -1
fi

############################# prepare args ###########################

targetId=android-23
if [ $# -eq 0 ]; then
    echo "No sdk version provided, use latested: ${targetId}"
    targetId=$(android list target -c -0 | head -n 1)
fi

ln -sf Application.mk.arm ./jni/Application.mk

if [[ $# -eq 1 ]]; then
    if [ "${1}" = "c" ]; then
        # flush
        rm -rf bin/ gen/ libs/ obj/ build.xml local.properties proguard-project.txt  project.properties
        exit 0
    elif [ "${1}" = "x" -o "${1}" = "x86" ]; then
        # choose ABI
        echo "building an x86 package"
        ln -sf Application.mk.x86 ./jni/Application.mk
    else
        # set Sdk version
        targetId=${1}
    fi
fi
ver=release
if [ $# -eq 2 ]; then
    if [ ${2} -eq 1 ]; then
        ver=release
    fi
fi
apkName=apkdemo


############################# build apk ##############################

echo
echo "1. generate build configuration files ..."
android update project -n ${apkName} -p . -t ${targetId}
if [[ $? -ne 0 ]]; then
    echo "gen java failed!"
    exit -1
fi
echo
echo "2. build NDK libraries ..."
if [[ -d ./jni ]]; then
    ndk-build clean
    ndk-build
    if [[ $? -ne 0 ]]; then
        echo "ndk build failed!"
        exit -1
    fi
fi
echo
echo "3. build APK ..."
ant clean
ant ${ver}

############################# install ##################################

echo "4. install APK ..."
echo "----------"
adb devices | grep -w "device" 1> /dev/null
if [[ $? -ne 0 ]]; then
    echo "Error: device NOT found!"
    exit -1
fi
if [[ "${ver}" == "debug" ]]; then
    adb install -r bin/${apkName}-debug.apk
else
    # echo ">>> NOTE: type the passowrd as requested: 122333\n"
    jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -storepass 122333 -keystore ./tools/release.key bin/${apkName}-${ver}-unsigned.apk test
    zipalign -v 4 bin/${apkName}-${ver}-unsigned.apk ${apkName}-signed.apk
    adb install -r ${apkName}-signed.apk
fi
