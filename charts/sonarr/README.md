# Sonarr Helm Chart

This Helm chart installs Sonarr, a movie collection manager, in a Kubernetes cluster.

This README covers the basics of customising and installation

![Sonarr](./icon.png)

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Installation](#installation)
* [Configuration](#configuration)
  * [Secrets](#secrets)
  * [Application Configuration](#application-configuration)
  * [Volumes](#volumes)
  * [Ingress Configuration](#ingress-configuration)
  * [Advanced](#advanced)
* [Upgrading](#upgrading)
* [Uninstallation](#uninstallation)
* [Support](#support)
<!-- vim-md-toc END -->

## Installation

Install this helm chart using the following command:

```bash
helm repo add mediar-servarr https://media-servarr.p.shw.al/charts

helm install sonarr media-servarr/sonarr -f myvalues.yaml -f mysecrets.yaml
```

## Configuration

Here is some example of some configuration you may want to override.

### Secrets

To set up secrets, like API keys, use the following format. Use `openssl rand -hex 16` to generate a key and replace the default value.

```yaml
secrets:
  - name: 'apiKey'
    value: 'your-api-key-here'
```

By not setting this value, and leaving it blank, Sonarr will automatically generate a key on start.

### Application Configuration

By default, base configuration is defined using a ConfigMap - defined by default in `./values.yaml` in `application.config`. You can change values in the contents, such as the url base in your custom `values.yaml`

```yaml
application:
  config:
    filename: 'config.xml'
    contents: |
      <Config>
        <UrlBase>tv</UrlBase>
        <ApiKey>$apiKey</ApiKey>
      </Config>
    secrets: [ 'apiKey' ]
    mountPath: '/config/config.xml'
```

You can prevent a ConfigMap being create and the configuration being managed as a kubernetes resource by defing the config as null. For example;

```yaml
application:
  config: null
```

### Volumes

Three volumes are available by default:

- **config** - General config data, where the sqlite database exists, for example
- **downloads** - Downloads folder for monitoring
- **tv** - Location of television shows


```yaml
deployment:
  ...
  volumes:
    config: # The key will be the volume name
      persistentVolumeClaim:
        name: 'sonarr-config'
    downloads:
      nfs:
        server: 'fileserver.local'
        path: '/srv/downloads/'
    tv:
      nfs:
        server: 'fileserver.local'
        path: '/srv/media/tv/'
```

By default, a PersistentVolumeClaim will be provisioned for the `config`, but `emptyDir: {}` will be used for downloads and tv - but it is recommended enable some type of PVC and PV!

It is highly recommended that you do not use NFS for your config volume - because of the loose implementation of NFS protocol that causes issue with file locking causing detrimental effects on the SQlite database.

You can define basic persistent volume claims in code to help you get started. You just need to pass to the pvc name (which is the key) is an empty object (`{}`)

```yaml
persistentVolumeClaims:
  sonarr-config:
    accessMode: 'ReadWriteOnce'
    requestStorage: '1Gi'
    storageClassName: 'manual'
    selector:
      matchLabels:
        type: 'local'
```

### Ingress Configuration

If ingress is enabled, you can customise the host, paths, and TLS settings:

```yaml
ingress:
  enabled: true
  hosts:
    - host: 'mymedia.example.com'
      paths:
        - path: '/sonarr/'
          pathType: 'ImplementationSpecific'
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
helm upgrade sonarr media-servarr/sonarr -f myvalues.yaml -f mysecrets.yaml
```

## Uninstallation

To uninstall/delete the `my-sonarr` deployment:

```bash
helm delete sonarr
```

## Support

For support, issues, or feature requests, please file an issue on the chart's repository issue tracker.

