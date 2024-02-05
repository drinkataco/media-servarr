# media-servarr helm charts

[![Lint](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml)
[![Release](https://github.com/DiceTechnology/drinkataco/media-servarr/workflows/release.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/package.yaml)

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

There are a number of charts available under the [./charts](./charts) directory for the following applications:

- Radarr - [radarr.video](https://radarr.video/)
- Sonarr - [sonarr.tv](https://sonarr.tv/)
- Lidarr - [lidarr.audio](https://lidarr.audio/)
- Readarr - [readarr.com](https://readarr.com/)
- Prowlarr - [prowlarr.com](https://prowlarr.com/)
- Transmission - [transmissionbt.com](https://transmissionbt.com)
- Homarr - [homarr.dev](https://homarr.dev/)

It will be helpful to check out each application in [./charts](./charts) and its README for more information.

The [media-servarr](./charts/media-servarr/) chart allows you to install and manage all the applications in one installation - and coordinate extras, such as shared persistent volumes and network policies.

