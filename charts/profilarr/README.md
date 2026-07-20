# Profilarr Helm Chart

This Helm chart installs Profilarr, a configuration management platform for Radarr and Sonarr, in a Kubernetes cluster.

This README covers the basics of customising and installation

![Profilarr](./icon.png)

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Installation](#installation)
* [Configuration](#configuration)
  * [Application Configuration](#application-configuration)
  * [Volumes](#volumes)
  * [Ingress](#ingress)
  * [Advanced](#advanced)
* [Upgrading](#upgrading)
* [Uninstallation](#uninstallation)
* [Support](#support)
<!-- vim-md-toc END -->

## Installation

Install this helm chart using the following command:

```bash
helm repo add media-servarr https://media-servarr.shw.al/charts

helm install profilarr media-servarr/profilarr
```

By default, this chart exposes Profilarr at `http://profilarr.local/`

## Configuration

Here are some examples of configuration you may want to override (and include in installation with `-f myvalues.yaml`).

### Application Configuration

Profilarr is configured primarily through environment variables. The upstream quick-start only requires a `/config` volume and port `6868`.

```yaml
application:
  port: 6868

deployment:
  container:
    env:
      - name: 'TZ'
        value: 'UTC'
```

### Volumes

One volume is available by default:

- **config** - Profilarr configuration, database, and git working data

```yaml
deployment:
  ...
  volumes:
    config:
      persistentVolumeClaim:
        claimName: 'profilarr-config'
```

By default, a PersistentVolumeClaim will be provisioned for `config` unless otherwise specified in your `values.yaml`

```yaml
persistentVolumeClaims:
  profilarr-config:
    accessMode: 'ReadWriteOnce'
    requestStorage: '5Gi'
    storageClassName: 'manual'
    # volumeName: 'existing-pv-name'  # optional: bind this PVC to a specific pre-existing PV
    selector:
      matchLabels:
        type: 'local'
```

### Ingress

Profilarr is best exposed on a dedicated host at `/`, rather than under a shared path prefix. Upstream still has an open request for custom host/port binding support, so this chart defaults to a dedicated host and root path.

```yaml
ingress:
  enabled: true
  host: 'profilarr.example.com'
  path: '/'
  tls:
    # Your TLS settings...
```

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables, and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade profilarr media-servarr/profilarr -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `profilarr` deployment:

```bash
helm uninstall profilarr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.

