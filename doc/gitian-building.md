Gitian building
================

*Setup instructions for a gitian build of Exor using a Debian VM or physical system.*

Gitian is the deterministic build process that is used to build the Exor
Core executables. It provides a way to be reasonably sure that the
executables are really built from the same source code. It also makes sure that
the same, tested dependencies are used and statically built into the executable.

Multiple developers build the source code by following a specific descriptor
("recipe"), cryptographically sign the result, and upload the resulting signature.
These results are compared and only if they match, the build is accepted and provided
for download.

More independent gitian builders are needed, which is why this guide exists.
It is preferred you follow these steps yourself instead of using someone else's
VM image to avoid 'contaminating' the build.

Table of Contents
------------------

- [Create a new VirtualBox VM](#create-a-new-virtualbox-vm)
- [Installing Debian](#installing-debian)
- [Connecting to the VM](#connecting-to-the-vm)
- [Setting up Debian for gitian building](#setting-up-debian-for-gitian-building)
- [MacOS code signing](#macos-code-signing)
- [Build binaries](#build-binaries)
- [Signing externally](#signing-externally)
- [Available Command-Line Options](#available-command-line-options)

Preparing the Gitian builder host
---------------------------------

The first step is to prepare the host environment that will be used to perform the Gitian builds.
This guide explains how to set up the environment, and how to start the builds.

Debian Linux was chosen as the host distribution because it has a lightweight install (in contrast to Ubuntu) and is readily available.
Any kind of virtualization can be used, for example:
- [VirtualBox](https://www.virtualbox.org/), covered by this guide
- [KVM](http://www.linux-kvm.org/page/Main_Page)
- [LXC](https://linuxcontainers.org/), see also [Gitian host docker container](https://github.com/gdm85/tenku/tree/master/docker/gitian-bitcoin-host/README.md).

You can also install on actual hardware instead of using virtualization.

Create a new VirtualBox VM
---------------------------
In the VirtualBox GUI click "New" and choose the following parameters in the wizard:

![](gitian-building/create_vm_new_vm.jpg)

- **Name:** gitian (This is just the name used to reference the virtual machine and can be anything you want)
- **Type:** Linux
- **Version:** Debian (64 bit)
- Push the `Next` button

![](gitian-building/create_vm_memsize.jpg)

- **Memory Size:** at least 1024MB but the more the better. Anything lower than 1024MB will really slow the build down
- Push the `Next` button

![](gitian-building/create_vm_hard_disk.jpg)

- **Hard disk:** Create a virtual hard disk now
- Push the `Create` button
    
![](gitian-building/create_vm_hard_disk_file_type.jpg)

- **Hard disk file type:** VDI (VirtualBox Disk Image) 
- Push the `Next` button

![](gitian-building/create_vm_storage_physical_hard_disk.jpg)
    
- **Storage on physical hard disk:** Dynamically Allocated 
- Push the `Next` button

![](gitian-building/create_vm_file_location_size.jpg)

- **Virtual hard disk file name:** gitian (This is just the name used to reference the virtual machine hard disk file and can be anything you want)
- **Disk size:** At least 40GB. Having more is helpful for storing multiple versions of the wallet builds but is not necessary if you manually remove them after each build
- Push the `Create` button

Get the [Debian 9.5.0 net installer](https://cdimage.debian.org/mirror/cdimage/archive/9.5.0/amd64/iso-cd/debian-9.5.0-amd64-netinst.iso) (a more recent minor version should also work, see also [Debian Network installation](https://www.debian.org/CD/netinst/)).
This DVD image can be validated using a SHA256 hashing tool, for example on
Unixy OSes by entering the following in a terminal:

    echo "1f97a4b8dee7c3def5cd8215ff01b9edef27c901b28fa8b1ef4f022eff7c36c2 debian-9.5.0-amd64-netinst.iso" | sha256sum -c
    # (must return OK)

After creating the VM, we need to configure it. 

- Click the `Settings` button for your `gitian` virtual machine and go to the `Network` tab
- Ensure that `Enable Network Adapter` is checked
- Adapter 1 should be attacked to `NAT`.
- Expand the `Advanced` section and ensure that `Cable Connected` is checked

![](gitian-building/network_settings.jpg)

- Click the `Port Forwarding` button. We want to set up a port through where we can reach the VM to get files in and out
- Create a new rule by clicking the plus icon

![](gitian-building/port_forwarding_rules.jpg)

- Set up the new rule the following way:
  - **Name:** `SSH`
  - **Protocol:** `TCP`
  - **Host IP:** &lt;leave this blank&gt;
  - **Host Port:** `22222`
  - **Guest IP:** &lt;leave this blank&gt;
  - **Guest Port:** `22`

- Click `Ok` twice to save.

Press the `Start` button to start the VM. On the first launch you will be asked for a CD or DVD image. Choose the downloaded iso and press the `Start` button.

![](gitian-building/select_startup_disk.jpg)

Installing Debian
------------------

In this section it will be explained how to install Debian on the newly created VM.

- Choose the non-graphical installer.  We do not need the graphical environment, it will only increase installation time and disk usage.

![](gitian-building/debian_install_boot_menu.jpg)

**Note**: Navigation in the Debian installer: To keep a setting at the default
and proceed, just press `Enter`. To select a different button, press `Tab`.

- Choose locale and keyboard settings (doesn't matter, you can just go with the defaults or select your own information)

![](gitian-building/debian_install_select_language.jpg)
![](gitian-building/debian_install_select_location.jpg)
![](gitian-building/debian_install_configure_keyboard.jpg)

- The VM will detect network settings using DHCP, this should all proceed automatically
- Configure the network: 
  - **Hostname:** `gitian`

![](gitian-building/debian_install_configure_network_hostname.jpg)

  - Leave domain name empty

![](gitian-building/debian_install_configure_network_domain.jpg)

- Choose a root password and enter it twice (remember it for later) 

![](gitian-building/debian_install_root_password.jpg)
![](gitian-building/debian_install_root_password_again.jpg)

- Leave the full name blank

![](gitian-building/debian_install_user_fullname.jpg)

- **Username:** `gitian`

![](gitian-building/debian_install_username.jpg)

- Choose a user password and enter it twice (remember it for later) 

![](gitian-building/debian_install_user_password.jpg)
![](gitian-building/debian_install_user_password_again.jpg)

- The installer will set up the clock using a time server, this process should be automatic
- Set up the clock: choose a time zone (depends on the locale settings that you picked earlier; specifics don't matter)  

![](gitian-building/debian_install_configure_clock.jpg)

- Disk setup
  - **Partitioning method:** Guided - Use the entire disk 
  
![](gitian-building/debian_install_partition_disks.jpg)

  - Select disk to partition: SCSI1 (0,0,0) 

![](gitian-building/debian_install_choose_disk.jpg)

  - **Partitioning scheme:** All files in one partition 
  
![](gitian-building/debian_install_partition_scheme.jpg)

  - Finish partitioning and write changes to disk

![](gitian-building/debian_install_finish_partitioning.jpg)

  - Press `tab` to select `Yes` and press `ENTER`
  
![](gitian-building/debian_install_write_disk_changes.jpg)

  - When it asks if you want to scan another CD or DVD ensure that `No` is selected and press `ENTER`

![](gitian-building/debian_install_scan_additional_cd.jpg)

- The base system will be installed, this will take a minute or so
- Choose a mirror (any will do) 

![](gitian-building/debian_install_choose_mirror_country.jpg)
![](gitian-building/debian_install_choose_mirror.jpg)

- Enter proxy information (unless you are on an intranet, you can leave this empty)

![](gitian-building/debian_install_proxy_settings.jpg)

- Wait a bit while 'Select and install software' runs
- **Participate in the package usage survey:** `No`

![](gitian-building/debian_install_popularity_contest.jpg)

- Choose software to install. We need just the base system
- Make sure only 'SSH server' and 'Standard System Utilities' are checked (Uncheck 'Debian Desktop Environment' and 'Print Server')

![](gitian-building/debian_install_software_selection.jpg)

- **Install the GRUB boot loader to the master boot record:** `Yes`

![](gitian-building/debian_install_install_grub.jpg)

- **Device for boot loader installation:** `/dev/sda`

![](gitian-building/debian_install_grub_boot_loader.jpg)

- **Installation Complete:** `Continue`

![](gitian-building/debian_install_finish_installation.jpg)

- After installation, the VM will reboot and you will have a working Debian VM. Congratulations!

Connecting to the VM
----------------------

After the VM has booted you can connect to it using SSH, and files can be copied from and to the VM using a SFTP utility.
Connect to `localhost`, port `22222` (or the port configured when installing the VM).
On Windows you can use putty[1] and WinSCP[2].

For example to connect as `root` from a Linux command prompt use

    $ ssh root@localhost -p 22222
    The authenticity of host '[localhost]:22222 ([127.0.0.1]:22222)' can't be established.
    ECDSA key fingerprint is 8e:71:f9:5b:62:46:de:44:01:da:fb:5f:34:b5:f2:18.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added '[localhost]:22222' (ECDSA) to the list of known hosts.
    root@localhost's password: (enter root password configured during install)
    Linux gitian 4.9.0-7-amd64 #1 SMP Debian 4.9.110-3+deb9u2 (2018-08-13) x86_64
    root@gitian:~#

Replace `root` with `gitian` to log in as user.

[1] http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html
[2] http://winscp.net/eng/index.php

Setting up Debian for gitian building
--------------------------------------

The steps in this section need only to be performed once.
First log into the debian virtual machine as the `gitian` user.
Setup the gitian building environment by pasting the following lines one at a time
into the terminal:

```bash
wget https://raw.githubusercontent.com/team-exor/exor/master/contrib/gitian-setup.sh
chmod +x gitian-setup.sh
./gitian-setup.sh
```

The `gitian-setup.sh` script will prompt for the *root* password.
Enter the correct password and the installation will continue.
The `gitian-build.sh` script will be installed during this process and the `gitian-setup.sh` script will automatically be removed by the end.
When the script is finished it will reboot the system to apply the changes.
Wait a minute for the system to boot back up and re-login as the user `gitian`.

MacOS code signing
-------------------
In order to sign builds for MacOS, you need to download the free SDK and extract a file. The steps are described [here](https://github.com/team-exor/exor/blob/master/doc/gitian-building-mac-os-sdk.md).

Build binaries
----------------

A build script is provided for building Exor binaries (for Linux, OSX and Windows).
The script uses lxc (setup lxc by following the instructions from
[Setting up Debian for gitian building](#setting-up-debian-for-gitian-building).
The first build of each operating system package takes a long time as it downloads
and builds the dependencies needed for each descriptor.
These dependencies will be cached after a successful build to avoid rebuilding them when possible.

The typical build command is as follows:

`./gitian-build.sh --detach-sign --no-commit -b satoshi 1.0.0`

Replace `satoshi` with your Github name and `1.0.0` is the release tag version you would like to build
(version tag must match 100% with a tag from the project you are building).

**Note**: When sudo asks for a password, enter the password for the user *gitian* not for *root*.

See the [Available Command-Line Options](#available-command-line-options) for more options.

To speed up the build, use `-j 5 -m 5000` as the first arguments, where `5` is the number of CPU's you allocated to the VM plus one, and 5000 is a little bit less than then the MB's of RAM you allocated.

If all went well, this produces a number of (uncommited) `.assert` files in the gitian.sigs repository.

You need to copy these uncommited changes to your host machine, where you can sign them. See [Signing externally](#signing-externally).

At any time you can check the package installation and build progress with

```bash
tail -f var/install.log
tail -f var/build.log
```

Output from `gbuild` will look something like

```bash
    Initialized empty Git repository in /home/debian/gitian-builder/inputs/exor/.git/
    remote: Reusing existing pack: 35606, done.
    remote: Total 35606 (delta 0), reused 0 (delta 0)
    Receiving objects: 100% (35606/35606), 26.52 MiB | 4.28 MiB/s, done.
    Resolving deltas: 100% (25724/25724), done.
    From https://github.com/team-exor/exor
    ... (new tags, new branch etc)
    --- Building for trusty x86_64 ---
    Stopping target if it is up
    Making a new image copy
    stdin: is not a tty
    Starting target
    Checking if target is up
    Preparing build environment
    Updating apt-get repository (log in var/install.log)
    Installing additional packages (log in var/install.log)
    Grabbing package manifest
    stdin: is not a tty
    Creating build script (var/build-script)
    lxc-start: Connection refused - inotify event with no name (mask 32768)
    Running build script (log in var/build.log)
```

Signing externally
-------------------

If you want to do the PGP signing on another device that's also possible.
Copy the resulting `.assert` files in `gitian.sigs` to your signing machine and run these commands:

```bash
    export SIGNER=satoshi
    export VERSION=1.0.0
    gpg --detach-sign ${VERSION}-linux/${SIGNER}/exor-build.assert
    gpg --detach-sign ${VERSION}-win/${SIGNER}/exor-build.assert
    gpg --detach-sign ${VERSION}-osx/${SIGNER}/exor-build.assert
```

This will create the `.sig` files that can be committed together with the `.assert` files to assert your
gitian build.

Available Command-Line Options
-------------------------------

Usage: ./gitian-build.sh [-u|v|b|s|B|o|h|j|m] signer version

- -h or --help

     Displays the help menu

     Usage Example: `./gitian-build.sh -h`
- -u or --url

    Specify the URL of the repository. Default is https://github.com/team-exor/exor
    
    Usage Example: `./gitian-build.sh --detach-sign --no-commit -u https://github.com/newrepo/exor -b satoshi 1.0.0`
- -v or --verify

    Verify the gitian build
    
    Usage Example: `./gitian-build.sh -v satoshi 1.0.0`
- -b or --build

    Do a gitian build
    
    Usage Example: `./gitian-build.sh --detach-sign --no-commit -b satoshi 1.0.0`
- -s or --sign

    Make signed binaries for Windows and Mac OSX
    
    Usage Example: `./gitian-build.sh --detach-sign --no-commit -s satoshi 1.0.0`
- -B or --buildsign

    Build both signed and unsigned binaries
    
    Usage Example: `./gitian-build.sh --detach-sign --no-commit -B satoshi 1.0.0`
- -o or --os

    Specify which Operating Systems the build is for. Default is lwxa. l for linux, w for windows, x for osx, a for aarch64
    
    Usage Example: `./gitian-build.sh --detach-sign --no-commit -o wx -b satoshi 1.0.0`
- -j

    Number of processes to use. Default 2
    
    Usage Example: `./gitian-build.sh --detach-sign --no-commit -j 4 -b satoshi 1.0.0`
- -m

    Memory to allocate in MiB. Default 2000
    
    Usage Example: `./gitian-build.sh --detach-sign --no-commit -m 5000 -b satoshi 1.0.0`
- --detach-sign

    Create the assert file for detached signing. Will not commit anything
    
    Usage Example: `./gitian-build.sh --detach-sign --no-commit -b satoshi 1.0.0`
- --no-commit

    Do not commit anything to git
    
    Usage Example: `./gitian-build.sh --detach-sign --no-commit -b satoshi 1.0.0`
- signer

    GPG signer to sign each build assert file
- version

    Version number, commit, or branch to build
