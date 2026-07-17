# media-servarr helm charts

[![Lint](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml)
[![Release](https://github.com/drinkataco/media-servarr/actions/workflows/release.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/release.yaml)
[![App Update](https://github.com/drinkataco/media-servarr/actions/workflows/auto-update.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/auto-update.yaml)

![media-servarr](./icon.png)

A collection of Helm charts for self-hosted media - primarily built around the [Servarr](https://wiki.servarr.com/) family of charts, with some complementary charts here and there.

All charts share the common base (`media-servarr-base`) so configuration patterns are consistent across every application.

* [The Charts](#the-charts)
* [Prerequisites](#prerequisites)
* [Usage](#usage)
* [Base Chart Features](#base-chart-features)
* [Configuration](#configuration)

## The Charts

| Chart | Application | Description |
|---|---|---|
| [`bazarr`](./charts/bazarr) | [Bazarr](https://www.bazarr.media/) | Automatic subtitle downloader; companion to Sonarr and Radarr |
| [`cleanuparr`](./charts/cleanuparr) | [Cleanuparr](https://cleanuparr.github.io/Cleanuparr/) | Removes stalled, orphaned, and unwanted items from download clients |
| [`flaresolverr`](./charts/flaresolverr) | [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr) | Proxy to bypass Cloudflare protection; used by Prowlarr |
| [`homarr`](./charts/homarr) | [Homarr](https://homarr.dev/) | Dashboard for self-hosted services |
| [`jellyfin`](./charts/jellyfin) | [Jellyfin](https://jellyfin.org/) | Open-source media server for movies, TV, and music |
| [`lidarr`](./charts/lidarr) | [Lidarr](https://lidarr.audio/) | Music library manager |
| [`profilarr`](./charts/profilarr) | [Profilarr](https://github.com/Dictionarry-Hub/profilarr) | Quality profile and custom format manager for the *arr stack |
| [`prowlarr`](./charts/prowlarr) | [Prowlarr](https://prowlarr.com/) | Indexer manager and proxy for the *arr stack |
| [`radarr`](./charts/radarr) | [Radarr](https://radarr.video/) | Movie library manager |
| [`readarr`](./charts/readarr) _(deprecated)_ | [Readarr](https://readarr.com/) | Book library manager |
| [`sabnzbd`](./charts/sabnzbd) | [SABnzbd](https://sabnzbd.org/) | Usenet download client |
| [`sonarr`](./charts/sonarr) | [Sonarr](https://sonarr.tv/) | TV series library manager |
| [`tinymediamanager`](./charts/tinymediamanager) | [tinyMediaManager](https://www.tinymediamanager.org/) | Media metadata scraper and manager |
| [`transmission`](./charts/transmission) | [Transmission](https://transmissionbt.com) | BitTorrent download client |

Each chart has its own `README.md` under [`./charts/<name>/`](./charts) with per-app installation and configuration details.

## Prerequisites

- Kubernetes `>=1.24`
- [Helm](https://helm.sh/) `>=3.12`
- (Optional) [Prometheus Operator](https://github.com/prometheus-operator/kube-prometheus) CRDs if enabling `metrics` where available (see [exportarr](https://github.com/onedr0p/exportarr))

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
- **PersistentVolumeClaims** — declarative PVC provisioning with `storageClassName`, label selectors, and `volumeName` for binding to a pre-existing PV
- **Ingress** — single-host ingress with optional TLS and custom annotations (compatible with Traefik, nginx, etc.)
- **Metrics / Exportarr** — optional [Exportarr](https://github.com/onedr0p/exportarr) sidecar and `ServiceMonitor` CRD for Prometheus scraping (Radarr, Sonarr, Lidarr, Readarr, Prowlarr)
- **Flexible volumes** — arbitrary volume types (NFS, emptyDir, ConfigMap, PVC, etc.) via the `deployment.volumes` map
- **Runtime customisation** — sidecar and init containers, node selectors, tolerations, affinity, pod/container security contexts, `runtimeClassName`, image pull secrets

## Configuration

For the full list of value keys, their types, and inline documentation:

- **Per-chart guides** — each chart has its own [`README.md`](./charts) with an installation walkthrough and worked examples.
- **JSON Schema** — [`values.schema.json`](./values.schema.json) validates every value path. Editors with the [YAML Language Server](https://github.com/redhat-developer/yaml-language-server) pick it up automatically via the modeline at the top of each `values.yaml`.
- **Default values** — [`values.yaml`](./values.yaml) is the canonical reference for defaults and shape.

The most distinctive pattern in this repo is **config-as-code with secret substitution**: application config lives in `values.yaml`, gets rendered to a ConfigMap, and secrets are substituted at pod start:

```yaml
secrets:
  - name: apiKey
    value: 'abc123'          # or: ref: 'my-existing-secret'

application:
  config:
    filename: config.xml
    mountPath: /config/config.xml
    secrets: [apiKey]        # substituted as $apiKey in contents
    contents: |
      <Config>
        <ApiKey>$apiKey</ApiKey>
      </Config>
```
