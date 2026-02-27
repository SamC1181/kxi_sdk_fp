#!/bin/sh
# publisher to known (specific) sequencer
d="`dirname "$0"`"
LD_LIBRARY_PATH="$d/../replicator/clib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH
t="${RT_RAFT_CLUSTER:-${RT_TOPIC_PREFIX}$1}$3:5002";

if [ "$4" != "0" ]
then
    REPLICATOR_REST_PORT="--rest-server-port $4"
fi

exec "$d/../replicator/clib/push_client"                            \
    --logging-level-file ${REPLICATOR_LOGLEVEL_FILE:-NONE}          \
    --logging-level-console ${REPLICATOR_LOGLEVEL_CONSOLE:-WARN}    \
    --endpoint "$t"                                                 \
    --server-sub-dir "$2"                                           \
    --source-dir "$RT_LOG_PATH/$2"                                  \
    --connect-timeout ${REPLICATOR_CONNECT_TIMEOUT:-300}            \
    --truncate-archived ${REPLICATOR_TRUNCATE_ARCHIVED:-1}          \
    --errors-on-stdout ${REPLICATOR_ERRORS_ON_STDOUT:-1}            \
    --fw-drain-interval ${REPLICATOR_FW_DRAIN_INTERVAL:-0}          \
    --ignore-prefix .                                               \
    --client-name ${REPLICATOR_CLIENT_NAME:-$(hostname)}            \
    ${REPLICATOR_REST_PORT}                                         \
    --renice 5

