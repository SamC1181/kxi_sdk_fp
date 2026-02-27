# Replicator

Replicate files from a directory on a source node to another directory on a target node.

**NB: Replicator uses binaries which don't currently get translated by qpacker's sobuilder. The replicator qp build therefore uses a `Dockerfile.qp` with the base image set to `rockylinux/rockylinux:8`, so that the binaries can be used in environments not managed by qpacker.**

Replicator can also be built using Alpine, Ubuntu and Windows.


## Building and installing

Clone and build the repo:

```bash
neal@NEWDESK-WIN10:~/Git$ git clone git@gitlab.com:kxdev/cloud/replicator.git
Cloning into 'replicator'...
remote: Enumerating objects: 562, done.
remote: Counting objects: 100% (562/562), done.
remote: Compressing objects: 100% (302/302), done.
remote: Total 562 (delta 294), reused 483 (delta 232), pack-reused 0
Receiving objects: 100% (562/562), 1.27 MiB | 2.47 MiB/s, done.
Resolving deltas: 100% (294/294), done.
neal@NEWDESK-WIN10:~/Git$ cd replicator
neal@NEWDESK-WIN10:~/Git/replicator$ qp build
INFO  | Build   | Dependency [q]
INFO  | Build   | docker build -t qlocker /home/neal/Git/replicator/qpbuild/dep/q
INFO  | Build   | docker run --rm -d --cidfile=/tmp/qpacker-5ylplxrGKh/qp.15647.qlocker.id --env-file /tmp/qpacker-5ylplxrGKh/qp.15647.env.list qlocker:latest
INFO  | Build   | Starting build for application [default]
INFO  | Build   | Building dep [clib] from source
INFO  | Build   | Dependency [so]
INFO  | Main    | (16169-4) Finished.
INFO  | Build   | Building clib
...
```

Local builds are also supported on Linux and Windows using CMake.  The dependencies (in particular gRPC) will need to installed through a package manager (or by following the manual steps in `qpmake.sh`).  For example, using vcpkg on Windows:

```bash
C:\Git\vcpkg>vcpkg list | grep grpc
grpc:x64-windows                                   1.36.4           An RPC library and framework
grpc:x64-windows-static                            1.36.4           An RPC library and framework
C:\Git\vcpkg>cd ..\replicator\clib\replicator
C:\Git\replicator\clib\replicator>mkdir build
C:\Git\replicator\clib\replicator>cd build
C:\Git\replicator\clib\replicator\build>cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/Git/vcpkg/scripts/buildsystems/vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows-static
-- Building for: Visual Studio 16 2019
-- Selecting Windows SDK version 10.0.18362.0 to target Windows 10.0.18363.
-- The CXX compiler identification is MSVC 19.28.29335.0
...
-- Configuring done
-- Generating done
-- Build files have been written to: C:/Git/replicator/clib/replicator/build

C:\Git\replicator\clib\replicator\build>cmake --build . --config Release
Microsoft (R) Build Engine version 16.8.2+25e4d540b for .NET Framework
Copyright (C) Microsoft Corporation. All rights reserved.

  Checking Build System
  Building Custom Rule C:/Git/replicator/clib/replicator/efsw/CMakeLists.txt
...
     Creating library C:/Git/replicator/clib/replicator/build/Release/replicator.lib and object C:/Git/replicator/clib/replicator/build/Release/replicator.exp
  replicator.vcxproj -> C:\Git\replicator\clib\replicator\build\Release\replicator.dll
  Building Custom Rule C:/Git/replicator/clib/replicator/CMakeLists.txt
  
```

# q/qpk Interface
## Pre-flight
To use the q-based launcher, you will need the q supervisor (qsup).

    $ qp pull gitlab.com/kxdev/cloud/packaging/qsup/qsup.qpk 0.0.10

This must be a peer-dependency of replicator, and loaded before it; so your application should have
something like the following in your `qp.json`:

    {
      "default": {
        "entry": ["app.q"],
        "depends": ["qsup", "replicator"]
      }
    }

## Usage

Assume you have:

1. Node 1 has a publisher directory `push_source` that is to be replicated
2. Node 2 stores a combined repository `cluster` containing multiple directories, one per publisher
3. Node 3 has a subscriber directory `pull_target` containing one or more of the replicated publisher directories

On node 2, start the servers:

    q).com_kx_replicator.push_server `base_dir`endpoint!`:./cluster`:0:50051
    q).com_kx_replicator.pull_server `base_dir`endpoint!`:./cluster`:0:50052

Then on node 1, start the push client:

    q).com_kx_replicator.push_client `endpoint`source_dir`server_sub_dir!`:localhost:50051`push_source`:push_source

Finally on node 3 start the `pull_client` connecting to the `pull_server` endpoint:

    q).com_kx_replicator.pull_client `endpoint`server_sub_dir`target_dir!`:localhost:50052`push_source`pull_target

## Supported options

### Common options

| Option name | Description                                                                                               |
|:------------|:----------------------------------------------------------------------------------------------------------|
| `id`        | Optional: Not used by replicator, but by `.com_kx_qsup` to identify the service. Defaults to `endpoint`   |
| `endpoint`  | The network endpoint to use. See below; it has slightly different meanings based on the mode of operation |
| `logging_level_console` | Console logging level where 0=none through 5=debug.  Note that errors are always sent to stderr. |
| `logging_level_file` | File logging level where 0=none through 5=debug, outputted to the file `replicator/<replicator_type>.<pid>` |
| `use_ssl`   | Enable (`1b`) to enable and require SSL/TLS. See the **SSL Options** below for details                    |
| `heartbeat_interval` | Interval in milliseconds between each heartbeat sent. Recommended for wide-area connections, but not within a lan. |
| `truncate_archived` | Enable (`1b`) to automatically truncate archived files |


### SSL options

All of these require `use_ssl` set to `1b` and you must use these over a wide-area network (outside the cluster)
for confidentiality and integrity:

| Option name | Description                                                                             |
|:------------|:----------------------------------------------------------------------------------------|
| `use_ssl` | Set to `1b` to enable and require SSL/TLS                                                 |
| `ssl_pem_cert_chain_file`  | File containing the PEM encoding of the certificate to present           |
| `ssl_pem_private_key_file` | File containing the PEM encoding of the private key associated with the above certificate |
| `ssl_pem_root_certs_file`  | File containing the PEM encoding of the CA used to mutually authenticate the peer certificate |

### Producer Recovery

If the producer has unreliable storage, it may need to perform some post-delivery recovery.
This is enabled with the following options:

| Option name | Description                                                                             |
|:------------|:----------------------------------------------------------------------------------------|
| `ignore_inconsistent` | Set to `1b` to skip errors after reporting                                    |
| `error_handler`  | Command to pass to `system()` that will recover from the error                     |

these options are available in both `.com_kx_replicator.push_client` and `.com_kx_replicator.pull_server`

### `.com_kx_replicator.push_server`

| Option name | Description                                                                             |
|:------------|:----------------------------------------------------------------------------------------|
| `base_dir`  | The base directory under which the client's target directories are being replicated to. |
| `endpoint`  | The network endpoint the server should listen to as `0:port` or `interfaceAddress:port` if binding to a specific interface is desired |
| `fragment_size` | Maximum length in bytes of a streaming update to be sent to the receiver in a single update.  Default 1MB. |

### `.com_kx_replicator.push_client`

| Option name | Description                                                                             |
|:------------|:----------------------------------------------------------------------------------------|
| `source_dir` |  The directory data should be replicated from                                          |
| `server_sub_dir` |  The directory data should be replicated to on the server (something uniquely identifying the client+topic pair) |
| `endpoint`  | The network endpoint the server client should connect to as a `host:port`               |

### `.com_kx_replicator.pull_server`

| Option name | Description                                                                             |
|:------------|:----------------------------------------------------------------------------------------|
| `base_dir` |  The directory where source directories to replicate from are found                      |
| `endpoint`  | The network endpoint the server should listen to as `0:port` or `interfaceAddress:port` if binding to a specific interface is desired |
| `fragment_size` | Maximum length in bytes of a streaming update to be sent to the receiver in a single update.  Default 1MB. |

### `.com_kx_replicator.pull_client`

| Option name | Description                                                                             |
|:------------|:----------------------------------------------------------------------------------------|
| `target_dir` |  The directory data should be replicated to                                            |
| `server_sub_dir` |  The directory data should be replicated from on the server (something uniquely identifying the topic) |
| `endpoint`  | The network endpoint the server client should connect to as a `host:port`               |
| `retry_attempts` | If after connecting the RPC fails, the client will reconnect and retry.  If after x retries the RPC continues to fail without making progress the client will exit.  Default 5. |
| `retry_delay` | Delay in ms between RPC retries.  Default 3000ms. |

# Command-line interface
## Usage

Assume you have:

1. Node 1 has a publisher directory `push_source` that is to be replicated
2. Node 2 stores a combined repository `cluster` containing multiple directories, one per publisher
3. Node 3 has a subscriber directory `pull_target` containing one or more of the replicated publisher directories

To setup the file transfer:

On node 2 start the `push_server` and `pull_server` each with a different endpoint:

```bash
C:\Git\replicator>push_server --base-dir cluster --endpoint localhost:50051 --debugging 1
Server listening on localhost:50051
```

```bash
C:\Git\replicator>pull_server --base-dir cluster --endpoint localhost:50052 --debugging 1
Server listening on localhost:50052
```

Then on node 1 start the `push_client` connecting to the `push_server` endpoint:

```bash
C:\Git\replicator>push_client --endpoint localhost:50051 --server-sub-dir push_source --source-dir push_source --debugging 1
```

Finally on node 3 start the `pull_client` connecting to the `pull_server` endpoint:

```bash
C:\Git\replicator>pull_client --endpoint localhost:50052 --server-sub-dir push_source --target-dir pull_target --debugging 1
```

Note the push and pull sides can be started in either order although the servers must be started before the clients.

The file updates will flow from `push_source` (node 1) > `cluster/push_source`  (node 2) > `pull_target/push_source` (node 3)



## Supported options

```bash
C:\Git\rt\replicator\clib\replicator\vs2019\x64\Debug>push_server
push_server (version "GIT_REV: 'UNKNOWN', GIT_TAG: 'UNKNOWN', GIT_BRANCH: 'UNKNOWN'"):

Supported string options:
--base-dir                 The base directory under which the client's target directories are being replicated to.
--diagnostics-prefix       If set, the server will write JSON diagnostics to '<prefix>.<pid>.json' every 10s.  Default empty.
--endpoint                 The network endpoint that the server should listen on as 'name:port' or 'address:port'
--logging-level-console    Console logging level: NONE, FATAL, ERROR, WARN, INFO, DEBUG or TRACE.  Default NONE.
--logging-level-file       File logging level: NONE, FATAL, ERROR, WARN, INFO, DEBUG or TRACE.  Default NONE.
--server-name              Server name to be displayed in logging.  Default $HOSTNAME.
--ssl-pem-cert-chain-file  File containing the PEM encoding of the server's certificate chain.  Only used if --use-ssl is set.  Default empty.
--ssl-pem-private-key-file File containing the PEM encoding of the server's private key.  Only used if --use-ssl is set.  Default empty.
--ssl-pem-root-certs-file  File containing the PEM encoding of the server root certificates.  Only used if --use-ssl is set.  Default empty.

Supported int options:
--debugging          Deprecated - if set equivalent to --logging-level-file INFO
--errors-on-stdout   Flag indicating if ERROR or FATAL console logs should be displayed on stdout rather than stderr.  Default 0.
--heartbeat-interval Interval in milliseconds between each heartbeat that the server sends to a client.  Default 5000ms.
--rest-client-port   If set, the server will forward tunneled REST requests to this endpoint.
--shutdown-after     Test use only.  If set, forces the server to shutdown automatically after the specified number of seconds.
--ssl-check-delay    Delay in minutes between checking if any of the SSL files have changed (in which case the server will exit).  Only used if --use-ssl is set.  Default 60 mins.
--stats-interval     Interval in seconds between logging stats.  Default 0s (disabled).
--truncate-archived  Flag indicating whether the client should auto-truncate archived files.  Default 0.
--use-ssl            Flag indicating whether the server should use SSL.  Default 0.
```



```bash
C:\Git\rt\replicator\clib\replicator\vs2019\x64\Debug>push_client
push_client (version "GIT_REV: 'UNKNOWN', GIT_TAG: 'UNKNOWN', GIT_BRANCH: 'UNKNOWN'"):

Supported string options:
--client-name              Client name to be displayed in logging.  Default $HOSTNAME.
--endpoint                 The network endpoint that the client should connect to as 'name:port' or 'address:port'.
--error-handler            Binary which is executed when an error occurs with the environment variables REPLICATOR_* containing the details.  Default empty.
--ignore-prefix            Prefix of file names to be ignored for replication.  Default empty.
--logging-level-console    Console logging level: NONE, FATAL, ERROR, WARN, INFO, DEBUG or TRACE.  Default NONE.
--logging-level-file       File logging level: NONE, FATAL, ERROR, WARN, INFO, DEBUG or TRACE.  Default NONE.
--server-sub-dir           The subdirectory under the server's base directory which should be replicated to.
--source-dir               The source directory that should be replicated from.
--ssl-pem-cert-chain-file  File containing the PEM encoding of the client's certificate chain.  Only used if --use-ssl is set.  Default empty.
--ssl-pem-private-key-file File containing the PEM encoding of the client's private key.  Only used if --use-ssl is set.  Default empty.
--ssl-pem-root-certs-file  File containing the PEM encoding of the server root certificates.  Only used if --use-ssl is set.  Default empty.
--ssl-target-name-override Target name override for SSL host name checking.  This option should be used with caution in production.  Only used if --use-ssl is set.  Default empty.

Supported int options:
--connect-timeout      Length of time in seconds that the client will attempt to connect to the server before exiting.  Default 60s.
--debugging            Deprecated - if set equivalent to --logging-level-file INFO
--errors-on-stdout     Flag indicating if ERROR or FATAL console logs should be displayed on stdout rather than stderr.  Default 0.
--exit-on-inconsistent If non-zero, exit immediately with the specified error code if the target directory has files not present at the source.  Default 0.
--fragment-size        Maximum length in bytes of a streaming update to be sent to the receiver in a single update.  Default 1MB.
--fw-drain-interval    Interval in milliseconds between draining the filewatcher (decreases CPU usage but increases latency).  Default is to drain immediately.
--heartbeat-timeout    Timeout in milliseconds that the client should wait for each heartbeat from the server befor erroring.  Default 10000ms.
--ignore-inconsistent  Flag indicating whether to ignore files where the receiver's length is greater than the sender's length.  Default 0.
--reparent-check       Interval if seconds that the replicator will check if its parent process has changed, in which case it exits.  Default 0 (not enabled).
--rescan-interval      Interval in milliseconds between each rescan (as a filewatcher fallback) of the source directory.  Default 1000ms.
--rest-server-port     If set, the client will provide a REST server on this port with the requests being tunneled through the connection.
--retry-attempts       If after connecting the RPC fails, the client will reconnect and retry.  If after x retries the RPC continues to fail without making progress the client will exit.  Default 5.
--retry-delay          Delay in ms between RPC retries.  Default 3000ms.
--ssl-check-delay      Delay in minutes between checking if any of the SSL files have changed (in which case the client will exit).  Only used if --use-ssl is set.  Default 60 mins.
--stats-interval       Interval in seconds between logging stats.  Default 0s (disabled).
--suppress-fw-warnings Flag indicating whether to suppress filewatcher warnings for DELETE and MOVE events.  Default 0.
--truncate-archived    Flag indicating whether the client should auto-truncate archived files.  Default 0.
--use-ssl              Flag indicating whether the client should use SSL.  Default 0.
```



```bash
C:\Git\rt\replicator\clib\replicator\vs2019\x64\Debug>pull_server
pull_server (version "GIT_REV: 'UNKNOWN', GIT_TAG: 'UNKNOWN', GIT_BRANCH: 'UNKNOWN'"):

Supported string options:
--base-dir                 The base directory under which the source directories to replicate from are found.
--diagnostics-prefix       If set, the server will write JSON diagnostics to '<prefix>.<pid>.json' every 10s.  Default empty.
--endpoint                 The network endpoint that the server should listen on as 'name:port' or 'address:port'
--error-handler            Binary which is executed when an error occurs with the environment variables REPLICATOR_* containing the details.  Default empty.
--ignore-prefix            Prefix of file names to be ignored for replication.  Default empty.
--logging-level-console    Console logging level: NONE, FATAL, ERROR, WARN, INFO, DEBUG or TRACE.  Default NONE.
--logging-level-file       File logging level: NONE, FATAL, ERROR, WARN, INFO, DEBUG or TRACE.  Default NONE.
--server-name              Server name to be displayed in logging.  Default $HOSTNAME.
--ssl-pem-cert-chain-file  File containing the PEM encoding of the server's certificate chain.  Only used if --use-ssl is set.  Default empty.
--ssl-pem-private-key-file File containing the PEM encoding of the server's private key.  Only used if --use-ssl is set.  Default empty.
--ssl-pem-root-certs-file  File containing the PEM encoding of the server root certificates.  Only used if --use-ssl is set.  Default empty.

Supported int options:
--debugging            Deprecated - if set equivalent to --logging-level-file INFO
--errors-on-stdout     Flag indicating if ERROR or FATAL console logs should be displayed on stdout rather than stderr.  Default 0.
--fragment-size        Maximum length in bytes of a streaming update to be sent to the receiver in a single update.  Default 1MB.
--fw-drain-interval    Interval in milliseconds between draining the filewatcher (decreases CPU usage but increases latency).  Default is to drain immediately.
--heartbeat-interval   Interval in milliseconds between each heartbeat that the server sends to a client.  Default 5000ms.
--ignore-inconsistent  Flag indicating whether to ignore files where the receiver's length is greater than the sender's length.  Default 0.
--rescan-interval      Interval in milliseconds between each rescan (as a filewatcher fallback) of the source directory.  Default 1000ms.
--rest-client-port     If set, the server will forward tunneled REST requests to this endpoint.
--shutdown-after       Test use only.  If set, forces the server to shutdown automatically after the specified number of seconds.
--ssl-check-delay      Delay in minutes between checking if any of the SSL files have changed (in which case the server will exit).  Only used if --use-ssl is set.  Default 60 mins.
--stats-interval       Interval in seconds between logging stats.  Default 0s (disabled).
--suppress-fw-warnings Flag indicating whether to suppress filewatcher warnings for DELETE and MOVE events.  Default 0.
--truncate-archived    Flag indicating whether the client should auto-truncate archived files.  Default 0.
--use-ssl              Flag indicating whether the server should use SSL.  Default 0.
```



```bash
C:\Git\rt\replicator\clib\replicator\vs2019\x64\Debug>pull_client
pull_client (version "GIT_REV: 'UNKNOWN', GIT_TAG: 'UNKNOWN', GIT_BRANCH: 'UNKNOWN'"):

Supported string options:
--client-name              Client name to be displayed in logging.  Default $HOSTNAME.
--endpoint                 The network endpoint that the client should connect to as 'name:port' or 'address:port'.
--logging-level-console    Console logging level: NONE, FATAL, ERROR, WARN, INFO, DEBUG or TRACE.  Default NONE.
--logging-level-file       File logging level: NONE, FATAL, ERROR, WARN, INFO, DEBUG or TRACE.  Default NONE.
--server-sub-dir           The subdirectory under the server's base directory which should be replicated from.
--ssl-pem-cert-chain-file  File containing the PEM encoding of the client's certificate chain.  Only used if --use-ssl is set.  Default empty.
--ssl-pem-private-key-file File containing the PEM encoding of the client's private key.  Only used if --use-ssl is set.  Default empty.
--ssl-pem-root-certs-file  File containing the PEM encoding of the server root certificates.  Only used if --use-ssl is set.  Default empty.
--ssl-target-name-override Target name override for SSL host name checking.  This option should be used with caution in production.  Only used if --use-ssl is set.  Default empty.
--start-point              The name of the file to start replication from.
--target-dir               The target directory that should be replicated to.

Supported int options:
--connect-timeout   Length of time in seconds that the client will attempt to connect to the server before exiting.  Default 60s.
--debugging         Deprecated - if set equivalent to --logging-level-file INFO
--errors-on-stdout  Flag indicating if ERROR or FATAL console logs should be displayed on stdout rather than stderr.  Default 0.
--exchange-archived Flag indicating whether the client should send archived events to the server and vice versa.  Default 1.
--heartbeat-timeout Timeout in milliseconds that the client should wait for each heartbeat from the server befor erroring.  Default 10000ms.
--reparent-check    Interval if seconds that the replicator will check if its parent process has changed, in which case it exits.  Default 0 (not enabled).
--rest-server-port  If set, the client will provide a REST server on this port with the requests being tunneled through the connection.
--retry-attempts    If after connecting the RPC fails, the client will reconnect and retry.  If after x retries the RPC continues to fail without making progress the client will exit.  Default 5.
--retry-delay       Delay in ms between RPC retries.  Default 3000ms.
--ssl-check-delay   Delay in minutes between checking if any of the SSL files have changed (in which case the client will exit).  Only used if --use-ssl is set.  Default 60 mins.
--stats-interval    Interval in seconds between logging stats.  Default 0s (disabled).
--truncate-archived Flag indicating whether the client should auto-truncate archived files.  Default 0.
--use-ssl           Flag indicating whether the client should use SSL.  Default 0.
```

# Building a config for running RT as a microservice. 

When RT is running as a microserive there will be no information service present to provide the config information, so a config file will need to be generated. This is done using the ./clib/build_microserice_config.sh script, like this.

```bash
SERVICE_NAME=dgm_service TOPIC_NAME=topic-name RT_ENDPOINTS=:127.0.0.1:5002,:127.0.0.2:5002,:127.0.0.3:5002 ./clib/build_microservice_config.sh > ./config.json
```
