FROM bash

LABEL maintainer="Dragos Dumitrache <dragos@afterburner.dev>"

RUN apk add --no-cache git bash;

COPY version.sh /usr/local/bin/versioner

WORKDIR /repo
RUN chmod +x /usr/local/bin/versioner
CMD [ "versioner" ]
