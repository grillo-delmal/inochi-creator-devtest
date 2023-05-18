# Inochi Creator Nightly Builds

This is not an official build of inochi-creator, this code here is just used as reference for the official build system.
Don't expect warranty or support in any form if you plan to use this.
For normal supported usage, please use the [official releases](https://github.com/Inochi2D/inochi-creator/releases).

## Installation

Builds of this repository are provided through the [Inochi2d Flatpak DevTest](https://github.com/grillo-delmal/inochi2d-flatpak-devtest) repo.

```sh
flatpak remote-add grillo-inochi2d oci+https://grillo-delmal.github.io//inochi2d-flatpak-devtest
flatpak install grillo-inochi2d io.github.grillo_delmal.inochi-creator
```

## Debugging

You can also install debug symbols.

```sh
flatpak install grillo-inochi2d io.github.grillo_delmal.inochi_creator.Debug
```

And with that you will be able to debug it with gdb as [any other flatpak app](https://docs.flatpak.org/en/latest/debugging.html).

```sh
flatpak run --command=sh --devel io.github.grillo_delmal.inochi-creator
gdb --ex 'r' /app/bin/inochi-creator
```