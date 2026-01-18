FROM ubuntu:22.04

RUN apt update && apt install -y \
    build-essential \
    bison \
    flex \
    libgmp3-dev \
    libmpc-dev \
    libmpfr-dev \
    texinfo \
    nasm \
    qemu-system-x86 \
    wget \
    xorriso \
    grub-pc-bin \
    grub-common

WORKDIR /toolchain

RUN wget https://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.gz && \
    wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.gz

RUN tar -xf binutils-2.40.tar.gz && \
    tar -xf gcc-13.2.0.tar.gz

RUN mkdir build-binutils && cd build-binutils && \
    ../binutils-2.40/configure \
      --target=x86_64-elf \
      --prefix=/opt/cross \
      --with-sysroot \
      --disable-nls \
      --disable-werror && \
    make -j$(nproc) && make install

RUN mkdir build-gcc && cd build-gcc && \
    ../gcc-13.2.0/configure \
      --target=x86_64-elf \
      --prefix=/opt/cross \
      --disable-nls \
      --enable-languages=c,c++ \
      --without-headers && \
    make all-gcc -j$(nproc) && \
    make all-target-libgcc -j$(nproc) && \
    make install-gcc && \
    make install-target-libgcc

ENV PATH="/opt/cross/bin:$PATH"

WORKDIR /workspace

CMD ["/bin/bash"]