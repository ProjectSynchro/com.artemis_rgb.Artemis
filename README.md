
# Artemis Flatpak Repository

## ***This is not an official Artemis repository.***

This is a repository for packaging [Artemis](https://artemis-rgb.com) as a Flatpak, as per it's best practices.



### What is in here?

Currently, this repository includes:
- [a flatpak manifest](com.artemis_rgb.Artemis.yaml)
- json files pointing to nuget sources required for building.
- [a metainfo file](com.artemis_rgb.artemis.metainfo.xml)
- [a desktop file](com.artemis_rgb.artemis.desktop)

There is a dependency updater script called [updateSources.sh](updateSources.sh).  
The build script that invokes `dotnet publish` and completes other deployment tasks called [`build.sh`](build.sh) directory.

Outlying issues are tracked in the [issue tracker](https://github.com/ProjectSynchro/com.artemis_rgb.Artemis/issues)


