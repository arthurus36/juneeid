#!/usr/bin/env bash
#
# Dependencies:
#   None
#
# vim: ft=sh

#######################################
# Create bin wrappers
#
# Globals:
#   JUNEST_HOME (RO)         : The JuNest home directory.
# Arguments:
#   force ($1?)              : Create bin wrappers even if the bin file exists.
#                              Defaults to false.
# Returns:
#   None
# Output:
#   None
#######################################
function create_wrappers() {
    local force=${1:-false}
    mkdir -p "${JUNEST_HOME}/usr/bin_wrappers"
    # Arguments inside a variable (i.e. `JUNEST_ARGS`) separated by quotes
    # are not recognized normally unless using `eval`. More info here:
    # https://github.com/fsquillace/junest/issues/262
    # https://github.com/fsquillace/junest/pull/287
    cat <<EOF > "${JUNEST_HOME}/usr/bin/junest_wrapper"
#!/usr/bin/env bash

eval "junest_args_array=(\${JUNEST_ARGS:-ns})"
junest "\${junest_args_array[@]}" -- \$(basename \${0}) "\$@"
EOF
    chmod +x "${JUNEST_HOME}/usr/bin/junest_wrapper"

    cd "${JUNEST_HOME}/usr/bin" || return 1
    for file in *
    do
        [[ -d $file ]] && continue
        # Symlinks outside junest appear as broken even though the are correct
        # within a junest session. The following do not skip broken symlinks:
        [[ -x $file || -L $file ]] || continue
        if [[ -e ${JUNEST_HOME}/usr/bin_wrappers/$file ]] && ! $force
        then
            continue
        fi
        rm -f "${JUNEST_HOME}/usr/bin_wrappers/$file"
        ln -s "../bin/junest_wrapper" "${JUNEST_HOME}/usr/bin_wrappers/$file"
    done

    # Remove wrappers no longer needed
    cd "${JUNEST_HOME}/usr/bin_wrappers" || return 1
    for file in *
    do
        [[ -e ${JUNEST_HOME}/usr/bin/$file || -L ${JUNEST_HOME}/usr/bin/$file ]] || rm -f "$file"
    done

}
