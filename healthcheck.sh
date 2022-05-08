#!/bin/sh

HEALTHCHECK_DIR="/var/run/named"
HEALTHCHECK_STATUS="$HEALTHCHECK_DIR/status"
HEALTHCHECK_RELOAD="$HEALTHCHECK_DIR/reload"
BIND_CONFIG_DIR="/data"
DOCKER_CONFIG_PATH=/etc/bind/docker.config
BIND_CONFIG_PATH="$BIND_CONFIG_DIR/named.conf.zones"
REGEX_DN="([A-Za-z0-9_-]{1,63}\\.)*[A-Za-z0-9_-]{1,63}\\.?"
REGEX_IPV4="[1-9][0-9]{0,2}\\.[1-9][0-9]{0,2}\\.[1-9][0-9]{0,2}\\.[1-9][0-9]{0,2}"
REGEX_LINE="^\w*$REGEX_DN\w+$REGEX_DN\w+$REGEX_DN($|\w*)"
CHANGES="false"

write_zone_begin()
{
_SEARCH=$1
_NAME=$2
_ZONE=$3
_FILE_PATH_TMP=$4
_SERIAL=$(date +%s)

cat << EOF > ${_FILE_PATH_TMP}
\$TTL    7200
${_ZONE}             IN      SOA     ns.${_ZONE} admin.${_ZONE} (
                                        ${_SERIAL}      ; Serial
                                        7200            ; Refresh
                                        3600            ; Retry
                                        604800          ; Expire
                                        7200)           ; NegativeCacheTTL
                        IN      NS      ns.${_ZONE}
EOF
}

write_zone_name()
{
_SEARCH=$1
_NAME=$2
_ZONE=$3
_ADDRESS=$4
_FILE_PATH_NEW=$5

echo "${_NAME}          IN  A   ${_ADDRESS}" >> $_FILE_PATH_NEW
}

exec_line()
{
_SEARCH=$1
_NAME=$2
_ZONE=$3
_FILE_PATH_NEW="$BIND_CONFIG_DIR/${_ZONE}zone.new"
_FILE_PATH_TMP="$BIND_CONFIG_DIR/${_ZONE}zone.tmp"

if [  $_SEARCH =~ $REGEX_IPV4 ]; then 
    _ADDRESS=$_SEARCH
else
    _ADDRESS=$(dig $_SEARCH +short)
fi

if [ "ADDRESS$_ADDRESS" == "ADDRESS" ]; then 
    _ADDRESS="127.0.0.1"
fi

if [ ! -f $_FILE_PATH_TMP ]; then
    write_zone_begin $_SEARCH $_NAME $_ZONE $_FILE_PATH_TMP
fi

write_zone_name $_SEARCH $_NAME $_ZONE $_ADDRESS $_FILE_PATH_NEW
}

exec_config()
{
if [ -f $DOCKER_CONFIG_PATH ]; then
    grep -E "$REGEX_LINE" $DOCKER_CONFIG_PATH | while read _SEARCH _NAME _ZONE; do
        exec_line $_SEARCH $_NAME $_ZONE
    done
fi
}

exec_file()
{
FILE_NAME_NEW=$1
FILE_NAME_TARGET=$2
FILE_NAME_OLD=$3
FILE_NAME_TMP=$4

if ! cmp -s $FILE_NAME_OLD $FILE_NAME_NEW ;then
    CHANGES="true"
    cat $FILE_NAME_TMP $FILE_NAME_NEW > $FILE_NAME_TARGET
fi
}

exec_add_zone()
{
_ZONE_NAME=$1
_ZONE_PATH=$2
cat << EOF >> ${BIND_CONFIG_PATH}.tmp
zone "${_ZONE_NAME}" {
    type master; 
    file "${_ZONE_PATH}";
};
EOF
}

exec_all_files()
{
rm -f  $BIND_CONFIG_PATH.tmp
for FILE_NAME_NEW in $BIND_CONFIG_DIR/*zone.new ; do
    if [ -f $FILE_NAME_NEW ]; then
        FILE_NAME_TARGET=${FILE_NAME_NEW%%.new}
        FILE_NAME_OLD="${FILE_NAME_TARGET}.old"
        FILE_NAME_TMP="${FILE_NAME_TARGET}.tmp"
        ZONE_NAME=$(basename $FILE_NAME_NEW)
        ZONE_NAME=${ZONE_NAME%%.zone.new}
        exec_file $FILE_NAME_NEW $FILE_NAME_TARGET $FILE_NAME_OLD $FILE_NAME_TMP
        exec_add_zone $ZONE_NAME $FILE_NAME_TARGET
    fi
done
rm -f $BIND_CONFIG_DIR/*zone.old
for FILE_NAME_NEW in $BIND_CONFIG_DIR/*zone.new ; do
    if [ -f $FILE_NAME_NEW ]; then
        FILE_NAME_TARGET=${FILE_NAME_NEW%%.new}
        FILE_NAME_OLD="${FILE_NAME_TARGET}.old"
        FILE_NAME_TMP="${FILE_NAME_TARGET}.tmp"
        mv -f $FILE_NAME_NEW $FILE_NAME_OLD
    fi
done
}

#################
rm -f $BIND_CONFIG_DIR/*zone.new
rm -f $BIND_CONFIG_DIR/*zone.tmp
rm -f $BIND_CONFIG_PATH.tmp

exec_config

exec_all_files


if $CHANGES ;then
    echo "Config has changed..."
    mv -f "$BIND_CONFIG_PATH.tmp" $BIND_CONFIG_PATH
    /usr/sbin/rndc reload > "$HEALTHCHECK_RELOAD.out" 2> "$HEALTHCHECK_RELOAD.err"
else 
    echo "No changes in config..."
fi

rm -f $BIND_CONFIG_DIR/*zone.new
rm -f $BIND_CONFIG_DIR/*zone.tmp
rm -f $BIND_CONFIG_PATH.tmp
#################
/usr/sbin/rndc status  > "$HEALTHCHECK_STATUS.out" 2> "$HEALTHCHECK_STATUS.err"
exit $?
#################