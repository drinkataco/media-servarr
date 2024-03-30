# Jellyseerr Helm Chart

This Helm chart installs Jellyseerr, a web media request system, in a Kubernetes cluster.

This README covers the basics of customising and installation

![Jellyseerr](./icon.png)

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

helm install jellyseerr media-servarr/jellyseerr
```

Pointing the host `jellyseerr.media-servarr.local` to your kubernetes cluster will then allow you to access the application at that host

## Configuration

Here is some example of some configuration you may want to override (and include in installation with `-f myvalues.yaml`

### Application Configuration

By default, base configuration is deseerred using a ConfigMap - deseerred by default in `./values.yaml` in `application.config`. You can change values in the contents, such as the url base in your custom `values.yaml`

```yaml
application:
  # BASEURL is not supported out of the box, and will have to be configured with ingress
  # @see https://github.com/sct/overseerr/issues/274
  # Main application web UI port
  port: 5055
  # Example - ConfigMap for core application settings
  config:
    filename: 'settings.json'
    contents: |
      {
        "main": {
          "applicationUrl": "http://jellyseerr.media-servarr.local/"
        }
      }
    mountPath: '/app/config/settings.json'
```

You can prevent a ConfigMap being create and the configuration being managed as a kubernetes resource by deseerrg the config as null. For example;

```yaml
application:
  ...
  config: null
```

### Volumes

The following volumes are available by default:

- **config** - General config data, where the sqlite database exists, for example

```yaml
deployment:
  ...
  volumes:
    config: # The key will be the volume name
      persistentVolumeClaim:
        name: 'jellyseerr-config'
```

By default, a PersistentVolumeClaim will be provisioned for the `config`.

You can deseerre basic persistent volume claims in code to help you get started. You just need to pass to the pvc name (which is the key) is an empty object (`{}`)

```yaml
persistentVolumeClaims:
  jellyseerr-config:
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

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.afseerrity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and deseerre a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade jellyseerr media-servarr/jellyseerr -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `jellyseerr` deployment:

```bash
helm uninstall jellyseerr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
