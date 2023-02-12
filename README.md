
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


