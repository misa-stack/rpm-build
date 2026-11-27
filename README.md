# Zen Browser RPM for Fedora

I originally made this project for my dad so he could install Zen Browser on Fedora without having to deal with tar archives or manually setting up the browser every time there is an update.

I also wanted to learn how RPM packaging, GitHub Actions and Linux package repositories actually work, so I decided to compile Zen from source and package it myself instead of just repackaging the official binaries.

This is a small personal project, not an official Zen Browser repository.

## Current state

- [x] Compile Zen from upstream source on GitHub Actions.
- [x] Build an RPM for Fedora 44 (x86_64).
- [x] Manual RPM installation on Fedora (tested).
- [x] Publish a public GitHub Pages repository with DNF metadata.
- [x] Automatically trigger publishing when a build finishes; skip failed builds.
- [x] Detect the latest upstream Zen release and automatically dispatch a build.
- [x] Add hourly release checks and an authenticated webhook-compatible trigger.
- [ ] Verify Fedora 45 compilation after the LLVM dependency fix.
- [ ] Verify successful automatic deployment of both Fedora repositories.
- [ ] Verify public DNF installation on Fedora 44 and 45.
- [ ] Verify an upgrade from an older Zen RPM to a new release using DNF.

The first automated release check successfully requested Zen `1.24.3b` ([logs](https://github.com/misa-stack/rpm-build/actions/runs/45969636050)). The new [Fedora 44/45 build](https://github.com/misa-stack/rpm-build/actions/runs/45969650053) is pending verification. An earlier Fedora 45 build failed because `llvm-config` was missing; LLVM and Clang development packages have since been added.

Packages are unsigned. This is intended for personal use; only install them if you trust the build and hosting environment.

## Manual installation (working on Fedora 44)

Download the artifact matching your Fedora version from a successful [build on GitHub Actions](https://github.com/misa-stack/rpm-build/actions/workflows/build.yml): `zen-browser-rpm-fc44` or `zen-browser-rpm-fc45` (Fedora 45 pending validation). Extract the ZIP and run:

```bash
sudo dnf install ./zen-browser-*.rpm
```

For example, download the verified Fedora 44 build using GitHub CLI (requires authentication):

```bash
gh run download 45905547896 --repo misa-stack/rpm-build --name zen-browser-rpm-fc44
sudo dnf install ./zen-browser-*.rpm
```

Actions artifacts expire after 30 days; use the latest successful build when this example expires.

## DNF repository (work in progress)

The goal is to configure the repository once and update Zen with the rest of the system.

Repository: https://misa-stack.github.io/rpm-build/

Once the new deployment passes its installation tests, run on Fedora 44 or 45 (x86_64):

```bash
sudo curl -fsSL https://misa-stack.github.io/rpm-build/zen-browser.repo \
  -o /etc/yum.repos.d/zen-browser.repo
sudo dnf makecache --refresh
sudo dnf install zen-browser
```

For normal updates:

```bash
sudo dnf upgrade
```

DNF uses `$releasever/$basearch` to select the matching repository. If the repository fails to load, check the metadata directly:

```bash
curl -fI "https://misa-stack.github.io/rpm-build/$(rpm -E %fedora)/$(uname -m)/repodata/repomd.xml"
```

The repository disables package and metadata signature verification only for Zen. Other Fedora versions and architectures are not supported. Until public installation has been verified, use manual RPM installation.

## How it works

1. [`check-release.yml`](.github/workflows/check-release.yml) checks Zen's official GitHub Releases API every hour at minute 17 UTC. It compares the latest release with the published version marker and checks both Fedora repository metadata files. It skips active builds and publishing runs, reuses successful build artifacts when available, and waits at least six hours before retrying a failed attempt for the same release.
2. [`build.yml`](.github/workflows/build.yml) runs parallel Fedora 44 and 45 Docker builds on GitHub Actions.
3. [`build.sh`](build.sh) downloads the selected upstream release and compiles it with Zen's Surfer tooling and Mozilla's mach build system.
4. [`zen-browser.spec`](zen-browser.spec) packages the compiled browser into an RPM using `rpmbuild`. Each Fedora build uploads its own artifact.
5. [`publish.yml`](.github/workflows/publish.yml) triggers after successful builds, validates the two RPMs, generates DNF metadata with `createrepo_c`, tests local installation, deploys to GitHub Pages and tests public installation. The site includes `version.txt` containing the published upstream tag.

```text
Official Zen releases
    |
    v
Hourly release check
    |
    v
GitHub Actions (Fedora 44 and 45 in parallel)
    |
    v
Surfer / mach -> rpmbuild
    |
    v
RPM artifacts
    |
    v
createrepo_c -> DNF tests -> GitHub Pages
    |
    v
Public DNF repository
```

## Manual triggers

Check for releases now, without waiting for the hourly schedule:

```bash
gh workflow run check-release.yml --repo misa-stack/rpm-build
```

Build an explicit Zen version:

```bash
gh workflow run build.yml --repo misa-stack/rpm-build -f version=1.24.3b
```

The release checker also accepts an authenticated `repository_dispatch` event of type `zen-release`:

```bash
gh api --method POST repos/misa-stack/rpm-build/dispatches -f event_type=zen-release
```

This is a webhook-compatible entry point, not an upstream webhook subscription. Registering a real release webhook on Zen's repository would require permission from its maintainers. Hourly polling works without their involvement or an external server.

## Credits

All credit for the browser itself goes to the [Zen Browser](https://github.com/zen-browser/desktop) and Mozilla developers. This project only provides an unofficial RPM build and packaging workflow.

<!-- README mascot -->
<p align="center">
  <a href="https://commons.wikimedia.org/wiki/File:Cute-girl.svg">
    <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Cute-girl.svg/500px-Cute-girl.svg.png" alt="Anime girl with a tablet" width="220">
  </a>
  <br>
  <sub>Art by <a href="https://commons.wikimedia.org/wiki/File:Cute-girl.svg">bogdan</a> · <a href="https://creativecommons.org/publicdomain/zero/1.0/">CC0</a></sub>
</p>
