# media-servarr helm charts

[![Lint](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml)
[![Release](https://github.com/drinkataco/media-servarr/actions/workflows/release.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/release.yaml)

> [!WARNING]
> The charts and their definitions are in the Alpha stage and will remain so until they reach the first major version release (1.x.x).
> It is important to note that there may be breaking changes introduced, especially around values, with each minor updater until then.

![media-servarr](./icon.png)

This repository contains a collection of similar applications under the [servarr](https://wiki.servarr.com/) family.

The aim of this repository is to be featureful, use repeatable code, and to be a testbed for me to play with a kubernetes helm chart.

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Usage](#usage)
* [The Charts](#the-charts)
<!-- vim-md-toc END -->

## Usage

Add the repository using:

```bash
helm repo add mediar-servarr https://media-servarr.shw.al/charts
```

And then view all available charts with

```bash
helm search repo media-servarr
```

## The Charts

There are a number of charts available under the [./charts](./charts)

An example of some of the supported charts:

- Radarr - [radarr.video](https://radarr.video/)
- Sonarr - [sonarr.tv](https://sonarr.tv/)
- Lidarr - [lidarr.audio](https://lidarr.audio/)
- Readarr - [readarr.com](https://readarr.com/)
- Prowlarr - [prowlarr.com](https://prowlarr.com/)
- Transmission - [transmissionbt.com](https://transmissionbt.com)
- Homarr - [homarr.dev](https://homarr.dev/)

It will be helpful to check out all available application in [./charts](./charts) and its README for more information.

The [media-servarr](./charts/media-servarr/) chart allows you to install and manage all the applications in one installation - and coordinate extras, such as shared persistent volumes and network policies.

