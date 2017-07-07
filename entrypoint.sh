#!/bin/bash

CA_DIR="${CA_DIR:-/ca}"
CLIENT_CONFIG_DIR="${CLIENT_CONFIG_DIR:-/client-configs}"

case "${1}" in

	clean)
		rm -rf "${CA_DIR}"/* "${CLIENT_CONFIG_DIR}"/*

		;;

	init)
		KEY_COUNTRY="${KEY_COUNTRY:-US}"
		KEY_PROVINCE="${KEY_PROVINCE:-CA}"
		KEY_CITY="${KEY_CITY:-San Francisco}"
		KEY_ORG="${KEY_ORG:-Fort-Funston}"
		KEY_EMAIL="${KEY_EMAIL:-me@myhost.mydomain}"
		KEY_OU="${KEY_OU:-MyOrganizationalUnit}"

		if [ ! /ca/vars ]; then
			echo "existing config still exists! exiting."
			exit 1
		fi

		rm -rf /ca/tmp
		make-cadir /ca/tmp
		mv /ca/tmp/* /ca/
		
		sed -i \
		    -e 's/^export KEY_COUNTRY=.*$/export KEY_COUNTRY="'"${KEY_COUNTRY}"'"/' \
		    -e 's/^export KEY_PROVINCE=.*$/export KEY_PROVINCE="'"${KEY_PROVINCE}"'"/' \
		    -e 's/^export KEY_CITY=.*$/export KEY_CITY="'"${KEY_CITY}"'"/' \
		    -e 's/^export KEY_ORG=.*$/export KEY_ORG="'"${KEY_ORG}"'"/' \
		    -e 's/^export KEY_EMAIL=.*$/export KEY_EMAIL="'"${KEY_EMAIL}"'"/' \
		    -e 's/^export KEY_OU=.*$/export KEY_OU="'"${KEY_OU}"'"/' \
		    -e 's/^export KEY_NAME=.*$/export KEY_NAME="server"/' \
		    "${CA_DIR}/vars"

		cd "${CA_DIR}"
		#ln -s openssl-1.0.0.cnf openssl.cnf
		. ./vars
		./clean-all
		./pkitool --initca
		./pkitool --server server
		$OPENSSL dhparam -out ${KEY_DIR}/dh${KEY_SIZE}.pem ${KEY_SIZE}
		openvpn --genkey --secret keys/ta.key


		rm -rf "${CLIENT_CONFIG_DIR}/files"
		mkdir -p "${CLIENT_CONFIG_DIR}/files"
		chmod 0700 "${CLIENT_CONFIG_DIR}/files"

		# get IP
		SERVER_NAME="${SERVER_NAME:-$(hostname --fqdn)}"

		sed -e 's/^remote .*/remote '"${SERVER_NAME}"' 1194/' \
		    -e 's/^ca /;ca /' -e 's/^cert /;cert /' -e 's/^key /;key /' \
		    < /usr/share/doc/openvpn/examples/sample-config-files/client.conf > "${CLIENT_CONFIG_DIR}/base.conf"
		    echo -e 'cipher AES-128-CBC\nauth SHA256\nkey-direction 1' >> "${CLIENT_CONFIG_DIR}/base.conf"

		
		;;

	client)
		if [ -z "${2}" ]; then
			echo "usage: docker-compose run --rm openvpn client <client_id>"
			exit 1
		fi

		cd "${CA_DIR}"
		. ./vars
		./pkitool "${2}"

		cat "${CLIENT_CONFIG_DIR}/base.conf" \
                    <(echo -e '<ca>') \
                    "${CA_DIR}/keys/ca.crt" \
                    <(echo -e '</ca>\n<cert>') \
                    "${CA_DIR}/keys/${2}.crt" \
                    <(echo -e '</cert>\n<key>') \
                    "${CA_DIR}/keys/${2}.key" \
                    <(echo -e '</key>\n<tls-auth>') \
                    "${CA_DIR}/keys/ta.key" \
                    <(echo -e '</tls-auth>') \
                  > "${CLIENT_CONFIG_DIR}/files/${2}.ovpn"
		;;

	start)
		iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
		exec /usr/sbin/openvpn --cd /etc/openvpn --config /etc/openvpn/openvpn.conf --script-security 2
	;;

	shell|bash|sh)
		exec bash -i
		;;


	*)
		echo "unknown command: '${1}'"
		exit 1
esac
