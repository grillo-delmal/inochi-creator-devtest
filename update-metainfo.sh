#!/usr/bin/env bash

source ./scripts/semver.sh

# Create and update creator metadata if it doesn't exist
[ ! -d "./dep.build/inochi-creator/.git" ] && ./update-creator.sh

VERSION=$(semver ./dep.build/inochi-creator)
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
DATE=$(date -I -u )

sed -i -E \
    "s/<release .*>/<release version=\"$VERSION.$TIMESTAMP\" date=\"$DATE\">/" \
    io.github.grillo_delmal.inochi-creator.metainfo.xml