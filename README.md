# media-servarr helm charts

[![Lint](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/lint.yaml)
[![Release](https://github.com/drinkataco/media-servarr/actions/workflows/release.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/release.yaml)
[![App Update](https://github.com/drinkataco/media-servarr/actions/workflows/auto-update.yaml/badge.svg)](https://github.com/drinkataco/media-servarr/actions/workflows/auto-update.yaml)

![media-servarr](./icon.png)

This repository contains a collection of similar applications under the [servarr](https://wiki.servarr.com/) family, and some other useful related applications.

The aim of this repository is to be featureful, use repeatable code, and to be a testbed for me to play with a kubernetes helm chart.

<!-- vim-md-toc format=bullets ignore=^TODO$ -->
* [Usage](#usage)
* [The Charts](#the-charts)
<!-- vim-md-toc END -->

## Usage

Add the repository using:

```bash
helm repo add media-servarr https://media-servarr.shw.al/charts
```

And then view all available charts with

```bash
helm search repo media-servarr
```

## The Charts

There are a number of charts available under the [./charts](./charts) - each with indiviual README instructions to help you get started.

- Bazarr - [bazarr.media](https://www.bazarr.media/)
- Cleanuparr - [cleanuparr.github.io](https://cleanuparr.github.io/Cleanuparr/)
- Flaresolverr - [Flaresolverr/Flaresolverr](https://github.com/FlareSolverr/FlareSolverr)
- Huntarr - [huntarr.io](https://huntarr.io)
- Homarr - [homarr.dev](https://homarr.dev/)
- Jellyfin - [jellyfin.org](https://jellyfin.org/)
- Lidarr - [lidarr.audio](https://lidarr.audio/)
- Prowlarr - [prowlarr.com](https://prowlarr.com/)
- Radarr - [radarr.video](https://radarr.video/)
- Readarr [DEPRECATED] - [readarr.com](https://readarr.com/)
- Sabnzbd - [sabnzbd.org](https://sabnzbd.org/)
- Sonarr - [sonarr.tv](https://sonarr.tv/)
- Transmission - [transmissionbt.com](https://transmissionbt.com)
