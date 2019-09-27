#FROM djaydev/krusader:latest
FROM alpine:3.10
# Your custom commands
RUN apk upgrade --update-cache --available && \
    apk add systemsettings nano
    
    # Install language pack
#RUN apk --no-cache add ca-certificates wget 

#Run wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
#wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-2.30-r0.apk && \
#sudo dpkg -i --force-overwrite /var/cache/apt/archives/libjline-java_1.0-1_all.deb && \
#apk add glibc-2.30-r0.apk

# Iterate through all locale and install it
# Note that locale -a is not available in alpine linux, use `/usr/glibc-compat/bin/locale -a` instead
#COPY ./locale.md /locale.md
#RUN cat locale.md | xargs -i /usr/glibc-compat/bin/localedef -i {} -f UTF-8 {}.UTF-8

# Set the lang, you can also specify it as as environment variable through docker-compose.yml
ENV LANG=fr_FR.UTF-8 \
    LANGUAGE=fr_FR.UTF-8
    
    

#CMD ["/run.sh"]
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.30-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"


# Add testing repo for KDE packages
RUN echo "http://dl-3.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "http://dl-3.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    echo "http://dl-3.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories

# Install packages.
RUN apk --update --upgrade add \
    build-base cmake extra-cmake-modules qt5-qtbase-dev xvfb-run\
    git bash ki18n-dev kio-dev kbookmarks-dev kparts-dev kdesu-dev \
    kwindowsystem-dev kiconthemes-dev kxmlgui-dev kdoctools-dev libc6-compat \
    kdeplasma-addons-dev plasma-desktop-dev qt5-qtlocation-dev acl-dev

WORKDIR /tmp

# Download krusader, krename from KDE
RUN git clone git://anongit.kde.org/krename
RUN git clone git://anongit.kde.org/krusader
RUN mkdir krusader/build
RUN mkdir krename/build

# Compile krusader
RUN cd krusader/build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_C_FLAGS="-O2 -fPIC" ..
RUN sed -i 's/#include <time.h>/#include <time.h>\n#include <sys\/types.h>/' /tmp/krusader/krusader/DiskUsage/filelightParts/fileTree.h
RUN sed -i 's/#include <time.h>/#include <time.h>\n#include <sys\/types.h>/' /tmp/krusader/krusader/FileSystem/krpermhandler.h
RUN sed -i 's/#include <pwd.h>/#include <pwd.h>\n#include <sys\/types.h>/' /tmp/krusader/krusader/FileSystem/krpermhandler.cpp
RUN cd krusader/build && make -j$(nproc) && make install

# Compile krename
RUN cd krename/build && cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_C_FLAGS="-O2 -fPIC" ..
RUN cd krename/build && make -j$(nproc) && make install

# Pull base image.
#FROM jlesage/baseimage-gui:alpine-3.9

# Add testing repo for edge upgrade
RUN echo "http://dl-3.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "http://dl-3.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    echo "http://dl-3.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories

# Install packages.
RUN apk upgrade --update-cache --available && \
    apk add \
    bash kate keditbookmarks konsole kompare mesa-dri-swrast \
    p7zip unrar zip xz findutils ntfs-3g libacl taglib \
    dbus-x11 breeze-icons exiv2 kjs diffutils libc6-compat && \
    # some breeze icon names differ
    ln -s /usr/share/icons/breeze/mimetypes/22/audio-x-mpeg.svg /usr/share/icons/breeze/mimetypes/22/audio-mpeg.svg && \
    ln -s /usr/share/icons/breeze/mimetypes/22/application-x-raw-disk-image.svg /usr/share/icons/breeze/mimetypes/22/application-raw-disk-image.svg && \
    ln -s /usr/share/icons/breeze/mimetypes/22/application-x-gzip.svg /usr/share/icons/breeze/mimetypes/22/application-gzip.svg && \
    ln -s /usr/share/icons/breeze/mimetypes/22/video-x-generic.svg /usr/share/icons/breeze/mimetypes/22/video-quicktime.svg && \
    ln -s /usr/share/icons/breeze/mimetypes/22/libreoffice-presentation.svg /usr/share/icons/breeze/mimetypes/22/application-vnd.openxmlformats-officedocument.presentationml.presentation.svg && \
    ln -s /usr/share/icons/breeze/mimetypes/22/application-x-zerosize.svg /usr/share/icons/breeze/mimetypes/22/inode-socket.svg && \
    rm -rf /var/cache/apk/* /tmp/* /tmp/.[!.]* /usr/share/icons/breeze-dark /usr/share/icons/breeze/breeze-icons.rcc

# Adjust the openbox config.
RUN \
    # Maximize only the main/initial window.
    sed-patch 's/<application type="normal">/<application type="normal" title="Krusader">/' \
      /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="Krusader">/a \    <layer>below</layer>' \
      /etc/xdg/openbox/rc.xml

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/binhex/docker-templates/master/binhex/images/krusader-icon.png && \
    install_app_icon.sh "$APP_ICON_URL" \
    && rm -rf /var/cache/apk/*

# Copy the start script.
COPY startapp.sh /startapp.sh

# Copy Krusader from base build image.
COPY --from=builder /usr/local /usr/
RUN ln -s /usr/lib64/plugins/* /usr/lib/qt5/plugins/

# Change web background color
RUN echo "sed-patch 's/<body>/<body><style>body { background-color: dimgrey; }<\/style>\n/' /opt/novnc/index.html" >> /etc/cont-init.d/10-web-index.sh

# Set the name of the application.
ENV APP_NAME="Krusader"
