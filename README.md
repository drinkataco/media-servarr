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
* [Configuration](#configuration)
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

Each chart has its own `README.md` under [`./charts/<name>/`](./charts) with per-app installation and configuration details.

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
