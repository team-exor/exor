Sample init scripts and service configuration for exord
==========================================================

Sample scripts and configuration files for systemd, Upstart and OpenRC
can be found in the contrib/init folder.

    contrib/init/exord.service:    systemd service unit configuration
    contrib/init/exord.openrc:     OpenRC compatible SysV style init script
    contrib/init/exord.openrcconf: OpenRC conf.d file
    contrib/init/exord.conf:       Upstart service configuration file
    contrib/init/exord.init:       CentOS compatible SysV style init script

1. Service User
---------------------------------

All three startup configurations assume the existence of a "exor" user
and group.  They must be created before attempting to use these scripts.

2. Configuration
---------------------------------

At a bare minimum, exord requires that the rpcpassword setting be set
when running as a daemon.  If the configuration file does not exist or this
setting is not set, exord will shutdown promptly after startup.

This password does not have to be remembered or typed as it is mostly used
as a fixed token that exord and client programs read from the configuration
file, however it is recommended that a strong and secure password be used
as this password is security critical to securing the wallet should the
wallet be enabled.

If exord is run with "-daemon" flag, and no rpcpassword is set, it will
print a randomly generated suitable password to stderr.  You can also
generate one from the shell yourself like this:

bash -c 'tr -dc a-zA-Z0-9 < /dev/urandom | head -c32 && echo'

Once you have a password in hand, set rpcpassword= in /etc/exor/exor.conf

For an example configuration file that describes the configuration settings,
see contrib/debian/examples/exor.conf.

3. Paths
---------------------------------

All three configurations assume several paths that might need to be adjusted.

Binary:              /usr/bin/exord
Configuration file:  /etc/exor/exor.conf
Data directory:      /var/lib/exord
PID file:            /var/run/exord/exord.pid (OpenRC and Upstart)
                     /var/lib/exord/exord.pid (systemd)

The configuration file, PID directory (if applicable) and data directory
should all be owned by the exor user and group.  It is advised for security
reasons to make the configuration file and data directory only readable by the
exor user and group.  Access to exor-cli and other exord rpc clients
can then be controlled by group membership.

4. Installing Service Configuration
-----------------------------------

4a) systemd

Installing this .service file consists on just copying it to
/usr/lib/systemd/system directory, followed by the command
"systemctl daemon-reload" in order to update running systemd configuration.

To test, run "systemctl start exord" and to enable for system startup run
"systemctl enable exord"

4b) OpenRC

Rename exord.openrc to exord and drop it in /etc/init.d.  Double
check ownership and permissions and make it executable.  Test it with
"/etc/init.d/exord start" and configure it to run on startup with
"rc-update add exord"

4c) Upstart (for Debian/Ubuntu based distributions)

Drop exord.conf in /etc/init.  Test by running "service exord start"
it will automatically start on reboot.

NOTE: This script is incompatible with CentOS 5 and Amazon Linux 2014 as they
use old versions of Upstart and do not supply the start-stop-daemon uitility.

4d) CentOS

Copy exord.init to /etc/init.d/exord. Test by running "service exord start".

Using this script, you can adjust the path and flags to the exord program by
setting the EXORD and FLAGS environment variables in the file
/etc/sysconfig/exord. You can also use the DAEMONOPTS environment variable here.

5. Auto-respawn
-----------------------------------

Auto respawning is currently only configured for Upstart and systemd.
Reasonable defaults have been chosen but YMMV.
