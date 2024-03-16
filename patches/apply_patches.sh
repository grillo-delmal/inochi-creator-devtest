# Apply lib patches
if [ -d "./patches" ]; then 
    pushd patches
    if [ -d "./libs" ]; then
        pushd libs
        if [ ! -z "$(ls -A */ 2> /dev/null)" ]; then 
            for d in * ; do
                if [ -d "$d" ]; then
                    for p in ${d}/*.patch; do 
                        for g in ../../.flatpak-dub/${d}*; do
                            if [ -d "$g" ]; then
                                echo "Patching ${p}"
                                git -C ${g} apply ../../patches/libs/$p
                            fi
                        done
                    done
                fi
            done
        fi
        popd
    fi
    popd
fi

# Apply inochi creator patches
if [ -d "./patches/inochi-creator" ]; then
    for p in ./patches/inochi-creator/*.patch; do
        echo "Patching ${p}"
        git apply $p
    done
fi