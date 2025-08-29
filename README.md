> ⚠️ **Notice:**  
> This project has migrated to **[Codeberg](https://codeberg.org/Synchro/com.artemis_rgb.Artemis)**.  

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

There is a dependency updater script named [`generate-sources.py`](generate-sources.py).  
There is a local build script named [`local-build.sh`](local-build.sh).

Outlying issues are tracked in the [issue tracker](https://github.com/ProjectSynchro/com.artemis_rgb.Artemis/issues)

### Want to build this?

First clone this repo and change directory into it, then:

### Build the Flatpak locally
1. Clone this repo
2. Install `flatpak`, `flatpak-builder` and `yq` for your distro
3. Run the build script with: `./local-build.sh`

### Getting dotnet sources manually
1. Clone this repo
2. Install `git`, and `python` for your distro
3. Run `./generate-sources.py`
4. Verify the updates and commit the updated `artemis-sources.json` and `artemis-plugins-sources.json` files.

### Using a Wooting? 

If the keyboard doesn't work, try enabling the `device=all` permission in Flatseal, or by typing the following in a console: 

`flatpak override com.artemis_rgb.Artemis --user --device=all`

Want to use analog input?

Install the analog plugin as according to the section on [this wiki page](https://wiki.artemis-rgb.com/guides/user/devices/wooting)

Allow read access to the following path in Flatseal, or by typing the following in a console:

`flatpak override com.artemis_rgb.Artemis --user --filesystem=/usr/local/share/WootingAnalogPlugins:ro`
