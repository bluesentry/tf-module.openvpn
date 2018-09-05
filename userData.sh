#!/usr/bin/env bash

  admin_user="${admin_user}"
  admin_pw="${admin_pw}"

  echo "##################### Configuring OpenVPN #####################"

  if [ "${split_tunnel}" == "true" ]; then
    # Split tunnel
    /usr/local/openvpn_as/scripts/sacli --key vpn.client.routing.reroute_gw --value false ConfigPut
  else
    # Route Internet traffic through the VPN
    /usr/local/openvpn_as/scripts/sacli --key vpn.client.routing.reroute_gw --value true ConfigPut
  fi

  /usr/local/openvpn_as/scripts/sacli --key vpn.client.tls_version_min --value 1.2 ConfigPut
  /usr/local/openvpn_as/scripts/sacli --key vpn.server.tls_version_min --value 1.2 ConfigPut


  # Setting WebServer SSL/TLS Options to TLSv1.2 to disable SSV3. This will avoid SOC Vulnerability related to OpenVPN
  /usr/local/openvpn_as/scripts/sacli --key cs.tls_version_min --value 1.2 ConfigPut

  /usr/local/openvpn_as/scripts/sacli --key vpn.server.session_ip_lock --value true ConfigPut
  /usr/local/openvpn_as/scripts/sacli --key vpn.server.lockout_policy.n_fails --value 3 ConfigPut
  /usr/local/openvpn_as/scripts/sacli --key vpn.server.lockout_policy.reset_time --value 900 ConfigPut

  echo "##################### Restart OpenVPN #####################"

  /usr/local/openvpn_as/scripts/sacli start
