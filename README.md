# Klaxxify
## (Alpha)

![Screenshot](data/screenshot.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* granite-7
* libadwaita-1.0
* gtk4
* meson
* valac

It's recommended to create a clean build environment. Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `com.github.zenitsudev.klaxxify`

    ninja install
    com.github.zenitsudev.klaxxify
