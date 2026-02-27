FROM debian

ARG API_TOKEN
ARG REPLICATOR_VERSION
ARG CI_COMMIT_TAG

RUN apt update && apt install cmake curl zip unzip gcc-mingw-w64-x86-64-posix g++-mingw-w64-x86-64-posix -y
## boost
ADD clib/deps/boost_1_82_0_headers.tar.gz ./
RUN cp -r boost /usr/local/include
COPY . /app

WORKDIR /app/clib/rt_helper

RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=/app/mingw.cmake . && make -j

RUN echo "$CI_JOB_TOKEN"
RUN echo "$API_TOKEN"
RUN echo "$REPLICATOR_VERSION"
RUN echo "$CI_COMMIT_TAG"

RUN curl  --header "Private-Token:$API_TOKEN" -s "https://gitlab.com/api/v4/projects/27968270/packages/generic/replicator/replicator_windows/${REPLICATOR_VERSION}.zip" -o replicator.zip

RUN unzip replicator.zip && ls -la ./


ENV KXI_C_SDK_DIR /kxi_c_sdk
RUN mkdir ${KXI_C_SDK_DIR}  && cp -R kdb/include ${KXI_C_SDK_DIR} && \
    cp -R rt_helper/include ${KXI_C_SDK_DIR} && \
    cp `find . -type f -name rt_helper_curl.exe` ${KXI_C_SDK_DIR} && \
    cp `find . -type f -name generate_rt_config.sh` ${KXI_C_SDK_DIR} && \
    cp /app/mingw.cmake ${KXI_C_SDK_DIR} && \
    cp `find . -type f -name librt_helper.dll` ${KXI_C_SDK_DIR}/ && \
    cp `find . -type f -name librt_helper.dll.a` ${KXI_C_SDK_DIR}/ && \
    cp `find / -name libwinpthread-1.dll` ${KXI_C_SDK_DIR}/ && \
    cp `find / -name libcurl-x64.dll` ${KXI_C_SDK_DIR}/ && \
    cp `find / -name libgcc_s_seh-1.dll` ${KXI_C_SDK_DIR}/ && \
    cp ./kdb/obj/Windows/c.dll ${KXI_C_SDK_DIR}/ && \    
    cp ./kdb/obj/Windows/c.lib ${KXI_C_SDK_DIR}/ &&\
    cp replicator.dll ${KXI_C_SDK_DIR} && \
    cp push_client.exe ${KXI_C_SDK_DIR} && \
    cp rest_proxy.exe ${KXI_C_SDK_DIR}

RUN zip -r /root/kxi-c-sdk-windows-${CI_COMMIT_TAG}.zip ${KXI_C_SDK_DIR}

