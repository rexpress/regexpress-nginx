FROM nginx:1.10-alpine

COPY run.sh /root/run.sh

RUN apk add --no-cache bash jq

ENTRYPOINT ["/bin/bash", "/root/run.sh"]