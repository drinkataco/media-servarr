# Bazarr Helm Chart

This Helm chart installs Bazarr, a companion application for [Radarr](../radarr/) and [Sonarr](../sonarr/) to manage and download subtitles

This README covers the basics of customising and installation

![Bazarr](./icon.png)

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

helm install bazarr media-servarr/bazarr
```

Pointing the host `media-servarr.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://media-servarr.local/bazarr/`

## Configuration

Here is some example of some configuration you may want to override (and include in installation with `-f myvalues.yaml`

### Secrets

To set up secrets, like API keys, use the following format.

Use `openssl rand -hex 16` to generate a key and replace the default value. If using a ConfigMap to manage configuration, you can also set various other secrets here too - such as service passwords, or sonarr and radarr API keys.

```yaml
secrets:
  - name: 'apiKey'
    value: 'your-api-key-here'
  - name: 'sonarrApiKey'
    value: ''
  - name: 'radarrApiKey'
    value: ''
```

By not setting this value, and leaving it blank, Bazarr will automatically generate a new key on start.

### Application Configuration

By default, base configuration is defined using a ConfigMap - defined by default in `./values.yaml` in `application.config`. You can change values in the contents, such as the url base in your custom `values.yaml`.

The list of configurable items is extensive. You can configure service providers directly here, for example. Only a selection of core settings are included in the existing ConfigMap in [values.yaml](values.yaml) - But an exhaustive list is included in [config.example.yaml](./config.example.yaml)

The following example expects to have secrets set up for Radarr and Sonarr API keys for secret injection:

```yaml
application:
  port: 8686 # default UI port
  urlBase: 'radarr' # default web base path
  config:
    contents: |
      general:
        adaptive_searching: true
        auto_update: false
        base_url: '/bazarr'
        port: 6767
        use_radarr: false
        use_sonarr: false
        radarr:
          apiKey: '$radarrApiKey'
          base_url: '/radarr'
          ip: 'radarr.media-servarr.svc.cluster.local'
          port: 7878
        sonarr:
          apiKey: '$sonarrApiKey'
          base_url: '/sonarr'
          ip: 'sonarr.media-servarr.svc.cluster.local'
          port: 8989
    # Secrets to inject the config they must be defined as $secret
    secrets:
      - 'apiKey'
      - 'sonarrApiKey'
      - 'radarrApiKey'
```

You can prevent a ConfigMap being create and the configuration being managed as a kubernetes resource by defing the config as null. For example;

```yaml
application:
  ...
  config: null
```

### Volumes

A volume is included just for configuration:

- **config** - General config data, where the sqlite database exists, for example

```yaml
deployment:
  ...
  volumes:
    config: # The key will be the volume name
      persistentVolumeClaim:
        name: 'bazarr-config'
```

By default, a PersistentVolumeClaim will be provisioned for the `config`

It is highly recommended that you do not use NFS for your config volume - because of the loose implementation of NFS protocol that causes issue with file locking causing detrimental effects if using a SQlite database.

You can define basic persistent volume claims in code to help you get started. You just need to pass to the pvc name (which is the key) is an empty object (`{}`)

```yaml
persistentVolumeClaims:
  bazarr-config:
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

Unless changed with `metrics.port.number` you can then consume metrics over port `9702`.

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade bazarr media-servarr/bazarr -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `bazarr` deployment:

```bash
helm uninstall bazarr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
