FROM bash

LABEL maintainer="Dragos Dumitrache <dragos@afterburner.dev>"

RUN apk add --no-cache git bash

WORKDIR /home

COPY version.sh /home/version.sh

RUN chmod +x /home/version.sh
ENTRYPOINT [ "/home/version.sh" ]