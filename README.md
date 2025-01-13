# quick-ros2-install

A script to install ROS2 quickly.

This script depends on curl and sudo. You can install them by running the following command:

```bash
apt install curl sudo
```

Then you can run the following command to install ROS2:

```bash
curl -s https://raw.githubusercontent.com/JafarAbdi/quick-ros2-install/refs/heads/main/install.bash | bash -s DISTRO_NAME
```

If you want to use a snapshot (https://wiki.ros.org/SnapshotRepository), you can pass the sync datestamp as the second argument:

```bash
curl -s https://raw.githubusercontent.com/JafarAbdi/quick-ros2-install/refs/heads/main/install.bash | bash -s DISTRO_NAME DATESTAMP
```

See http://snapshots.ros.org/ for the available datestamps for each distro.
