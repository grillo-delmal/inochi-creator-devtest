# Inochi Creator DevTest Builds

This is not an official build of inochi-creator. I use this system to check on the latest updates and to test new patches.
Don't expect any warranty or support if you use the generated builds from this repository.
For normal supported usage, please get a supported official version from the [inochi2d website](https://inochi2d.com/#download).

## Installation

You can get the latest builds from the [release section](https://github.com/grillo-delmal/inochi-creator-devtest/releases/tag/nightly).

Linux builds of this repository are also provided through the [Inochi2d Flatpak DevTest](https://github.com/grillo-delmal/inochi2d-flatpak-devtest) repo.

```sh
flatpak remote-add grillo-inochi2d oci+https://grillo-delmal.github.io//inochi2d-flatpak-devtest
flatpak install grillo-inochi2d io.github.grillo_delmal.inochi-creator
```

## Tips

### Local building flatpak version on Linux

```sh
flatpak-builder build-dir io.github.grillo_delmal.inochi-creator.yml --force-clean
```

### Debugging in Linux

You can also install debug symbols.

```sh
flatpak install grillo-inochi2d io.github.grillo_delmal.inochi_creator.Debug
```

And with that you will be able to debug it with gdb as [any other flatpak app](https://docs.flatpak.org/en/latest/debugging.html).

```sh
flatpak run --command=sh --devel io.github.grillo_delmal.inochi-creator
gdb --ex 'r' /app/bin/inochi-creator
```
### Debugging in Windows

Download [WinDbg](http://www.windbg.org/) and the source code from the [release section](https://github.com/grillo-delmal/inochi-creator-devtest/releases/tag/nightly)... you can figure out the rest from there.
