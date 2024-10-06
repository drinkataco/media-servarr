# Radarr Helm Chart

This Helm chart installs Radarr, a movie collection manager, in a Kubernetes cluster.

This README covers the basics of customising and installation

![Radarr](./icon.png)

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

helm install radarr media-servarr/radarr
```

Pointing the host `media-servarr.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://media-servarr.local/radarr/`

## Configuration

Here is some example of some configuration you may want to override (and include in installation with `-f myvalues.yaml`

### Secrets

To set up secrets, like API keys, use the following format. Use `openssl rand -hex 16` to generate a key and replace the default value.

```yaml
secrets:
  - name: 'apiKey'
    value: 'your-api-key-here'
```

By not setting this value, and leaving it blank, Radarr will automatically generate a key on start.

### Application Configuration

By default, base configuration is defined using a ConfigMap - defined by default in `./values.yaml` in `application.config`. You can change values in the contents, such as the url base in your custom `values.yaml`

```yaml
application:
  port: 7878 # default UI port
  urlBase: 'radarr' # default web base path
  config:
    contents: |
      <Config>
        ...
        <UrlBase>radarr</UrlBase>
        <ApiKey>$apiKey</ApiKey>
        <Port>7878</Port>
        ...
      </Config>
```

You can prevent a ConfigMap being create and the configuration being managed as a kubernetes resource by defing the config as null. For example;

```yaml
application:
  ...
  config: null
```

### Volumes

Three volumes are available by default:

- **config** - General config data, where the sqlite database exists, for example
- **downloads** - Downloads folder for monitoring
- **film** - Location of films

```yaml
deployment:
  ...
  volumes:
    config: # The key will be the volume name
      persistentVolumeClaim:
        name: 'radarr-config'
    downloads:
      nfs:
        server: 'fileserver.local'
        path: '/srv/downloads/'
    film:
      nfs:
        server: 'fileserver.local'
        path: '/srv/media/film/'
```

By default, a PersistentVolumeClaim will be provisioned for the `config`, but `emptyDir: {}` will be used for downloads, and film, unless otherwise specified in your `values.yaml`

```yaml
persistentVolumeClaims:
  radarr-config:
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

Enabling metrics enables a sidecar container being attached for [exportarr](https://github.com/onedr0p/exportarr/) - and a ServiceMonitor CRD to be consumed by the [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) package.

```yaml
metrics:
  enabled: true
  env: []
```

It is recommended to install [kube-prometheus chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) first for the CRD to be supported. It is not included as a dependency by default in this package!

Unless changed with `metrics.port.number` you can then consume metrics over port `9704`.

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade radarr media-servarr/radarr -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `radarr` deployment:

```bash
helm uninstall radarr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
