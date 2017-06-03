#!/bin/bash
#
# author: @tschifftner
#

# Export path for cronjob
export PATH="/usr/local/bin:/usr/bin:/bin"

# Load configuration
source /etc/duplicity/duplicity.conf

# Define variables
INCLUDE=""
LOGFILE=${LOGFILE:-"/var/log/duplicity/duplicity_$(date +'%Y-%m-%d_%H:%I:%S').log"}
LOCKFILE=/tmp/duplicity-backup.lock

# make sure /var/log/duplicity exists
mkdir -p /var/log/duplicity

# Backup everything
backup () {
    # Check if lockfile exists
    if [ -f $LOCKFILE ]; then echo 'duplicity backup already running'; exit 1; fi

    touch $LOCKFILE;

    # Log result status
    echo "[$(date +'%Y-%m-%d %H:%I:%S')] started" >> /var/log/duplicity.log

    # Build include params
    for CDIR in $INCLUDES; do INCLUDE="$INCLUDE --include ${CDIR}"; done

    # Clean things up
    duplicity remove-older-than 1M --force --extra-clean $SERVER >> $LOGFILE
    duplicity cleanup --force $SERVER >> $LOGFILE

    # Log result status
    echo "[$(date +'%Y-%m-%d %H:%I:%S')] cleanup done" >> /var/log/duplicity.log

    # backup everything except excluded, perform full backup if older than 2 weeks
    duplicity $PARAMS $INCLUDE --full-if-older-than 2W --exclude '**' / $SERVER >> $LOGFILE

    # Log result status
    echo "[$(date +'%Y-%m-%d %H:%I:%S')] finished" >> /var/log/duplicity.log

    # Remove lock file
    rm -f $LOCKFILE
}

# List all files that have been backuped
list() {
    duplicity list-current-files $SERVER
}

# Displays duplicity backups status
status() {
    duplicity collection-status $SERVER
}

# Remove backups older than PERIOD (i.e. 1M, 2W, 4D)
remove() {
    echo "Remove backups oder than $1 in $SERVER"
    duplicity remove-older-than $1 --force --extra-clean $SERVER
}

# Restore backups by date/time
restore() {
    if [ $# = 2 ]; then
       duplicity restore --file-to-restore $1 $SERVER $2
    else
       duplicity restore --file-to-restore $1 --time $2 $SERVER $3
    fi
}

# Show log file
log() {
    less $LOGFILE
}

# run script
if [ `type -t $1`"" == 'function' ]; then
    $1 "${@:2}"
else
    echo "
    duptools - manage duplicity backup

    USAGE:

    duptools backup
    duptools list
    duptools status
    duptools restore file [time] dest
    duptools remove [time]

    [time]
    a) now
    b) 2002-01-25T07:00:00+02:00
    c) D=Days, W=Weeks, M=Months, Y=Years, h=hours, m=minutes, s=seconds

    "
fi

# Protect password and passphrase
unset FTP_PASSWORD
unset PASSPHRASE

exit 0