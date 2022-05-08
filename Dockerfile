FROM alpine:latest
LABEL maintaner="Mariusz Ornowski <mariusz.ornowski@ict-project.pl>"
LABEL description="DNS server (bind)"

VOLUME [ "/data","/var/cache/bind", "/var/run/named" ]

ADD named.conf /etc/bind/named.conf
ADD named.conf.options /etc/bind/named.conf.options
ADD named.conf.local /etc/bind/named.conf.local
ADD entrypoint.sh /root/entrypoint.sh
ADD healthcheck.sh /root/healthcheck.sh

RUN apk add --update bind || echo ok && \
    rm -rf /var/cache/apk/* && \
    chmod +x /root/healthcheck.sh && \
    chmod +x /root/entrypoint.sh && \
    chown named:named /etc/bind/rndc.key && \
    chmod 644 /etc/bind/rndc.key

EXPOSE 53/udp
EXPOSE 53/tcp

HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=1 CMD [ "/root/healthcheck.sh" ]

ENTRYPOINT ["/root/entrypoint.sh"]
