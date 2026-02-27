#!/bin/sh
# north side of sequencer, pulls from internal client (known topics)
d="`dirname "$0"`"
LD_LIBRARY_PATH="$d/../replicator/clib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH
t="${RT_RAFT_CLUSTER:-${RT_TOPIC_PREFIX}$1}$3:5001";

# Use of replication start point is the default
# Can be disabled by setting $REPLICATOR_NO_START_POINT
if [ -z "$REPLICATOR_NO_START_POINT" -a ! -z "$2" -a "$2" != "--" ]
then
      REPLICATOR_USE_START_POINT=1
fi

if [ "$4" != "0" ]
then
    REPLICATOR_REST_PORT="--rest-server-port $4"
fi

exec "$d/../replicator/clib/pull_client"                                            \
    --logging-level-file ${REPLICATOR_LOGLEVEL_FILE:-NONE}                          \
    --logging-level-console ${REPLICATOR_LOGLEVEL_CONSOLE:-WARN}                    \
    --endpoint "$t"                                                                 \
    --target-dir "$RT_LOG_PATH/$1"                                                  \
    --connect-timeout ${REPLICATOR_CONNECT_TIMEOUT:-300}                            \
    --truncate-archived ${REPLICATOR_TRUNCATE_ARCHIVED:-1}                          \
    --errors-on-stdout ${REPLICATOR_ERRORS_ON_STDOUT:-1}                            \
    --exchange-archived ${REPLICATOR_EXCHANGE_ARCHIVED:-1}                          \
    ${REPLICATOR_USE_START_POINT:+--start-point "$2"}                               \
    --client-name ${REPLICATOR_CLIENT_NAME:-$(hostname)}                            \
    ${REPLICATOR_REST_PORT}                                                         \
    ${REPLICATOR_PAUSE_THRESHOLD:+--pause-threshold "$REPLICATOR_PAUSE_THRESHOLD"}  \
    --renice 5

