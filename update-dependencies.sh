#!/usr/bin/env bash

set -e

source ./scripts/semver.sh

CHECKOUT_TARGET=
NIGHTLY=0
VERIFY_CREATOR=1
PATCH_CREATOR=1
EXT_CREATOR=
YML_CREATOR=
OUTPATH=.

# Parse options
for i in "$@"; do
    case $i in
        -h|--help)
cat <<EOL
Usage: $0 [OPTION]...
Checks a specific version of inochi-creator, calculates dependencies and stores them 
on a file ready to be used by flatpak-builder.
By default it uses the version defined by the commit hash defined in the
./io.github.grillo_delmal.inochi-creator.yml file

    --target=<string>       Checkout a specific hash/tag/branch instead of
                            reading the one defined on the yaml file.
    --yml-creator=<string>  Search creator commit in external file
    --ext-creator=<string>  Search creator commit in external file
    --outpath               Path where to write dep results.
    --nightly               Will checkout the latest commit from all 
                            dependency repositories.
    --skip-patch            Skip patches.
    --force                 Skip verification.
    --help                  Display this help and exit
EOL
            exit 0
            ;;
        -t=*|--target=*)
            CHECKOUT_TARGET="${i#*=}"
            shift # past argument=value
            ;;
        -y=*|--yml-creator=*)
            YML_CREATOR="${i#*=}"
            shift # past argument=value
            ;;
        -e=*|--ext-creator=*)
            EXT_CREATOR="${i#*=}"
            shift # past argument=value
            ;;
        -o=*|--outpath=*)
            OUTPATH="${i#*=}"
            shift # past argument=value
            ;;
        -n|--nightly)
            NIGHTLY=1
            ;;
        -f|--force)
            VERIFY_CREATOR=0
            ;;
        -s|--skip-patch)
            PATCH_CREATOR=0
            ;;
        -*|--*)
            echo "Unknown option $i"
            exit 1
            ;;
        *)
            ;;
    esac
done

# If no outpath and yml, use yml path as output
if [ "${OUTPATH}" == "." ] && ! [ -z ${YML_CREATOR} ]; then
    OUTPATH=$(dirname ${YML_CREATOR})
fi

echo "### Verification Stage"
if [ -z ${CHECKOUT_TARGET} ]; then
    if [ -z ${EXT_CREATOR} ] && [ -z ${YML_CREATOR} ]; then
        CHECKOUT_TARGET=$(python3 ./scripts/find-creator-hash.py ./io.github.grillo_delmal.inochi-creator.yml)
    elif [ -z ${EXT_CREATOR} ]; then
        CHECKOUT_TARGET=$(python3 ./scripts/find-creator-hash.py ${YML_CREATOR})
    else
        CHECKOUT_TARGET=$(python3 ./scripts/find-creator-hash.py ${EXT_CREATOR} ext)
    fi
fi

# Verify that we are not repeating work 
if [ "${NIGHTLY}" == "0" ] && [ "${VERIFY_CREATOR}" == "1" ]; then
    if [ -f "${OUTPATH}/.dep_target" ]; then
        LAST_PROC=$(cat ${OUTPATH}/.dep_target)
        if [ "$CHECKOUT_TARGET" == "$LAST_PROC" ]; then
            echo "Dependencies already processed for current commit."
            exit 1
        fi
    fi
fi

echo "### Download Stage"

mkdir -p dep.build

# Delete the old working directory
find ./dep.build -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

pushd dep.build

# Download inochi-creator
git clone https://github.com/Inochi2D/inochi-creator.git
git -C ./inochi-creator/ checkout $CHECKOUT_TARGET 2>/dev/null

# Download deps
mkdir -p ./deps
pushd deps
git clone https://github.com/Inochi2D/inochi2d.git
git clone https://github.com/Inochi2D/dportals.git
git clone https://github.com/Inochi2D/facetrack-d.git
git clone https://github.com/Inochi2D/fghj.git
git clone https://github.com/KitsunebiGames/i18n.git i18n-d
git clone https://github.com/Inochi2D/i2d-imgui.git
git clone https://github.com/Inochi2D/i2d-opengl.git
git clone https://github.com/Inochi2D/inmath.git
git clone https://github.com/Inochi2D/kra-d.git
git clone https://github.com/Inochi2D/numem.git
git clone https://github.com/Inochi2D/psd-d.git
git clone https://github.com/Inochi2D/vmc-d.git

# Fixme Use v0_8 branch until v9 is usable
git -C ./inochi2d checkout cae57b6f
git -C ./numem checkout v0.25.0-beta1

# Download gitver and semver
git clone https://github.com/Inochi2D/gitver.git
git clone https://github.com/dcarp/semver.git
git -C ./semver checkout v0.3.4
popd #deps

if [ "${NIGHTLY}" == "0" ]; then
    # Update repos to their state at inochi-creators commit date
    CREATOR_DATE=$(git -C ./inochi-creator/ show -s --format=%ci)
    for d in ./deps/*/ ; do
        DEP_COMMIT=$(git -C $d log --before="$CREATOR_DATE" -n1 --pretty=format:"%H" | head -n1)
        git -C $d checkout $DEP_COMMIT 2>/dev/null
    done
fi

# Fix tag for inochi2d and semver version by searching the required
# version on the respective dub.sdl file
# .This perl regular expresion will match strings that contain
# .`inochi2d`, `~>` and `"`, with anything in between those things
# .it will output only the things between `~>` and `"`
REQ_INOCHI2D_TAG=v$(grep -oP 'inochi2d.*~>\K(.*)(?=")' ./inochi-creator/dub.sdl)
CUR_INOCHI2D_TAG=$(git -C ./deps/inochi2d/ describe --tags \
        `git -C ./deps/inochi2d/ rev-list --tags --max-count=1`)
if [[ "$CUR_INOCHI2D_TAG" != "$REQ_INOCHI2D_TAG" ]]; then
    git -C ./deps/inochi2d/ tag -d "$REQ_INOCHI2D_TAG" || true
    git -C ./deps/inochi2d/ tag "$REQ_INOCHI2D_TAG"
fi
# .Same logic as above, but now using semver instead of inochi2d
REQ_SEMVER_TAG=v$(grep -oP 'semver.*~>\K(.*)(?=")' ./deps/gitver/dub.sdl)
git -C ./deps/semver/ checkout "$REQ_SEMVER_TAG" 2>/dev/null

if [ "${PATCH_CREATOR}" == "1" ]; then
    # Make sure to apply patches beforehand
    popd
    bash ./scripts/apply_local_patches.sh dep.build/deps dep.build/inochi-creator
    pushd dep.build
fi

echo "### Build Stage"

# Add the dependencies to the inochi creator's local-packages file
# .The version is calculated to semver format using the git tag
# .the commit hash and the commit distance to the tag.
mkdir -p ./inochi-creator/.dub/packages
for d in ./deps/*/ ; do
    python3 ../scripts/write-local-packages.py \
        ./inochi-creator/.dub/packages/local-packages.json \
        ../deps/ \
        $(basename $d) \
        "$(semver $d)"
done

# Download dependencies and generate the dub.selections.json file in the process
pushd inochi-creator
dub describe  \
    --compiler=ldc2 \
    --config=barebones \
    --cache=local \
    >> ../describe.json
popd #inochi-creator

popd #dep.build

echo "### Process Stage"

mv ./dep.build/inochi-creator/dub.selections.json ./dep.build/inochi-creator/dub.selections.json.bak
jq ".versions += {\"semver\": \"$(semver ./dep.build/deps/semver)\", \"gitver\": \"$(semver ./dep.build/deps/gitver)\"}" \
    ./dep.build/inochi-creator/dub.selections.json.bak > ./dep.build/inochi-creator/dub.selections.json

# Generate the dependency file
python3 ./scripts/flatpak-dub-generator.py \
    --output=./dep.build/dub-dependencies.json \
    ./dep.build/inochi-creator/dub.selections.json

# Generate the dub-add-local-sources.json using the generated
# dependency file and adding the correct information to get
# the project libraries.
python3 ./scripts/write-dub-deps.py \
    ./dep.build/dub-dependencies.json \
    ${OUTPATH}/dub-add-local-sources.json \
    ./dep.build/deps
 
if [ "${NIGHTLY}" == "1" ]; then
    rm -f ${OUTPATH}/.dep_target
else
    echo "$CHECKOUT_TARGET" > ${OUTPATH}/.dep_target
fi
