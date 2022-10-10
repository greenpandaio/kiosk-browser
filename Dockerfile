ARG NODEJS_VERSION="12"

FROM balenalib/genericx86-64-ext-debian-node:${NODEJS_VERSION}-buster-run

# install required packages
RUN install_packages \
    ssh \
    chromium-common=90.0.4430.212-1~deb10u1\
    chromium=90.0.4430.212-1~deb10u1\
    fonts-noto-color-emoji \
    libgles2-mesa \
    lsb-release \
    mesa-vdpau-drivers \
    scrot \
    wget \
    x11-xserver-utils \
    xserver-xorg-input-evdev \
    xserver-xorg-legacy \
    xserver-xorg-video-fbdev \
    xserver-xorg xinit \
    xinput \
    xterm 

WORKDIR /usr/src/app

# install node dependencies
COPY ./package.json /usr/src/app/package.json
RUN JOBS=MAX npm install --unsafe-perm --production && npm cache clean --force

COPY ./src /usr/src/app/

RUN chmod +x ./*.sh

ENV UDEV=1

RUN mkdir -p /etc/chromium/policies
RUN mkdir -p /etc/chromium/policies/recommended
COPY ./policy.json /etc/chromium/policies/recommended/my_policy.json

# Add chromium user
RUN useradd chromium -m -s /bin/bash -G root || true && \
    groupadd -r -f chromium && id -u chromium || true \
    && chown -R chromium:chromium /home/chromium || true

COPY ./public-html /home/chromium  

# udev rule to set specific permissions 
RUN echo 'SUBSYSTEM=="vchiq",GROUP="video",MODE="0660"' > /etc/udev/rules.d/10-vchiq-permissions.rules
RUN usermod -a -G audio,video,tty chromium

RUN ln -s /usr/bin/chromium /usr/bin/chromium-browser || true

# Set up the audio block. This won't have any effect if the audio block is not being used.
RUN curl -skL https://raw.githubusercontent.com/balenablocks/audio/master/scripts/alsa-bridge/debian-setup.sh| sh
ENV PULSE_SERVER=tcp:audio:4317

COPY VERSION .
EXPOSE 5011
EXPOSE 35173
# Start app
CMD ["bash", "/usr/src/app/start.sh"]
