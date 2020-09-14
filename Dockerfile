FROM debian:buster
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && apt-get -y install git git-lfs && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man/?? /usr/share/man/??_*
COPY ./entrypoint.sh /entrypoint.sh

RUN git lfs install

CMD ["/entrypoint.sh"]
