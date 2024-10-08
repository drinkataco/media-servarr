# Routing Traffic through a VPN

Here is a guide how you can route all of your torrent traffic through a VPN for transmission in kubernetes.

This guide uses [gluetun](https://github.com/qdm12/gluetun) to simplify the process of forwarding traffic from your transmission container.

It is heavily recommended to use a VPN such as [ProtonVPN](https://protonvpn.com/) that supports Port Forwarding!

Configuring Gluetun will be slightly different for everybody, so please referr to their documentation along the way.

## Configuration

All configuration can be applied within your `values.yaml` file used for provisioning resources from this helm chart.

### Transmission

First, we must add a securityContext to transmission so that it can perform network-related administrative tasks alongside gluetun.

```yaml
deployment:
  container:
    securityContext:
      - 'NET_ADMIN'
```

### Gluetun

We'll need to add a sidecar container to run Gluetun, with the same security context.

Configuration specifics, in terms of environment variables, will be different for everybody. Consult the [Gluetun Wiki](https://github.com/qdm12/gluetun-wiki/)!

```yaml
deployment:
   ...
   sideCarContainers:
    - name: 'gluetun'
      image: 'qmcgaw/gluetun'
      ports:
        - containerPort: 8000
      securityContext:
        capabilities:
          add:
            - 'NET_ADMIN'
      env:
        # VPN connection
        #  This is different depending on your provider. Consult Gluetun documentation
        - name: 'VPN_SERVICE_PROVIDER'
          value: 'protonvpn'
        - name: 'VPN_TYPE'
          value: 'wireguard'
        - name: 'WIREGUARD_PRIVATE_KEY'
          value: ''
        - name: 'SERVER_COUNTRIES'
          value: 'United Kingdom'
        # Port Forwarding
        #  A port
        - name: 'VPN_PORT_FORWARDING'
          value: 'on'
        - name: 'PORT_FORWARD_ONLY'
          value: 'on'
        # Kubernetes specific config:
        # DNS
        - name: 'DNS_KEEP_NAMESERVER'
          value: 'on'
        # FIREWALL
        - name: 'FIREWALL_OUTBOUND_SUBNETS'
          value: '10.42.0.0/15'
```

## Deployment

By adding these two items deploying your helm chart should now enable Transmission traffic to flow through your chosen VPN provider!

Verify your setup with these commands:

```bash
# Verify your allocated IP in Gluetun
kubectl exec -it \
  <transmission_pod> \
  --container gluetun \
  -- cat /tmp/gluetun/ip

# Verify your assigned forwarded port in Gluetun
kubectl exec -it \
  <transmission_pod> \
  --container gluetun \
  -- cat /tmp/gluetun/forwarded_port

# Verify your IP address in Transmission
kubectl exec -it \
  <transmission_pod> \
  --container transmission \
  -- curl ifconfig.me
```

Within the transmission UI, it is worth updating your peer port by going to _Menu_ > _Edit Preferences_ > _Network_, and the portchecker should verify this is an open port.

> [!NOTE]
> Assigned forwarded ports are random each time, so you must update the peer port from the UI. Alternatively, you could add [another sidecar to automate this process](#auto-update-peer-port) for you

## Bonus

### Auto update peer port

It can get a bit annoying managing the peer port manually through the transmission UI due to this port being random each time.

A way around this is by adding another sidecar with a bash script to automate this process for you! It uses the [Gluetun Control Server](https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/control-server.md) and [Transmission RPC](https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md) to achieve this.

The following sidecar container achieves this by:

1. Fetching the SESSION ID from Transmission
1. Fetching the allocated port from Gluetun
1. Updating the Peer Port on Transmission via RPC
1. Repeating every two minutes

```yaml
deployment:
  ...
  sideCarContainers:
    ...
    - name: 'update-peer-port'
      image: 'alpine:latest'
      command:
        - '/bin/sh'
        - '-c'
        - |
          # Add dependencies
          echo "nameserver 8.8.8.8" > /etc/resolv.conf # allow quick resolution
          apk update
          apk add --no-cache jq curl

          # Transmission RPC URL
          TRANSMISSION_URL="http://localhost:9091/transmission/rpc/"
          # Gluetun Control Server URL
          GLUETUN_URL="http://localhost:8000/v1"
          # Initial Transmission RPC request with an invalid session ID to start
          SESSION_ID=""
          # How quickly to retry after a failure 
          ERROR_RETRY_S=60 
          # How often to check for updated ports
          UPDATE_CHECK_S=120

          log() {
            echo "[$(date)] $1"
          }

          err() {
            echo "[$(date)] [ERROR] $1" 1>&2
          }

          while true; do
            echo "[$(date)] Fetching Transmission Session ID"
            SESSION_ID=$(curl -s -X POST "$TRANSMISSION_URL" \
              -H "Content-Type: application/json" \
              -d "{\"arguments\":{\"peer-port\":$PORT},\"method\":\"session-set\"}" \
              | sed -n 's/.*X-Transmission-Session-Id: \([^<]*\).*/\1/p')

            if [ -z "$SESSION_ID" ]; then
              err "Session ID not found. Trying again in ${ERROR_RETRY_S}s"
              sleep $ERROR_RETRY_S
              continue
            fi

            log "Transmission Session ID: $SESSION_ID"

            while true; do
              log 'Fetching port from Gluetun'

              PORT=$(curl -s "${GLUETUN_URL}/openvpn/portforwarded" | jq -r '.port')

              if [ -z "$PORT" ]; then
                err "Port forward not found. Trying again in ${ERROR_RETRY_S}s"
                sleep $ERROR_RETRY_S
                continue
              fi

              log "Gluetun forwarding Port: ${PORT}"
              log "Sending request to Transmission RPC..."

              RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -X POST "$TRANSMISSION_URL" \
                 -H "Content-Type: application/json" \
                 -H "X-Transmission-Session-Id: $SESSION_ID" \
                 -d "{\"arguments\":{\"peer-port\":$PORT},\"method\":\"session-set\"}")

              if [ "$RESPONSE" = "200" ]; then
                log "Transmission RPC request successful. Peer port updated to $PORT."
              elif [ "$RESPONSE" = "409" ]; then
                err 'Received 409 Conflict. Fetching new Transmission session ID...'
                break
              else
                err "Unexpected response: $RESPONSE from Transmission. Trying again in ${ERROR_RETRY_S}s"
                sleep $ERROR_RETRY_S
                continue
              fi

              log "Updating again in ${UPDATE_CHECK_S}s"
              sleep $UPDATE_CHECK_S
            done
          done
```
