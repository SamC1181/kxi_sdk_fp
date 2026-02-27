# KXI SDK Final Project
This repository provides an example of a KX Insights SDK application which ingests and stores live messages from a dummy kafka feed and writes to RT database for querying

# Deploy

In order to deploy this application, you can pull this repo and then run the following commands to create the directory structure for your database:

```
# create db directories
mkdir -p data/logs/rt data/db data/sp
# allow for reads and writes to db
chmod -R 777 data
```

You can start the application/pipeline using docker compose
```
# start application
docker compose up -d
# stop application
docker compose down 
```
<img width="1052" height="191" alt="Screenshot 2026-02-27 162836" src="https://github.com/user-attachments/assets/8690511c-91b0-4860-ab36-9ba88822b9b2" />

Check on kafka broker, create the kafka topic and send messages using the following:
```
#broker health check

sudo docker exec -it kxi-db-redpanda-1 rpk cluster info
sudo docker exec -it kxi-db-redpanda-1 rpk topic list

#add trade topic
sudo docker exec -it kxi-db-redpanda-1 rpk topic create tradeTopic -p 1 -r 1

#Send Messages:
sudo docker exec -it kxi-db-redpanda-1 rpk topic produce tradeTopic
# e.g. {"sym":"MSFT","px":120.5,"size":200}
```
<img width="950" height="178" alt="Screenshot 2026-02-27 162814" src="https://github.com/user-attachments/assets/f9b77a57-e9d5-4469-824d-7da77331482a" />

# Stream Processor

In this app, I utilize a stream processor architecture to capture messages published to a kafka broker, decode the messages, transform them to expected schema and map the current timestamp before writing the incoming records to the database. This could be connected to any kafka feed and using KXI SDK's window/map functionality can be analysed and persisted to suit the user's data requirements


# Query

Upon starting this application, you can query the data which has been fed through RT to the database with the following query:

```
last h(`.kxi.getData;enlist[`table]!enlist`trade;`;()!())
```
<img width="586" height="393" alt="Screenshot 2026-02-27 162744" src="https://github.com/user-attachments/assets/ecec4621-d67b-42cb-a2c3-7defeb36cef1" />

