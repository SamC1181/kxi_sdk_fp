#!/bin/sh
if [ -z ${SERVICE_NAME+x} ]; then
  echo Please specify the SERVICE_NAME environment variable
  exit 1
fi

if [ -z ${TOPIC_NAME+x} ]; then
  echo Please specify the TOPIC_NAME environment variable
  exit 1
fi

if [ -z ${RT_ENDPOINTS+x} ]; then
	echo Please specify the RT_ENDPOINTS environment variable as a comma separated list of rt endpoints \(e.g. RT_ENDPOINTS=\":127.0.0.1:5002,:127.0.0.2:5002,:127.0.0.3:5002\"\)
  exit 1
fi


ENDPOINT_LIST=`echo $RT_ENDPOINTS | sed "s/,/\",\"/g" | sed "s/\(.*\)/\"\1\"/g"`
echo "{\"name\":\"$SERVICE_NAME\",\"useSslRt\":false,\"topics\":{\"insert\":\"$TOPIC_NAME\"},\"insert\":{\"insert\":[$ENDPOINT_LIST]}}"
