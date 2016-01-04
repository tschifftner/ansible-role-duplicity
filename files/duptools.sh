#!/bin/bash
# Do not let this script run more than once
[ `ps axu | grep -v "grep" | grep --count "duplicity"` -gt 0 ] && exit 1

source /etc/duplicity/duplicity.conf
LIMIT=${LIMIT:-100}

export PASSPHRASE
export FTP_PASSWORD

backup() {

    echo $(date +"%d-%m-%Y") >> $LOGFILE

    INCLUDE=""
    for CDIR in $SOURCE
    do
        TMP=" --include  ${CDIR}"
        INCLUDE=${INCLUDE}${TMP}
    done

    # Clean things up
    duplicity remove-older-than 2M --force --extra-clean $DEST
    duplicity cleanup --force $DEST

    # backup everything except excluded, perform full backup if older than 1 month
    CMD="duplicity $PARAMS $INCLUDE --full-if-older-than 1M --exclude '**' / $DEST >> $LOGFILE"
    echo $CMD
    eval $CMD

    space >> $LOGFILE

    if [ $(space_raw) -lt 10 ]; then
       echo $(space) | mail -s "[$HOSTNAME] WARNING: Backup space full!!!!" $EMAIL
       echo $(space) | mail -s "[$HOSTNAME] WARNING: Backup space full!!!!" $EMERGENCY_EMAIL
    fi

    # save current space in file for monit
    echo $(space) > /var/log/backup.space

    # Send email
    if [ -n "$EMAIL" ]; then
        mail -s "[$HOSTNAME] Backup report" $EMAIL < $LOGFILE
    fi
}

list() {
    duplicity list-current-files $DEST
}
remove() {
    echo "duplicity remove-older-than $1 --force --extra-clean $DEST"
    duplicity remove-older-than $1 --force --extra-clean $DEST
}
restore() {
    if [ $# = 2 ]; then
       duplicity restore --file-to-restore $1 $DEST $2
    else
       duplicity restore --file-to-restore $1 --time $2 $DEST $3
    fi
}

status() {
    duplicity collection-status $DEST
}

space() {
    echo "du" | /usr/bin/lftp -u "$FTP_LOGIN,$FTP_PASSWORD" "$FTP_SERVER" | awk -v LIMIT=$LIMIT '$2=="." {print ((LIMIT*1024*1024)-$1)/1024/1024 " GB backup space remaining"}'
}

space_raw() {
    # returns free space in GB, rounded
    echo "du" | /usr/bin/lftp -u "$FTP_LOGIN,$FTP_PASSWORD" "$FTP_SERVER" | awk -v LIMIT=$LIMIT '$2=="." {printf("%d\n", ((LIMIT*1024*1024)-$1)/1024/1024)}'
}

checkspace() {
    if [ $(space_raw) -lt 10 ]; then
        # failures
        exit 1;
    fi

    # success
    exit 0;
}


# Controller
if [ "$1" = "backup" ]; then
    backup
elif [ "$1" = "list" ]; then
    list
elif [ "$1" = "space" ]; then
    space_raw
elif [ "$1" = "checkspace" ]; then
    checkspace
elif [ "$1" = "remove" ]; then
    remove $2
elif [ "$1" = "restore" ]; then
    if [ $# = 3 ]; then
        restore $2 $3
    else
        restore $2 $3 $4
    fi
elif [ "$1" = "status" ]; then
    status
else
    echo "
    duptools - manage duplicity backup

    USAGE:

    ./duptools.sh backup
    ./duptools.sh list
    ./duptools.sh status
    ./duptools.sh restore file [time] dest
    ./duptools.sh remove [time]
    "
fi

# Protect password and passphrase
unset FTP_PASSWORD
unset PASSPHRASE

exit 0