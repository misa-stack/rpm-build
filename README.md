# Zen Browser RPM for Fedora

I originally made this project for my dad so he could install Zen Browser on Fedora without having to deal with tar archives or manually setting up the browser every time there is an update.

I also wanted to learn how RPM packaging, GitHub Actions and Linux package repositories actually work, so I decided to compile Zen from source and package it myself instead of just repackaging the official binaries.

This is a small personal project, not an official Zen Browser repository.

## Current state

- Building Zen from source on GitHub Actions works.
- Building and manually installing the RPM works.
- The GitHub Pages repository and DNF metadata are published, but installation and updates through the repository still need debugging.
- Automatic detection of new upstream releases is not implemented yet.

Currently targeting Fedora 44 on x86_64. Packages are unsigned.

## Manual installation (working)

Download the `zen-browser-rpm` artifact from a successful [build on GitHub Actions](https://github.com/misa-stack/rpm-build/actions/workflows/build.yml). Extract the ZIP file and run the following in the directory containing the RPM:

```bash
sudo dnf install ./zen-browser-*.rpm
```

You can also download the current build using GitHub CLI (requires authentication):

```bash
gh run download 45840127714 --repo misa-stack/rpm-build --name zen-browser-rpm
sudo dnf install ./zen-browser-*.rpm
```

## DNF repository (work in progress)

The goal is to configure the repository once, install Zen with DNF and receive updates alongside all other system packages.

Repository: https://misa-stack.github.io/rpm-build/

The intended setup is:

```bash
sudo curl -fsSL https://misa-stack.github.io/rpm-build/zen-browser.repo \
  -o /etc/yum.repos.d/zen-browser.repo

sudo dnf install zen-browser
```

Then updates should work through the normal:

```bash
sudo dnf upgrade
```

These repository installation and update commands are not fully working or verified yet. Use the manual RPM installation in the meantime. The repository currently disables package and metadata signature verification only for this repository.

## How it works

1. `build.yml` starts a Fedora Docker container on a GitHub Actions runner.
2. `build.sh` installs build dependencies, fetches the selected Zen source release and compiles the browser using Zen's Surfer tooling and Mozilla's mach build system.
3. `zen-browser.spec` packages the locally compiled browser into an RPM using `rpmbuild`.
4. GitHub Actions uploads the RPM as a build artifact.
5. `publish.yml` downloads that artifact, generates RPM repository metadata with `createrepo_c` and deploys the repository to GitHub Pages. It can run manually or after a successful manually triggered build.

```text
Zen source code
    |
    v
GitHub Actions + Fedora Docker container
    |
    v
Surfer / mach
    |
    v
rpmbuild
    |
    +--> Downloadable RPM
    |
    v
createrepo_c + GitHub Pages
    |
    v
DNF installation and updates (WIP)
```

## What's next?

- Fix the remaining DNF repository issues.
- Detect new Zen releases and automatically build them.
- Test installation and upgrades in a clean Fedora environment.

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
