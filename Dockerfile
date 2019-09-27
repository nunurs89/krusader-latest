FROM djaydev/krusader:latest

# Your custom commands
RUN apk upgrade --update-cache --available && \
    apk add systemsettings kde-l10n-fr nano
#CMD ["/run.sh"]
