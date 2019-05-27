#!/bin/bash
# Copyright (c) 2016 The Bitcoin Core developers
# Copyright (c) 2019 The NulleX Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

# Configuration settings
projectName="exor"				# The name of the wallet or project
mainSuite="trusty"				# All wallets use the same build model except for AArch64
aarchSuite="xenial"				# The AArch64 wallet uses this model
walletOutputDirectory="exor-binaries"		# The directory where finished wallets will be stored
githubUsername="team-exor"			# The username of the repo for the wallet project. Ie: repo username = devrandom from https://github.com/devrandom/gitian-builder
githubRepo="exor"				# The name of the repo for the wallet project. Ie: repo name = gitian-builder from https://github.com/devrandom/gitian-builder
githubDetachedSigsRepo="exor-detached-sigs"	# The name of the repo for the detached signatures.
osxSDKtarballFilename="MacOSX10.11.sdk.tar.gz"	# The name of the Mac OSX SDK tarball file

# What to do
sign=false
verify=false
build=false

# Systems to build
linux=true
windows=true
osx=true
aarch64=true

# Other Basic variables
SIGNER=
VERSION=
url=https://github.com/${githubUsername}/${githubRepo}
proc=2
mem=2000
osslTarUrl=http://downloads.sourceforge.net/project/osslsigncode/osslsigncode/osslsigncode-1.7.1.tar.gz
osslPatchUrl=https://bitcoincore.org/cfields/osslsigncode-Backports-to-1.7.1.patch
scriptName=$(basename -- "$0")
signProg="gpg --detach-sign"
commitFiles=true

# Force lxc
export USE_LXC=1

# Functions
check_clone_repo() {
	# Ensure repo directory is available
	if [[ ! -d "${1}" ]]
	then
		git clone ${2} ${1}
	fi
}

check_install_suite() {
	# Check if environment is already set up and if not then install it
	if [[ ! -f "base-${1}-amd64" ]]
	then
		echo && echo "Installing ${1} VM" && echo
		bin/make-base-vm --suite ${1} --arch amd64 --lxc
	fi
}

# Help Message
read -d '' usage <<- EOF
Usage: $scriptName [-u|v|b|s|B|o|h|j|m] signer version

Run this script from the directory containing the ${githubRepo}, gitian-builder, gitian.sigs, and ${githubDetachedSigsRepo}.

Arguments:
signer          GPG signer to sign each build assert file
version		Version number, commit, or branch to build

Options:
-u|--url	Specify the URL of the repository. Default is https://github.com/${githubUsername}/${githubRepo}
-v|--verify 	Verify the gitian build
-b|--build	Do a gitian build
-s|--sign	Make signed binaries for Windows and Mac OSX
-B|--buildsign	Build both signed and unsigned binaries
-o|--os		Specify which Operating Systems the build is for. Default is lwxa. l for linux, w for windows, x for osx, a for aarch64
-j		Number of processes to use. Default 2
-m		Memory to allocate in MiB. Default 2000
--detach-sign   Create the assert file for detached signing. Will not commit anything.
--no-commit     Do not commit anything to git
-h|--help	Print this help message
EOF

# Get options and arguments
while :; do
    case $1 in
        # Verify
        -v|--verify)
	    verify=true
            ;;
        # Build
        -b|--build)
	    build=true
            ;;
        # Sign binaries
        -s|--sign)
	    sign=true
            ;;
        # Build then Sign
        -B|--buildsign)
	    sign=true
	    build=true
            ;;
        # Operating Systems
        -o|--os)
	    if [ -n "$2" ]
	    then
		linux=false
		windows=false
		osx=false
		aarch64=false
		if [[ "$2" = *"l"* ]]
		then
		    linux=true
		fi
		if [[ "$2" = *"w"* ]]
		then
		    windows=true
		fi
		if [[ "$2" = *"x"* ]]
		then
		    osx=true
		fi
		if [[ "$2" = *"a"* ]]
		then
		    aarch64=true
		fi
		shift
	    else
		echo 'Error: "--os" requires an argument containing an l (for linux), w (for windows), x (for Mac OSX), or a (for aarch64)\n'
		exit 1
	    fi
	    ;;
	# Help message
	-h|--help)
	    echo "$usage"
	    exit 0
	    ;;
	# Number of Processes
	-j)
	    if [ -n "$2" ]
	    then
		proc=$2
		shift
	    else
		echo 'Error: "-j" requires an argument'
		exit 1
	    fi
	    ;;
	# Memory to allocate
	-m)
	    if [ -n "$2" ]
	    then
		mem=$2
		shift
	    else
		echo 'Error: "-m" requires an argument'
		exit 1
	    fi
	    ;;
	# URL
	-u)
	    if [ -n "$2" ]
	    then
		url=$2
		shift
	    else
		echo 'Error: "-u" requires an argument'
		exit 1
	    fi
	    ;;
        # Detach sign
        --detach-sign)
            signProg="true"
            commitFiles=false
            ;;
        # Commit files
        --no-commit)
            commitFiles=false
            ;;
	*)               # Default case: If no more options then break out of the loop.
             break
    esac
    shift
done

# Get signer
if [[ -n "$1" ]]
then
    SIGNER=$1
    shift
fi

# Get version
if [[ -n "$1" ]]
then
    VERSION=$1
    COMMIT=$VERSION
    shift
fi

# Check that a signer is specified
if [[ $SIGNER == "" ]]
then
    echo "$scriptName: Missing signer."
    echo "Try $scriptName --help for more information"
    exit 1
fi

# Check that a version is specified
if [[ $VERSION == "" ]]
then
    echo "$scriptName: Missing version."
    echo "Try $scriptName --help for more information"
    exit 1
fi

# Display wallet version
echo ${COMMIT}
# Ensure project directory is available
check_clone_repo "${githubRepo}" "https://github.com/${githubUsername}/${githubRepo}.git"
# Set up build
pushd ./${githubRepo}
git fetch
git checkout ${COMMIT}
popd

# Build
if [[ $build = true ]]
then
	# Setup before building wallets
	mkdir -p ./${walletOutputDirectory}/${VERSION}
	check_clone_repo "gitian.sigs" "https://github.com/${githubUsername}/gitian.sigs.git"
	check_clone_repo "${githubDetachedSigsRepo}" "https://github.com/${githubUsername}/${githubDetachedSigsRepo}.git"
	check_clone_repo "gitian-builder" "https://github.com/devrandom/gitian-builder.git"
    pushd ./gitian-builder
	mkdir -p inputs
	echo && echo "Building Dependencies" && echo
	wget -N -P inputs $osslPatchUrl
	wget -N -P inputs $osslTarUrl
	make -C ../${githubRepo}/depends download SOURCES_PATH=`pwd`/cache/common

	# Linux
	if [[ $linux = true ]]
	then
		check_install_suite "${mainSuite}"
        echo && echo "Compiling ${VERSION} Linux" && echo
	    ./bin/gbuild -j ${proc} -m ${mem} --commit ${githubRepo}=${COMMIT} --url ${githubRepo}=${url} ../${githubRepo}/contrib/gitian-descriptors/gitian-linux.yml
	    ./bin/gsign -p $signProg --signer $SIGNER --release ${VERSION}-linux --destination ../gitian.sigs/ ../${githubRepo}/contrib/gitian-descriptors/gitian-linux.yml
	    mv build/out/${projectName}-*.tar.gz build/out/src/${projectName}-*.tar.gz ../${walletOutputDirectory}/${VERSION}
	fi
	# Windows
	if [[ $windows = true ]]
	then
		check_install_suite "${mainSuite}"
	    echo && echo "Compiling ${VERSION} Windows" && echo
	    ./bin/gbuild -j ${proc} -m ${mem} --commit ${githubRepo}=${COMMIT} --url ${githubRepo}=${url} ../${githubRepo}/contrib/gitian-descriptors/gitian-win.yml
	    ./bin/gsign -p $signProg --signer $SIGNER --release ${VERSION}-win-unsigned --destination ../gitian.sigs/ ../${githubRepo}/contrib/gitian-descriptors/gitian-win.yml
	    mv build/out/${projectName}-*-win-unsigned.tar.gz inputs/${projectName}-win-unsigned.tar.gz
	    mv build/out/${projectName}-*.zip build/out/${projectName}-*.exe ../${walletOutputDirectory}/${VERSION}
	fi
	# Mac OSX
	if [[ $osx = true ]]
	then
		# Check for OSX SDK
		if [[ ! -f "./inputs/${osxSDKtarballFilename}" ]]
		then
			# OSX SDK doesn't exist. Give time to upload it via sftp or other method
			read -p "OSX SDK tarball is missing. Please upload ${osxSDKtarballFilename} to the gitian-builder/inputs directory and press [ENTER]" 
		fi

		# Check again for OSX SDK
		if [[ -f "./inputs/${osxSDKtarballFilename}" ]]
		then
			check_install_suite "${mainSuite}"
			echo && echo "Compiling ${VERSION} Mac OSX" && echo
			./bin/gbuild -j ${proc} -m ${mem} --commit ${githubRepo}=${COMMIT} --url ${githubRepo}=${url} ../${githubRepo}/contrib/gitian-descriptors/gitian-osx.yml
			./bin/gsign -p $signProg --signer $SIGNER --release ${VERSION}-osx-unsigned --destination ../gitian.sigs/ ../${githubRepo}/contrib/gitian-descriptors/gitian-osx.yml
			mv build/out/${projectName}-*-osx-unsigned.tar.gz inputs/${githubRepo}-osx-unsigned.tar.gz
			mv build/out/${projectName}-*.tar.gz build/out/${projectName}-*.dmg ../${walletOutputDirectory}/${VERSION}
		else
			echo && echo "Skipping Mac OSX build" && echo
		fi
	fi
	# AArch64
	if [[ $aarch64 = true ]]
	then
		check_install_suite "${aarchSuite}"
	    echo && echo "Compiling ${VERSION} AArch64" && echo
	    ./bin/gbuild -j ${proc} -m ${mem} --commit ${githubRepo}=${COMMIT} --url ${githubRepo}=${url} ../${githubRepo}/contrib/gitian-descriptors/gitian-aarch64.yml
	    ./bin/gsign -p $signProg --signer $SIGNER --release ${VERSION}-aarch64 --destination ../gitian.sigs/ ../${githubRepo}/contrib/gitian-descriptors/gitian-aarch64.yml
	    mv build/out/${projectName}-*.tar.gz build/out/src/${projectName}-*.tar.gz ../${walletOutputDirectory}/${VERSION}
	fi
	popd

	if [[ $commitFiles = true ]]
	then
		# Commit to gitian.sigs repo
		echo && echo "Committing ${VERSION} Unsigned Sigs" && echo
		pushd gitian.sigs
		git add ${VERSION}-linux/${SIGNER}
		git add ${VERSION}-aarch64/${SIGNER}
		git add ${VERSION}-win-unsigned/${SIGNER}
		git add ${VERSION}-osx-unsigned/${SIGNER}
		git commit -a -m "Add ${VERSION} unsigned sigs for ${SIGNER}"
		popd
	fi
fi

# Verify the build
if [[ $verify = true ]]
then
	# Linux
	pushd ./gitian-builder
	echo && echo "Verifying v${VERSION} Linux" && echo
	./bin/gverify -v -d ../gitian.sigs/ -r ${VERSION}-linux ../${githubRepo}/contrib/gitian-descriptors/gitian-linux.yml
	# Windows
	echo &&	echo "Verifying v${VERSION} Windows" && echo
	./bin/gverify -v -d ../gitian.sigs/ -r ${VERSION}-win-unsigned ../${githubRepo}/contrib/gitian-descriptors/gitian-win.yml
	# Mac OSX
	echo && echo "Verifying v${VERSION} Mac OSX" && echo
	./bin/gverify -v -d ../gitian.sigs/ -r ${VERSION}-osx-unsigned ../${githubRepo}/contrib/gitian-descriptors/gitian-osx.yml
	# AArch64
	echo && echo "Verifying v${VERSION} AArch64" && echo
	./bin/gverify -v -d ../gitian.sigs/ -r ${VERSION}-aarch64 ../${githubRepo}/contrib/gitian-descriptors/gitian-aarch64.yml
	# Signed Windows
	echo && echo "Verifying v${VERSION} Signed Windows" && echo
	./bin/gverify -v -d ../gitian.sigs/ -r ${VERSION}-osx-signed ../${githubRepo}/contrib/gitian-descriptors/gitian-osx-signer.yml
	# Signed Mac OSX
	echo && echo "Verifying v${VERSION} Signed Mac OSX" && echo
	./bin/gverify -v -d ../gitian.sigs/ -r ${VERSION}-osx-signed ../${githubRepo}/contrib/gitian-descriptors/gitian-osx-signer.yml
	popd
fi

# Sign binaries
if [[ $sign = true ]]
then
    pushd ./gitian-builder
	# Sign Windows
	if [[ $windows = true ]]
	then
	    echo && echo "Signing ${VERSION} Windows" && echo
	    ./bin/gbuild -i --commit signature=${COMMIT} ../${githubRepo}/contrib/gitian-descriptors/gitian-win-signer.yml
	    ./bin/gsign -p $signProg --signer $SIGNER --release ${VERSION}-win-signed --destination ../gitian.sigs/ ../${githubRepo}/contrib/gitian-descriptors/gitian-win-signer.yml
	    mv build/out/${projectName}-*win64-setup.exe ../${walletOutputDirectory}/${VERSION}
	    mv build/out/${projectName}-*win32-setup.exe ../${walletOutputDirectory}/${VERSION}
	fi
	# Sign Mac OSX
	if [[ $osx = true ]]
	then
	    echo && echo "Signing ${VERSION} Mac OSX" && echo
	    ./bin/gbuild -i --commit signature=${COMMIT} ../${githubRepo}/contrib/gitian-descriptors/gitian-osx-signer.yml
	    ./bin/gsign -p $signProg --signer $SIGNER --release ${VERSION}-osx-signed --destination ../gitian.sigs/ ../${githubRepo}/contrib/gitian-descriptors/gitian-osx-signer.yml
	    mv build/out/${githubRepo}-osx-signed.dmg ../${walletOutputDirectory}/${VERSION}/${projectName}-${VERSION}-osx.dmg
	fi

	if [[ $commitFiles = true ]]
	then
		# Commit Sigs
		echo && echo "Committing ${VERSION} Signed Sigs" && echo
		git add ${VERSION}-win-signed/${SIGNER}
		git add ${VERSION}-osx-signed/${SIGNER}
		git commit -a -m "Add ${VERSION} signed binary sigs for ${SIGNER}"
	fi
	popd
fi
