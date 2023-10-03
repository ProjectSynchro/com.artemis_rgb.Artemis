
# Artemis Flatpak Repository

## ***This is not an official Artemis repository.***

This is a repository for packaging [Artemis](https://artemis-rgb.com) as a Flatpak, as per Flatpak's best practices.



### What is in here?

Currently, this repository includes:
- [a flatpak manifest](com.artemis_rgb.Artemis.yaml)
- [a metainfo file](com.artemis_rgb.artemis.metainfo.xml)
- [a desktop file](com.artemis_rgb.artemis.desktop)
- json files pointing to nuget sources required for building.

There is a dependency updater script named [`updateSources.sh`](updateSources.sh).  
There is a build script called during building named [`build.sh`](build.sh).

Outlying issues are tracked in the [issue tracker](https://github.com/ProjectSynchro/com.artemis_rgb.Artemis/issues)

### Want to build this?

First clone this repo and change directory into it, then:

```sh
## Install the freedesktop SDK, runtime and the dotnet 6 SDK extension for the freedesktop SDK
flatpak install flathub org.freedesktop.Platform//23.08 org.freedesktop.Sdk//23.08 org.freedesktop.Sdk.Extension.dotnet7//23.08

## Install flatpak-builder for your distro and run this, it will locally install the Flatpak for you.
flatpak-builder --user --install --force-clean build-dir com.artemis_rgb.Artemis.yaml
```

### Using a Wooting? 

Enable the `device=all`` permission in Flatseal, or by typing the following in a console: 

`flatpak override com.artemis_rgb.Artemis --device=all`
