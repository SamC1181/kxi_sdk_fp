 generate_rt_config() {
    local NAME=$1
    local TYPE_STRING=$2
    local RT_STREAM=$3
    local PORT=$4

    echo '{"name":"'"$NAME"'","useSslRt":"false","'"$TYPE_STRING"'":{"stream":"'"$RT_STREAM"'","port":"'"$PORT"'"}}'
}
