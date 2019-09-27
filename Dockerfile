FROM djaydev/krusader:latest

# Your custom commands
RUN apk upgrade --update-cache --available && \
    apk add language-fr language-fr-base language-pack-kde-fr language-pack-kde-fr-base language-support-fr
#CMD ["/run.sh"]
