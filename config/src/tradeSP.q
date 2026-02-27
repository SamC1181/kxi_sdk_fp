//Initialise trade schema
schema:([] sym:`symbol$(); px:`float$(); size:`int$());


//read messages from redpanda kafka broker
collector: .qsp.read.fromKafka[`tradeTopic; "kxi-db-redpanda-1:9092"]; 

//decode json messages
decoder: collector .qsp.decode.json[.qsp.use``decodeEach!11b];

//cast messages to trade table schema
transform: decoder .qsp.transform.schema[schema]; 

//record timestamp on message ingestion
stamp: transform .qsp.map[{[data] update ts:.z.p from data}];

//write records to database
writer: stamp .qsp.v2.write.toDatabase[`trade; .qsp.use (!) . flip ((`target; "kxi-sm:10001");(`overwrite; 0b))];

.qsp.run writer;