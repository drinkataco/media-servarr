# Homarr Helm Chart

This Helm chart installs Homarr, a server dashboard, in a Kubernetes cluster.

This README covers the basics of customising and installation

![Homarr](./icon.png)

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
helm repo add mediar-servarr https://media-servarr.shw.al/charts

helm install homarr media-servarr/homarr
```

Pointing the host `media-servarr.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://media-servarr.local/homarr/`

## Configuration

Here is some example of some configuration you may want to override (and include in installation with `-f myvalues.yaml`

### Application Configuration

You can change the default port in the application config

```yaml
application:
  port: 7575
```

### Volumes

Three volumes are available by default:

- **app-data-configs** - Dashboard files
- **data** - Homarr data
- **app-data-icons** - Icons

```yaml
deployment:
  ...
  volumes:
    # Dashboard (config) files
    app-data-configs:
      persistentVolumeClaim:
        name: 'my-pv-claim1'
    # Dashboard Icons
    app-data-icons:
      # Example direct NFS mount without need for PV
      nfs:
        server: 'fileserver'
        path: '/srv/homarr/icons'
```

By default, a PersistentVolumeClaim will be provisioned for the `data`, but `emptyDir: {}` will be used for config and icons, unless otherwise specified in your `values.yaml`

```yaml
persistentVolumeClaims:
  # Default PV is for 'data' where the SQlite database exists
  data:
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

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade homarr media-servarr/homarr -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `homarr` deployment:

```bash
helm uninstall homarr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
