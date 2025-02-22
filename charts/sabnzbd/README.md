# SABnzbd Helm Chart

This Helm chart installs SABnzbd, a program to download binary files from Usenet servers.

This README covers the basics of customising and installation

![SABnzbd](./icon.png)

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

helm install sabnzbd media-servarr/sabnzbd
```

Pointing the host `media-servarr.local` to your kubernetes cluster will then allow you to access the application at the default location of `http://media-servarr.local/sabnzbd/`

## Configuration

Here is some example of some configuration you may want to override (and include in installation with `-f myvalues.yaml`

### Secrets

To set up secrets, like API keys, use the following format. Use `openssl rand -hex 16` to generate a key and replace the default value.

```yaml
secrets:
  - name: 'apiKey'
    value: 'apiKey'
  - name: 'nzbKey'
    value: 'nzbKey'
  # - name: 'newsreaderServerPassword'
  #   value: 'password123'
```

If setting up a ConfigMap, you can also store any newsreader server passwords here, for example

### Application Configuration

By default, base configuration is defined using a ConfigMap - defined by default in `./values.yaml` in `application.config`.

You can also add servers here, as shown under the `[servers]` block

```yaml
application:
  port: 8080 # default UI port
  urlBase: 'sabnzbd' # default web base path
  config:
    contents: |
      [misc]
      language = en
      queue_limit = 20
      port = 8080
      api_key = $apiKey
      nzb_key = $nzbKey
      download_dir = Downloads/incomplete
      complete_dir = Downloads/complete
      # url_base = /sabnzbd # Set a base url
      # [servers]
      # [[yournewsreader.example.org]]
      # name = yournewsreader.example.org
      # displayname = yourNewsReader
      # host = yournewsreader.example.org
      # port = 563
      # username = username
      # password = $newsreaderServerPassword
      # connections = 8
      # ssl = 1
      # ssl_verify = 2
      # enable = 1
      # priority = 0
```

You can prevent a ConfigMap being create and the configuration being managed as a kubernetes resource by defing the config as null. For example;

```yaml
application:
  ...
  config: null
```

### Volumes

Three volumes are available by default:

- **config** - General config data
- **downloads** - Downloads folder, with {complete, incomplete} subdirectories

```yaml
deployment:
  ...
  volumes:
    config: # The key will be the volume name
      persistentVolumeClaim:
        name: 'sabnzbd-config'
    downloads:
      nfs:
        server: 'fileserver.local'
        path: '/srv/downloads/'
```

By default, a PersistentVolumeClaim will be provisioned for the `config`, but `emptyDir: {}` will be used for downloads, unless otherwise specified in your `values.yaml`

```yaml
persistentVolumeClaims:
  sabnzbd-config:
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

Unless changed with `metrics.port.number` you can then consume metrics over port `9707`.

### Advanced

Other supported deployment configuration include `deployment.nodeSelector`, `deployment.tolerations`, and `deployment.affinity`

You can also adjust container ports, environment variables (such as adding `PGID` and `PUID`) and define a `serviceAccount`.

Have a look at the parent charts default `values.yaml` for a comprehensive list of available config.

## Upgrading

To upgrade the deployment:

```bash
helm upgrade sabnzbd media-servarr/sabnzbd -f myvalues.yaml
```

## Uninstallation

To uninstall/delete the `sabnzbd` deployment:

```bash
helm uninstall sabnzbd
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.
