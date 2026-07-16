# media-servarr helm charts

[![Lint](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml)
[![Release](https://github.com/drinkataco/media-servarr/actions/workflows/release.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/release.yaml)
[![App Update](https://github.com/drinkataco/media-servarr/actions/workflows/auto-update.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/auto-update.yaml)

![media-servarr](./icon.png)

A collection of opinionated Helm charts for self-hosted media automation on Kubernetes. All charts share a common base (`media-servarr-base`) so configuration patterns are consistent across every application.

Covers the full [servarr](https://wiki.servarr.com/) stack — indexers, downloaders, and library managers for movies, TV, music, and books — plus supporting tools like a dashboard, subtitle manager, and media scraper.

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [The Charts](#the-charts)
* [Prerequisites](#prerequisites)
* [Usage](#usage)
* [Base Chart Features](#base-chart-features)
* [Configuration Reference](#configuration-reference)
  * [Secrets](#secrets)
  * [Application config (ConfigMap-backed)](#application-config-configmap-backed)
  * [Volumes and PersistentVolumeClaims](#volumes-and-persistentvolumeclaims)
  * [Ingress](#ingress)
  * [Metrics (Exportarr)](#metrics-exportarr)
  * [Service](#service)
  * [Service Account](#service-account)
  * [Pod scheduling](#pod-scheduling)
<!-- vim-md-toc END -->

## The Charts

| Chart | Application | Description |
|---|---|---|
| `bazarr` | [Bazarr](https://www.bazarr.media/) | Automatic subtitle downloader; companion to Sonarr and Radarr |
| `cleanuparr` | [Cleanuparr](https://cleanuparr.github.io/Cleanuparr/) | Removes stalled, orphaned, and unwanted items from download clients |
| `flaresolverr` | [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr) | Proxy to bypass Cloudflare protection; used by Prowlarr |
| `homarr` | [Homarr](https://homarr.dev/) | Dashboard for self-hosted services |
| `jellyfin` | [Jellyfin](https://jellyfin.org/) | Open-source media server for movies, TV, and music |
| `lidarr` | [Lidarr](https://lidarr.audio/) | Music library manager |
| `profilarr` | [Profilarr](https://github.com/Dictionarry-Hub/profilarr) | Quality profile and custom format manager for the *arr stack |
| `prowlarr` | [Prowlarr](https://prowlarr.com/) | Indexer manager and proxy for the *arr stack |
| `radarr` | [Radarr](https://radarr.video/) | Movie library manager |
| `readarr` _(deprecated)_ | [Readarr](https://readarr.com/) | Book library manager |
| `sabnzbd` | [SABnzbd](https://sabnzbd.org/) | Usenet download client |
| `sonarr` | [Sonarr](https://sonarr.tv/) | TV series library manager |
| `tinymediamanager` | [tinyMediaManager](https://www.tinymediamanager.org/) | Media metadata scraper and manager |
| `transmission` | [Transmission](https://transmissionbt.com) | BitTorrent download client |

Each chart has its own `README.md` under [`./charts/<name>/`](./charts) with installation and configuration details.

## Prerequisites

- Kubernetes `>=1.24`
- [Helm](https://helm.sh/) `>=3.12`
- (Optional) [Prometheus Operator](https://github.com/prometheus-operator/kube-prometheus) CRDs if enabling `metrics`

## Usage

Add the Helm repository:

```bash
helm repo add media-servarr https://media-servarr.shw.al/charts
helm repo update
```

List available charts:

```bash
helm search repo media-servarr
```

Install a chart (Sonarr as an example):

```bash
helm install sonarr media-servarr/sonarr -f my-values.yaml
```

Upgrade an existing release:

```bash
helm upgrade sonarr media-servarr/sonarr -f my-values.yaml
```

## Base Chart Features

All charts are built on the shared `media-servarr-base` library. Key capabilities:

- **Secret injection** — inline values or references to pre-existing Kubernetes Secrets; secrets can be substituted into ConfigMap-mounted config files at pod start via an init container
- **Config-as-code** — application config files are managed as ConfigMaps and mounted read-write via an init container (to satisfy apps that crash on read-only mounts)
- **PersistentVolumeClaims** — declarative PVC provisioning with support for `storageClassName`, `volumeName` (bind to a specific pre-existing PV), and label selectors
- **Ingress** — single-host ingress with optional TLS and custom annotations (compatible with Traefik, nginx, etc.)
- **Metrics / Exportarr** — optional [Exportarr](https://github.com/onedr0p/exportarr) sidecar and `ServiceMonitor` CRD for Prometheus scraping (supported on Radarr, Sonarr, Lidarr, Readarr, Prowlarr)
- **Flexible volumes** — arbitrary volume types (NFS, emptyDir, ConfigMap, PVC, etc.) via the `deployment.volumes` map; a null entry defaults to `emptyDir: {}`
- **Runtime customisation** — sidecar and init containers, node selectors, tolerations, affinity, pod/container security contexts, `runtimeClassName`, image pull secrets

A JSON Schema for all values is provided at [`values.schema.json`](./values.schema.json). Editors with the [YAML Language Server](https://github.com/redhat-developer/yaml-language-server) (VS Code, nvim, etc.) will validate your values files against it automatically via the `yaml-language-server: $schema` modeline included in every `values.yaml`.

## Configuration Reference

All top-level keys are optional unless noted. The canonical reference is [`values.yaml`](./values.yaml); what follows is a summary of the main sections.

### Secrets

```yaml
secrets:
  - name: 'apiKey'          # key name used in config substitution ($apiKey) and Secret data
    value: 'abc123'          # inline value — generates a Secret in-cluster
  # - name: 'apiKey'
  #   ref: 'my-k8s-secret'  # reference a pre-existing Secret instead
```

When `value` is set the chart creates a Kubernetes `Secret`. When `ref` is set the chart reads from a Secret you manage externally (e.g. via External Secrets Operator).

### Application config (ConfigMap-backed)

```yaml
application:
  port: 8989
  urlBase: 'sonarr'
  config:                     # null to disable ConfigMap management
    filename: 'config.xml'
    mountPath: '/config/config.xml'
    secrets: ['apiKey']       # names to substitute as $apiKey in contents
    contents: |
      <Config>
        <ApiKey>$apiKey</ApiKey>
      </Config>
```

`config` can also be a list of entries to mount multiple config files.

### Volumes and PersistentVolumeClaims

```yaml
deployment:
  volumes:
    config:                          # volume name; null → emptyDir
      persistentVolumeClaim:
        claimName: 'sonarr-config'
    media:
      nfs:
        server: fileserver
        path: /srv/media

persistentVolumeClaims:
  sonarr-config:
    storageClassName: longhorn
    accessMode: ReadWriteOnce        # singular string, not a list
    requestStorage: 5Gi
    volumeName: existing-pv-name     # optional: bind to a specific pre-existing PV
```

### Ingress

```yaml
ingress:
  enabled: true
  className: traefik
  host: example.com
  path: /sonarr                      # defaults to /urlBase
  pathType: Prefix
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  tls:
    - secretName: example-tls
      hosts: [example.com]
```

### Metrics (Exportarr)

Supported on: Radarr, Sonarr, Lidarr, Readarr, Prowlarr.

```yaml
metrics:
  enabled: true
  app: sonarr                        # which *arr app to scrape
  # apiref:                          # omit to use this chart's own apiKey secret
  #   secret: my-existing-secret
  #   keyname: apiKey
```

Requires Prometheus Operator CRDs (`ServiceMonitor`). Install [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) first.

### Service

```yaml
service:
  type: ClusterIP                    # ClusterIP | NodePort | LoadBalancer | ExternalName
  # externalTrafficPolicy: Local     # NodePort/LoadBalancer only
  annotations: {}
```

### Service Account

```yaml
serviceAccount:
  create: false
  automount: true
  name: default
  imagePullSecrets:
    - name: my-registry-secret
```

### Pod scheduling

```yaml
deployment:
  runtimeClassName: nvidia
  nodeSelector:
    kubernetes.io/arch: amd64
  tolerations:
    - key: gpu
      operator: Exists
  affinity:
    nodeAffinity: {}
  podSecurityContext:
    fsGroup: 1000
```
