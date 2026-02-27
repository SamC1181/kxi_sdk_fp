// define schema for trade table
schema:([] sym:`symbol$(); px:`float$(); size:`int$(); ts:`timestamp$());

//read from redpanda
consumer:.sp.read.fromKafka[
  `tradeTopic;
  `bootstrap.servers`group.id!("kxi-db-redpanda-1:9092";"sp-consumer-1")
];

// parse and cast data to kdb table
parsed:consumer .sp.map each {
  (-1!schema) upsert enlist each .j.k x
};

// optional: write to Parquet ---
pq:parsed .sp.write.toParquet["/data/parquet/trades"];

// optional: publish to rt
rt:parsed .sp.write.toPublisher[`tradeRT];

pipeline:pq;
