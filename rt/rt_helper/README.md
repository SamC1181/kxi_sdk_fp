# kxi-c-sdk

**kxi-c-sdk** is the C SDK to interface with KX insights using the **RT (Reliable Transport)** stream.

## Building

#### Linux

In order to build the `kxi-c-sdk` library, you need `libcurl` and `libssl` development packages. And don't forget to install `cmake`.

```bash
$ apt install cmake libcurl4-openssl-dev libssl-dev
```

Do the below commands in the project directory to build the library, and run tests:

```bash
$ cd clib/rt_helper
$ mkdir build && cd build
$ cmake -DBUILD_TESTS=ON .. && make -j
$ cd .. && ./run_tests.sh
```

This should generate a dynamic library file `librt_helper.so` and an executable `rt_helper_curl` (extensions will vary depending on the platform).

## Running the sample application

There is a csvupload sample application provided with the SDK that demonstrates how the SDK can be used to ingest data into insights.

The sample application can be built using the commands below.

#### Linux

```bash
$ mkdir sandbox && cd sandbox
$ TOK=<gitlab_token>
$ VER=<kxi-c-sdk-version eg. 1.5.0-rc.1>
$ curl  --header "Private-Token:${TOK}" -s  https://gitlab.com/api/v4/projects/38672251/packages/generic/kxi-c-sdk/${VER}/kxi-c-sdk-${VER}.zip -o kxi-c-sdk.zip && unzip kxi-c-sdk.zip && rm kxi-c-sdk.zip
$ curl  --header "Private-Token:${TOK}" -s https://gitlab.com/api/v4/projects/38672251/packages/generic/kxi-c-sdk/${VER}/samples-${VER}.zip -o samples.zip && unzip samples.zip && rm samples.zip
$ cd samples && mkdir build && cd build
$ cmake .. -DKXI_C_SDK_INCLUDE_DIR:PATH=../kxi_c_sdk/include -DKXI_C_SDK_LINK_DIR:PATH=../kxi_c_sdk && cmake --build .
```
#### Windows (cross compile for windows on Linux)

Lauch the cmd shell and create a directory. (This directory should have windows security exclusions to execute binaries)

Create a docker file using notepad with the content below.

```
notepad Dockerfile
```
```
FROM debian
RUN apt update && apt install curl unzip cmake gcc-mingw-w64-x86-64-posix g++-mingw-w64-x86-64-posix -y
```
```
rename Dockerfile.txt Dockerfile
```

Docker build and run the above docker file.
```
docker build -t mingw .
docker run -it --rm -v "%cd%":/a -w /a mingw
```
Now execute the below commands (in the docker container created by the previous command)

```bash
$ TOK=<gitlab_token>
$ VER=<kxi-c-sdk-version eg. 1.5.0-rc.3>
$ curl  --header "Private-Token:${TOK}" -s  https://gitlab.com/api/v4/projects/38672251/packages/generic/kxi-c-sdk/${VER}/kxi-c-sdk-windows-${VER}.zip -o kxi-c-sdk.zip && unzip kxi-c-sdk.zip && rm kxi-c-sdk.zip
$ curl  --header "Private-Token:${TOK}" -s https://gitlab.com/api/v4/projects/38672251/packages/generic/kxi-c-sdk/${VER}/samples-${VER}.zip -o samples.zip && unzip samples.zip && rm samples.zip
$ cd samples && mkdir build && cd build
$ cmake .. -DKXI_C_SDK_INCLUDE_DIR:PATH=../kxi_c_sdk/include -DKXI_C_SDK_LINK_DIR:PATH=../kxi_c_sdk -DCMAKE_TOOLCHAIN_FILE=../kxi_c_sdk/mingw.cmake && cmake --build .
$ cp ../../kxi_c_sdk/*.dll .
$ cp ../../kxi_c_sdk/push_client.exe .
$ cp ../../kxi_c_sdk/rt_helper_curl.exe .
$ exit
```
Now you are back in the windows shell. Run the following commands.
```
cd samples\build
```


### Execute csvupload
```bash
$ ./csvupload
Usage: cvsupload [options]
Options:
  -u str  (req) config URL or local file in URL format,eg. file:///tmp/c.cfg
  -s str  (req) schema (example: "sensorID:int,captureTS:ts,readTS:ts,valFloat:float,qual:byte,alarm:byte")
  -t str  (req) Table
  -r str  (opt) RT directory
  -f int  (opt) config fetch thread sleep between retries (in milliseconds)
  -c int  (opt) config max age (in milliseconds)
  -l int  (opt) local persistence period (in milliseconds)
  -g str  (opt) log level (info/warn/err,off) - info by default
  -m str  (opt) console log level (info/warn/err/off) - err by default
  -w num  (opt) seconds to wait for the connection to establish
  -i str  (opt) input file name, eg. '../sample.csv', if not provided stdin is used
  -o int  (opt) loop, send file many times, -1 for infinite loop, defaults to 1
  -z int  (opt) set to 1 to write a single test record, defaults to 0
  -x str  (opt) absolute or relative path of CA cert file, defaults to null. Can be used to overcome "Curl Fetch Error 60"
  -d str  (opt) dedupId identifies publishers (typically to same stream) to be deduped, use this along with the message correlId to deduplicate messages  
```
### Example usage of csvupload
```bash
$ cd sandbox/samples/build
$ url="https://bjoseph.aws-green.kxi-dev.kx.com/informationservice/details/51b145bd3c71d2987885bbcf75cdca71"
$ schema="sensorID:int,captureTS:ts,readTS:ts,valFloat:float,qual:byte,alarm:byte"
$ table="trace"
$ ./csvupload -u $url -s $schema -t $table < ../sample.csv
```
### Quick example for using the C SDK API with a local kdb server
```code
// Start a local q server listening on port 1234 using command 'q -p 1234'
// Create a table using the below q code
// q)trace:([]sensorID:`int$();readTS:`timestamp$();captureTS:`timestamp$();valFloat:`float$();qual:`byte$();alarm:`byte$()) 

#include <rt_helper/kdb/kk.h>
#include <rt_helper/ksvc_direct_c.h>

Schema *schema = ParseSchema("sensorID:int,captureTS:ts,readTS:ts,valFloat:float,qual:byte,alarm:byte");
void *h = ksvc_direct_start("localhost", 1234);
if (!h) {printf("Error\n");exit1}
char csv_record[] = "10,2021.01.01D00:00:09.000000000,2021.01.01D00:00:09.000000000,97,1,0";
K k_record = convert_csv_record_to_k_record(schema, csv_record);
ksvc_direct_insert(h, ks("trace"), k_record);
ksvc_direct_stop(h);
FreeSchemaResources(schema);
```

### Quick example for using the C SDK API with a KX Insights 
```code
// Make sure that insights ingest endpoints (as defined by the configURL) are accessible from your test host.
// Make sure that sdk_sample_assembly is deployed in the KX Insights instance you are running.
// sdk_sample_assembly will have created the sample table named 'trace' in insights

#include <rt_helper/kdb/kk.h>
#include <rt_helper/ksvcrt_c.h>
#include <rt_helper/rt_params.h>

Schema *schema = ParseSchema("sensorID:int,captureTS:ts,readTS:ts,valFloat:float,qual:byte,alarm:byte");
rt1_stream_params params = {.configUrl = "https://{INSIGHTS_HOSTNAME}/informationservice/details/{KC_CLIENT_ID}",
                      .logLevel = "info"};
void *h = ksvcrtc_start(&params); 
if (!h) {printf("Error\n");FreeSchemaResources(schema);exit(1);}                     
char csv_record[] = "10,2021.01.01D00:00:09.000000000,2021.01.01D00:00:09.000000000,97,1,0";
K k_record = convert_csv_record_to_k_record(schema, csv_record);
if (k_record) {
  ksvcrtc_insert(h, ks("trace"), k_record);
} else {
  printf("Bad csv record\n");
}
ksvcrtc_insert(h, ks("trace"), k_record);
ksvcrtc_stop(h);
FreeSchemaResources(schema);
```

### Quick example of deduplicating messages using the C SDK API with a KX Insights 
```code
// Make sure that insights ingest endpoints (as defined by the configURL) are accessible from your test host.
// Make sure that sdk_sample_assembly is deployed in the KX Insights instance you are running.
// sdk_sample_assembly will have created the sample table named 'trace' in insights

#include <rt_helper/kdb/kk.h>
#include <rt_helper/ksvcrt_c.h>
#include <rt_helper/rt_params.h>

Schema *schema = ParseSchema("sensorID:int,captureTS:ts,readTS:ts,valFloat:float,qual:byte,alarm:byte");
rt1_stream_params params = {.configUrl = "https://{INSIGHTS_HOSTNAME}/informationservice/details/{KC_CLIENT_ID}",
                      .logLevel = "info",
                      .dedupId = "testDedupId"};
void *h = ksvcrtc_start(&params); 
if (!h) {printf("Error\n");FreeSchemaResources(schema);exit(1);}                     
char csv_record[][1000] = {"1,2021.01.01D00:00:09.000000000,2021.01.01D00:00:09.000000000,97,1,0",
                           "2,2021.01.01D00:00:10.000000000,2021.01.01D00:00:10.000000000,98,1,0",
                           "3,2021.01.01D00:00:11.000000000,2021.01.01D00:00:11.000000000,99,1,0"};
J correlId = LLONG_MIN+1; // This is a monatonously increasing id used for deduplication, minimum value is LLONG_MIN+1 
for (int i=0;i<3;++i) {
  K k_record = convert_csv_record_to_k_record(schema, csv_record[i]);
  if (k_record) {
    ksvcrtc_insert_dedup(h, ks("trace"), k_record, ++correlId);
  } else {
    printf("Bad csv record\n");
  }
}
ksvcrtc_stop(h);
FreeSchemaResources(schema);
```

# rt_helper.qpk

## Building

```
$ qp pull gitlab.com/kxdev/interop/rt/replicator/replicator.qpk 1.4.0-rc.5
$ qp build
```

## Running a smoke test

```
$ qp run rt_helper
```

```q
q)param:`config_url`path!("http...";"/tmp/rt")
q)param
config_url| "http..."
path      | "/tmp/rt"
q)rep:.rt.p.helper[`push;param]
; start
q)rep
foreign
q)delete rep from `.;
; stop
```

## Latest output position support

It is also supported to query the "latest" output position via RESTProxy for the internal subscribers. The latest means the last postion what the merger merged so the data log regarding to this postion can be found all sequencer nodes output stream.

This feature is supported on both Linux and Windows systems so the `boost_1_82_0_headers` are added to the dependecies and needed for the build.

```
$ qp run rt_helper
```

```q
q)param
config_url   | "file://..."
delete_config| foreign
q)pos:.rt.p.get_latest_pos[param]
q).rt.sub[getenv`RT_STREAM;`latest;callback]
```

## Testing publish/subscribe using kxi-c-sdk and one node RT

Use the rt-c-pub and rt-c-sub helm charts [here](https://gitlab.com/kxdev/interop/kxi-c-sdk/-/tree/main/deploy/helm) to `helm install` rt-c-sub and rt-c-pub in a namespace with one node RT

Shell into the rt-c-pub container and execute:
```bash
root@rt-c-pub:/opt/dev/rt-publisher-cpp-1.6.0-dev.8/samples/build# echo '{"name":"pub_stream","useSslRt":false,"topics":{"insert":"kxi-mystream"},"insert":{"insert":[":kxi-mystream-0:5002"],"query":[]},"query":[]}' > pub_config.json
root@rt-c-pub:/opt/dev/rt-publisher-cpp-1.6.0-dev.8/samples/build# ./csvupload -u "file:///`pwd`/pub_config.json" -s "sensorID:int,captureTS:ts,readTS:ts,valFloat:float,qual:byte,alarm:byte" -t "trace" -i ../sample.csv -o -1
```
Shell into the rt-c-sub container and execute:
```bash
root@rt-c-sub:/opt/dev/rt-publisher-cpp-1.6.0-dev.8/samples/build# echo '{"name":"sub_stream","useSslRt":false,"topics":{"subscribe":"kxi-mystream"},"insert":{"subscribe":[":kxi-mystream-0:5001"],"query":[]},"query":[]}' > sub_config.json
root@rt-c-sub:/opt/dev/rt-publisher-cpp-1.6.0-dev.8/samples/build# ./test_c "file:///`pwd`/sub_config.json" <position>
root@rt-c-sub:/opt/dev/rt-publisher-cpp-1.6.0-dev.8/samples/build# ./test_k "file:///`pwd`/sub_config.json" <position>
root@rt-c-sub:/opt/dev/rt-publisher-cpp-1.6.0-dev.8/samples/build# ./test_kf "file:///`pwd`/sub_config.json" table_name <position>
```
