# alpine-qemu

[![Container Repository on Quay: Alpine Qemu](https://quay.io/repository/mbayreut/alpine-qemu/status "Container Repository on Quay: Alpine Qemu")](https://quay.io/repository/mbayreut/alpine-qemu)

The original version of this container was built with Debian to run **ancient** Intel x86 based operating systems inside an OCI container (docker / podman).

This new Dockerfile implementation based on Alpine now works equally well.

The following OSs have been successfully bootstrapped to virtual hard disks (VHDs) in the QCOW2 format:
- MS-DOS 3.2 (HP branded)
- MS-DOS 3.3
- MS-DOS 5.0 (HP branded)
- MS-DOS 6.2
- MS-DOS 6.22
- DR-DOS 5.0

Besides that the following Windows versions have been installed on the MS-DOS 6.22 QCOW2 image:
- Microsoft Windows 3.0
- Microsoft Windows 3.1
- Microsoft Windows 3.11

Both projects, this one and the sister project called `debian-qemu` are now maintained in parallel.
Alpine gives a smaller container footprint and a newer version of QEMU. Debian is based on the latest
stable release of Debian and therefore typically a few QEMU versions behind Alpine. Both containers work
equally well and of course the QCOW2 files containing the actual OS, can be interchanged between the two.

## Purpose

To allow old applications to run (for nostalgia reasons) and to ensure that old operating system can participate in CI/CD scenarios. Using qemu (which is the current state of the art emulator on Linux platforms), it is possible to encapsulate and automate workloads that run on OSs which date back to the 1980-ies.

Main target for this exercise are of course Microsoft OSs, which by nature are not that easy to containerize.
This is why I simply wrap a container around QEMU. Given that this works successfully for MS-DOS 3.2, I
would conclude that it works as well for all other Microsoft OSs and Windows versions coming after that.

Example files on how the `qemu` is started can be found under `/usr/local/bin` inside the container or
under `srv/usr/local/bin` in the repository.

This also eliminates the need for VirtualBox installations (for me personally). I don't need the VirtualBox UI and I am 
happy using a WSL2 based Linux distro to fire up all my virtualized OSs.

## Concept

- OCI container image based on Alpine Linux
- qemu running inside the container
- some helper tools and scripts

## Build

    podman build .
or

    docker build .

Then tag the resulting image as you like

    podman tag <image hash> alpine-qemu:1.0
or

    docker tag <image hash> alpine-qemu:1.0

## Usage

To prepare your working qemu hard disk image, you need some boot floppy images to bootstrap your environment. Place them in a place that you will then volume mount into the container. To persist the resulting qcow2 image, make sure to mount `/tmp/images` into the container.

Example:

    podman run -it --rm \
    -p 5901:5901 -p 2323:2323 -p 6001:6001 \
    -v /host-machine/some-hdimg-path:/tmp/images \
    -v /host-machine/some-floppy-path:/opt/floppies \
    -v /host-machine/some-path/external-mount:/opt/external-mount \
    quay.io/mbayreut/alpine-qemu:3-2023-04

Some wrapper shell scripts are included. They illustrate how to work with the container. The GUI of the image / the screen is exposed via VNC on display :1 (= port 5901). The qemu monitor port is exposed via telnet on port 2323. Via the qemu monitor, you are able to control the virtual machine running inside the container.

## qemu startup parameters

| qemu option | note                                   |
|-------------|----------------------------------------|
| `-m 4M`       | Memory: 4 MB (Megabytes) are fine for ancient DOS, if you want to be really generous, put 8M |
| `-vnc :1`     | Screen is exposed via VNC on port 5901 |
| `-monitor telnet:0.0.0.0:2323,server,nowait` | QEMU monitor is exposed via telnet on port 2323 |
| `-boot adc`   | Set boot sequence to floppy, cdrom, hard disc |

additional QEMU command line parameters can be found in the example files under `/usr/local/bin`.

Side note: qemu also supports the SPICE protocol which is more modern than VNC. Good viewers are either TigerVNC 
(any other VNC client works as well) or "remote viewer" from the Redhat KVM project. The latter one has a pretty good
tracking of the mouse cursor when used with the SPICE protocol.

## qemu monitor commands needed for bootstrapping

| qemu command | used for                                   |
|-------------|----------------------------------------|
| `change floppy0 <path-to-floppy-img>` | virtually insert or change a floppy |
| `system_reset` | re-boot the VM |
| `eject floppy0` | remove floppy from floppy drive |

As a client for the monitor port, you can use "Putty" with the Telnet protocol or you can install a telnet
client into your WSL Linux Distro and just do `telnet localhost 2323`. This will bring you directly to
the QEMU monitor command line.

### bootstrapping strategy

1. start the container and qemu (e.g. using one of the helper scripts)
2. connect to the screen via VNC
3. insert the first install disk via the qemu monitor port
4. reboot - wait for the install screen to come up
5. follow the install sequence, change and eject floppies as directed by the installer
