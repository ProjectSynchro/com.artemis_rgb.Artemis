
# Artemis Flatpak Repository

## ***This is not an official Artemis repository.***

This is a repository for packaging [Artemis](https://artemis-rgb.com) as a Flatpak, as per Flatpak's best practices.


### What is in here?

Currently, this repository includes:
- [a flatpak manifest](com.artemis_rgb.Artemis.yaml)
- [a metainfo file](com.artemis_rgb.artemis.metainfo.xml)
- [a desktop file](com.artemis_rgb.artemis.desktop)
- [an icon file](com.artemis_rgb.artemis.png)
- json files pointing to nuget sources required for building.

There is a dependency updater script named [`generate-sources.sh`](generate-sources.sh).  
There is a local build script named [`local-build.sh`](local-build.sh).

Outlying issues are tracked in the [issue tracker](https://github.com/ProjectSynchro/com.artemis_rgb.Artemis/issues)

### Want to build this?

First clone this repo and change directory into it, then:

### Build the Flatpak locally
1. Clone this repo
2. Install flatpak and flatpak-builder for your distro
3. Run the build script with: `./local-build.sh`
4. Install the test build with: `flatpak install ./com.artemis_rgb.Artemis.flatpak`

### Getting dotnet sources manually
1. Clone this repo
2. Install `git`, and `python` for your distro
3. Run `./generate-sources.sh`
4. Verify the updates and commit the updated `artemis-sources.json` and `artemis-plugins-sources.json` files.

### Using a Wooting? 

Enable the `device=all` permission in Flatseal, or by typing the following in a console: 

`flatpak override com.artemis_rgb.Artemis --device=all`
