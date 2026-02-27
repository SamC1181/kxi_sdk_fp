FROM rockylinux:8.9

ARG API_TOKEN
ARG REPLICATOR_VERSION
ARG RT1_CORE_SUB_VERSION
ARG CI_COMMIT_TAG
ARG CONAN_GITLAB_TOKEN

RUN yum -y install epel-release && yum update -y && yum install which cmake  make  patchelf python3 perl clang -y
RUN curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq
RUN dnf --enablerepo=powertools install libstdc++-static -y

ENV CXX=clang++
ENV CC=clang

# Running pip as the 'root' user can result in broken permissions and 
# conflicting behaviour with the system package manager. It is recommended to use a virtual environment instead: 
# https://pip.pypa.io/warnings/venv
RUN python3 -m venv ~/.venv/devel
RUN . ~/.venv/devel/bin/activate

# Install Conan
RUN python3 -m pip install --upgrade pip setuptools && \
    python3 -m pip install conan==1.*

# By default, anything you run in Docker is done as superuser.
# Conan runs some install commands as superuser, and will prepend `sudo` to
# these commands, unless `CONAN_SYSREQUIRES_SUDO=0` is in your env variables.
ENV CONAN_SYSREQUIRES_SUDO 0
# Some packages request that Conan use the system package manager to install
# a few dependencies. This flag allows Conan to proceed with these installations;
# leaving this flag undefined can cause some installation failures.
ENV CONAN_SYSREQUIRES_MODE enabled

## boost
ADD clib/deps/boost_1_82_0_headers.tar.gz ./
RUN cp -r boost /usr/local/include

COPY . /app

WORKDIR /app/clib/rt_helper/rt1_sub/rt

RUN echo "$CI_JOB_TOKEN"
RUN echo "$API_TOKEN"
RUN echo "$REPLICATOR_VERSION"
RUN echo "$CI_COMMIT_TAG"

RUN curl  --header "Private-Token:$API_TOKEN" -s "https://gitlab.com/api/v4/projects/27754751/packages/generic/rt1_core_sub/$RT1_CORE_SUB_VERSION/rt1_core_sub.zip" -o rt1_core_sub.zip
RUN unzip rt1_core_sub.zip && ls -la ./
RUN rm -rf include lib
RUN mv rt/include ./include && mv rt/lib ./lib 
RUN ar -cr ./lib/librt1_core_sub_l64.a ./lib/rt1_core_sub_l64.o
RUN rm -rf rt rt1_core_sub.zip

WORKDIR /app/clib/rt_helper 

RUN conan remote add gitlab https://gitlab.com/api/v4/projects/39565241/packages/conan
RUN conan user conan-deploy-token -r gitlab -p $CONAN_GITLAB_TOKEN
RUN conan config init && yq eval '.compiler.clang.version += ["18"]' -i /root/.conan/settings.yml
RUN conan install .. -s compiler.libcxx=libstdc++11 -s compiler=clang -r gitlab

RUN cmake -DCMAKE_BUILD_TYPE=Release . && make -j



RUN curl  --header "Private-Token:$API_TOKEN" -s "https://gitlab.com/api/v4/projects/27968270/packages/generic/replicator/$REPLICATOR_VERSION/replicator.qpk" -o replicator.zip

RUN unzip replicator.zip && ls -la ./


ENV KXI_C_SDK_DIR /kxi_c_sdk
RUN mkdir ${KXI_C_SDK_DIR}  && cp -R kdb/include ${KXI_C_SDK_DIR} && \
    cp -R rt_helper/include ${KXI_C_SDK_DIR} && \
    cp `find . -type f -name rt_helper_curl` ${KXI_C_SDK_DIR} && \
    cp `find . -type f -name librt_helper.so` ${KXI_C_SDK_DIR} && \
    cp `find . -type f -name replicator_static.so` ${KXI_C_SDK_DIR} && \
    cp `find . -type f -name push_client_static` ${KXI_C_SDK_DIR} && \
    cp `find . -type f -name pull_client_static` ${KXI_C_SDK_DIR} && \
    cp `find . -type f -name rest_proxy_static` ${KXI_C_SDK_DIR} && \
    cp `find . -type f -name generate_rt_config.sh` ${KXI_C_SDK_DIR}


RUN zip -r /root/kxi-c-sdk-${CI_COMMIT_TAG}.zip ${KXI_C_SDK_DIR}



