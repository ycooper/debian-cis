#!/bin/bash

# run-shellcheck
#
# CIS Debian Hardening
#

#
# 4.1.14 Ensure changes to system administration scope (sudoers) is collected (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

# shellcheck disable=2034
HARDENING_LEVEL=4
# shellcheck disable=2034
DESCRIPTION="Collect changes to system administration scopre."

AUDIT_PARAMS='-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers'
FILE='/etc/audit/rules.d/audit.rules'

# This function will be called if the script status is on enabled / audit mode
audit() {
    # define custom IFS and save default one
    d_IFS=$IFS
    c_IFS=$'\n'
    IFS=$c_IFS
    for AUDIT_VALUE in $AUDIT_PARAMS; do
        debug "$AUDIT_VALUE should be in file $FILE"
        IFS=$d_IFS
        does_pattern_exist_in_file "$FILE" "$AUDIT_VALUE"
        IFS=$c_IFS
        if [ "$FNRET" != 0 ]; then
            crit "$AUDIT_VALUE is not in file $FILE"
        else
            ok "$AUDIT_VALUE is present in $FILE"
        fi
    done
    IFS=$d_IFS
}

# This function will be called if the script status is on enabled mode
apply() {
    IFS=$'\n'
    for AUDIT_VALUE in $AUDIT_PARAMS; do
        debug "$AUDIT_VALUE should be in file $FILE"
        does_pattern_exist_in_file "$FILE" "$AUDIT_VALUE"
        if [ "$FNRET" != 0 ]; then
            warn "$AUDIT_VALUE is not in file $FILE, adding it"
            add_end_of_file "$FILE" "$AUDIT_VALUE"
            eval "$(pkill -HUP -P 1 auditd)"
        else
            ok "$AUDIT_VALUE is present in $FILE"
        fi
    done
}

# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ -r /etc/default/cis-hardening ]; then
    # shellcheck source=../../debian/default
    . /etc/default/cis-hardening
fi
if [ -z "$CIS_ROOT_DIR" ]; then
    echo "There is no /etc/default/cis-hardening file nor cis-hardening directory in current environment."
    echo "Cannot source CIS_ROOT_DIR variable, aborting."
    exit 128
fi

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r "$CIS_ROOT_DIR"/lib/main.sh ]; then
    # shellcheck source=../../lib/main.sh
    . "$CIS_ROOT_DIR"/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi
