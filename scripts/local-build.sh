#!/usr/bin/env bash

set -e

flatpak-builder --default-branch=localbuild --force-clean --repo=./repo-dir ./build-dir io.github.grillo_delmal.inochi-creator.yml

flatpak build-bundle \
    --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo \
    ./repo-dir \
    inochi-creator.x86_64.flatpak \
    io.github.grillo_delmal.inochi-creator localbuild
flatpak build-bundle \
    --runtime \
    ./repo-dir \
    inochi-creator.x86_64.debug.flatpak \
    io.github.grillo_delmal.inochi_creator.Debug localbuild

# flatpak -y install inochi-creator.x86_64.flatpak
# flatpak -y install inochi-creator.x86_64.debug.flatpak