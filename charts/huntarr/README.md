# Huntarr Helm Chart

This Helm chart installs Huntarr, a companion application for [Radarr](../radarr/), [Lidarr](../lidarr/), and [Sonarr](../sonarr/) to search for quality upgrades.

This README covers the basics of customising and installation

![Huntarr](./icon.png)

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Installation](#installation)
* [Configuration](#configuration)
  * [Secrets](#secrets)
  * [Application Configuration](#application-configuration)
  * [Volumes](#volumes)
  * [Ingress](#ingress)
  * [Metrics](#metrics)
  * [Advanced](#advanced)
* [Upgrading](#upgrading)
* [Uninstallation](#uninstallation)
* [Support](#support)
<!-- vim-md-toc END -->

## Installation

Install this helm chart using the following command:

```bash
helm repo add mediar-servarr https://media-servarr.shw.al/charts

helm install huntarr media-servarr/huntarr
```

Pointing the host `media-servarr.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://media-servarr.local/huntarr/`

## Configuration

Here is some example of some configuration you may want to override (and include in installation with `-f myvalues.yaml`

### Application Configuration

Application configuration is managed via the GUI and stored in the application database.

### Volumes

A volume is included just for configuration:

- **config** - General config data, where the sqlite database exists, for example

```yaml
deployment:
  ...
  volumes:
    config: # The key will be the volume name
      persistentVolumeClaim:
        name: 'huntarr-config'
```

By default, a PersistentVolumeClaim will be provisioned for the `config` named `huntarr-config`.

```yaml
persistentVolumeClaims:
  cleanuparr-config:
    accessMode: 'ReadWriteOnce'
    requestStorage: '1Gi'
    storageClassName: 'manual'
    selector:
      matchLabels:
        type: 'local'
```

### Ingress

Ingress can be enabled, and you can customise the default host, path, and TLS settings:

```yaml
ingress:
  enabled: true
  host: 'example.com'
  tls:
    # Your TLS settings...
```

### Metrics

Metrics are not supported for this application.

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade huntarr media-servarr/huntarr -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `huntarr` deployment:

```bash
helm uninstall huntarr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
