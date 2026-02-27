# kdb Insights Database

Thank you for downloading the kdb Insights Database. This bundle contains a Docker compose configuration to start and run the kdb Insights Database. Additionally, some samples are included for publishing and querying data from the database.

## Prerequisites

To run this bundle, ensure that you have [Docker](https://www.docker.com/) installed with the [Docker Compose](https://docs.docker.com/compose/install/) extension. Next, login to `portal.dl.kx.com` with your credentials in order to pull the required KX images.

```
docker login portal.dl.kx.com -u <email> -p <bearer token>
```

Finally, before running, ensure to place your kdb license (either `kx.lic`, `kc.lic` or `k4.lic`) into the provided `lic` folder. Your license needs to have the appropriate feature flags for running kdb Insights.

> If you do not have credentials to access the KX Docker registry, you do not have a kdb license, or you are unsure if your license has the required feature flags, please contact [sales@kx.com](mailto:sales@kx.com)

## Quickstart

To start the kdb Insights Database, run the following command.

```bash
docker compose up
```

Running this command starts the kdb Insights Database with a collection of sample schemas included in the `config/assembly.yaml` configuration file.

> Tip: to reset the example, delete the `data` folder to run it again

!!! important "Permission configuration"

    If you are running on Linux based operating system, you may need to create the `data` folder yourself and set the permissions to be readable by the container.

    ```bash
    mkdir -p data/logs/rt data/db
    chmod -R 777 data
    ```

    Try this technique if you encounter any permission denied errors (ex. ``EACCES: `:/opt/data/db/idb: Permission denied``)


## Publish and Query

The [kdb Insights CLI](https://code.kx.com/insights/enterprise/cli/index.html) can be used to publish and query data.
There are examples below where you can publish the content of a csv file, `taxi.csv` to the Insights database. The content of this data is stored in a table on the database called `taxi`.
The schema for this table is defined in `config/assembly.yaml`.

The CLI is also used to query back this data.
Additional examples which use the interfaces to [kdb Insights](https://code.kx.com/insights/microservices/rt/sdks/getting-started-sdks.html) are also included to illustrate how developers can publish data to Insights.

### Pre-requisite

1. To use the _kdb Insights CLI_ you musty first populate a file `~/.insights/cli-config`
```bash
cat ~/.insights/cli-config
[default]
usage = microservices
hostname = http://localhost:8080
```

### Publish
```
export KXI_C_SDK_APP_LOG_PATH=$(pwd)  ## useful for debug logging, defaults to /tmp
kxi publish --mode rt --file-format csv --table taxi --data config/taxi.csv --endpoint :localhost:5002
```

### Query
```
kxi query --sql "SELECT * FROM taxi"
```

### Advanced

There are a number of sample docker compose files provided which can be used to populate your database
These rely on the different kdb Insights interfaces, more information on these can be found [here](https://code.kx.com/insights/microservices/database/)

#### Publish

_Publish data python_
```bash
docker compose -f samples/publish/compose-publish.yaml up
```

_Publish data java_
```bash
docker compose -f samples/publish_java/compose-java-ingest.yaml up
```

_Publish data q_
Ensure the [`rt.qpk`](https://portal.dl.kx.com/assets/raw/rt) has been downloaded and unzipped
```bash
$ cd rt/
$ q startq.q
q)params:(`path`stream`publisher_id`cluster)!("/tmp/rt";"data";"pub1";enlist(":127.0.0.1:5002"))
q)p:.rt.pub params
q)show taxi:("SPPHEEEEEEEES";enlist",")0: hsym`$"../config/taxi.csv"
q)p(`.b; `taxi; update pickup:.z.p,dropoff:.z.p+0D00:15:00.0 from taxi)
```

#### Query

_Query data python_
```bash
docker compose -f samples/query/compose-query.yaml up
```

_Query data REST_
```bash
curl -X POST -H 'Content-Type: application/json' http://localhost:8080/data -d '{"table":"taxi"}'
```

_Query data q_
```q
q)h:hopen 5050  // the SG has a tcp port forwarded locally on this port
q)r:h(`.kxi.getData;enlist[`table]!enlist`taxi;`;()!())
q)@[;1]h(`.kxi.qsql; enlist[`query]!enlist"select vendor,pickup,dropoff from taxi";`;()!())
```

### Metrics

To enable metrics, bring up the following docker compose file after bringing up compose.yaml

_Enable metrics_
```bash
docker compose -f config/compose-metrics.yaml up
```

There will be a Prometheus server with the hostname "promstats" added, which you can connect to a grafana dashboard. Port 9090 is mapped to the Prometheus server, and port 3000 is mapped to grafana.

## Further Reading

For more information about kdb Insights and its associated configuration, see the [kdb Insights documentation](https://code.kx.com/insights/microservices/database/).
