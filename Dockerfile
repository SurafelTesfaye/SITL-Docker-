FROM ubuntu:16.04
WORKDIR /ardupilot

RUN useradd -U -d /ardupilot ardupilot && \
    usermod -G users ardupilot

ENV USER=ardupilot

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install --no-install-recommends -y \
    lsb-release \
    sudo \
    software-properties-common \
    git \
    python-software-properties && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Passwordless sudo for ardupilot user
RUN echo "ardupilot ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ardupilot \
    && chmod 0440 /etc/sudoers.d/ardupilot

RUN git clone https://github.com/ArduPilot/ardupilot $(pwd)
RUN cd /ardupilot && git submodule update --init --recursive

RUN chown -R ardupilot:ardupilot /ardupilot

# Assumes fixed install script
RUN bash -c "Tools/environment_install/install-prereqs-ubuntu.sh -y && apt-get install gcc-arm-none-eabi -y" && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER ardupilot

ENV CCACHE_MAXSIZE=1G
ENV PATH /usr/lib/ccache:/ardupilot/Tools:${PATH}
ENV PATH /usr/lib/ccache:/ardupilot/Tools/autotest:${PATH}
ENV PATH /ardupilot/.local/bin:$PATH

# Build SITL/Copter
RUN ./waf configure --board sitl
RUN ./waf -j8 copter

EXPOSE 14550/udp
EXPOSE 14551/udp
EXPOSE 5760

ENTRYPOINT cd /ardupilot/ArduCopter && sim_vehicle.py -w --no-rebuild --console
