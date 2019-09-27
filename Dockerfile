FROM djaydev/krusader:latest

# Your custom commands
RUN apk upgrade --update-cache --available && \
    apk add systemsettings apt-get nano
#CMD ["/run.sh"]
