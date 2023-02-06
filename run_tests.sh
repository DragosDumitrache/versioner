#!/usr/bin/env bash

docker run --rm -e CRITIC_SETUP='apk add --no-cache jq' -v $(pwd):/work checksum/critic.sh '/work/test.sh'
