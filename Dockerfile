FROM ubuntu:16.04
MAINTAINER Xia xiaozheng
LABEL version="1.0"
LABEL description="Wellcom OptionFamiy!"

## 替换 apt 源为阿里云，在本地构建镜像时，取消注释，使用阿里云的 apt 源
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse" > /etc/apt/sources.list
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse" >>/etc/apt/sources.list

RUN apt-get clean
RUN apt-get update -q --fix-missing

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PYTHONIOENCODING UTF-8
ENV PATH /opt/conda/bin:$PATH

RUN apt-get install -y wget \
    apt-utils \
    nano \
    perl-base \
    perl \
    bzip2 \
    ca-certificates \
    libglib2.0-0\
    libxext6\
    libsm6\
    libxrender1 \
    perl-modules \
    liberror-perl \
    git

RUN  apt-get clean \
  && apt-get autoclean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN wget --quiet https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc
ENV DEBIAN_FRONTEND noninteractive
RUN	apt-get update

RUN apt-get install -y curl grep sed dpkg dialog && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

RUN apt-get -qy autoremove
RUN echo "设置 conda 国内源, 从 conda 安装 python 库" \
    && conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/ \
    && conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/ \
    && conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/ \
    && conda config --set show_channel_urls yes
RUN conda update -n base conda
RUN conda install scikit-learn==0.18 -y

RUN conda install tensorflow==1.2.1 -y
RUN conda install keras==2.1.2 -y
RUN conda install pymc3 -y
RUN conda install cython -y
RUN conda install lxml -y

RUN conda install -c conda-forge fastparquet -y

COPY . /code
WORKDIR /code/

#RUN sadd-apt-repository ppa:linaro-maintainers/toolchain
RUN apt-get update
RUN apt-get -y install  vim g++ gcc gdb
RUN apt-get -y install binutils nasm
RUN apt-get -y install nmap

# Compiler install
RUN apt-get -y install libc6-dev-i386
RUN apt-get -y install gcc-multilib g++-multilib
#RUN apt-get install -y  gcc-multilib-arm-linux-gnueabi
#RUN apt-get install -y  gcc-multilib-arm-linux-gnueabihf
#RUN apt-get install -y  gcc-multilib-mips-linux-gnu
#RUN apt-get install -y  gcc-multilib-mips64-linux-gnuabi64
#RUN apt-get install -y  gcc-multilib-mips64el-linux-gnuabi64
#RUN apt-get install -y  gcc-multilib-mipsel-linux-gnu
#RUN apt-get install -y  gcc-multilib-powerpc-linux-gnu
#RUN apt-get install -y  gcc-multilib-powerpc64-linux-gnu
#RUN apt-get install -y  gcc-multilib-s390x-linux-gnu
#RUN apt-get install -y  gcc-multilib-sparc64-linux-gnu

RUN pip install -r requirements.txt
RUN pip install nltk
RUN python -m nltk.downloader all

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]
