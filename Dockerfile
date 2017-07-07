
# docker build -t openvpn:latest -t mactijn/openvpn:latest .

FROM ubuntu:16.04

ENV LC_ALL en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive

#RUN LC_ALL=C.UTF-8 locale-gen en_US.UTF-8

RUN LC_ALL=C apt-get update && \
    LC_ALL=C apt-get -y install locales-all && \
    apt-get -y upgrade && \
    apt-get -y install openvpn easy-rsa iptables tcpdump net-tools iputils-ping traceroute && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    for FILE in ca.crt ca.key server.crt server.key ta.key dh2048.pem; do ln -fs "/ca/keys/${FILE}" "/etc/openvpn/${FILE}"; done

COPY entrypoint.sh /entrypoint.sh
COPY openvpn.conf /etc/openvpn/openvpn.conf

EXPOSE 1194/udp

WORKDIR /etc/openvpn

ENTRYPOINT ["/entrypoint.sh"]
CMD ["start"]
