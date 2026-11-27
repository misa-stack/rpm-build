#!/usr/bin/env bash

set -euo pipefail

: "${VERSION:=1.24.3b}"
: "${HOST_UID:=1000}"
: "${HOST_GID:=1000}"

# Install dependencies as root
if [[ "$(id -u)" -eq 0 ]]; then
    dnf install -y \
        git curl wget sudo shadow-utils \
        python3 python3-devel python3-pip python3.14 python3.14-devel \
        nodejs22 nodejs22-npm \
        nodejs22-bin nodejs22-npm-bin \
        gcc gcc-c++ make clang clang-devel llvm llvm-devel lld \
        nasm yasm m4 sccache cbindgen \
        gtk3-devel alsa-lib-devel \
        libcurl-devel dbus-devel \
        dbus-glib-devel libdrm-devel \
        pulseaudio-libs-devel \
        libX11-devel libXt-devel libxcb-devel \
        libuuid-devel mesa-libGL-devel \
        xorg-x11-server-Xvfb \
        openssl nss-tools \
        zip unzip tar xz zstd dos2unix rsync \
        rpm-build rpmdevtools \
        desktop-file-utils

    command -v llvm-config
    llvm-config --version
    command -v cbindgen
    cbindgen --version
    dnf clean all

    if ! getent group "$HOST_GID" >/dev/null; then
        groupadd -g "$HOST_GID" builder
    fi

    useradd -m \
        -u "$HOST_UID" \
        -g "$HOST_GID" \
        -s /bin/bash builder

    echo 'builder ALL=(ALL) NOPASSWD: ALL' \
        > /etc/sudoers.d/builder

    chmod 0440 /etc/sudoers.d/builder

    exec runuser -u builder -- \
        env VERSION="$VERSION" \
        bash /workspace/build.sh
fi

[[ "$VERSION" =~ ^[0-9]+(\.[0-9]+){1,3}b?$ ]] || { echo "Invalid Zen release tag: $VERSION" >&2; exit 1; }

cd "$HOME"

# Keep Mach and Surfer on a supported Python without replacing Fedora's system Python.
mkdir -p "$HOME/.local/zen-build-bin"
ln -sf /usr/bin/python3.14 "$HOME/.local/zen-build-bin/python3"
ln -sf /usr/bin/python3.14 "$HOME/.local/zen-build-bin/python"
export PATH="$HOME/.local/zen-build-bin:$PATH"
export MACH_PYTHON=/usr/bin/python3.14
python3 --version

# Download upstream source code
git clone \
    --depth 1 \
    --branch "$VERSION" \
    --recurse-submodules \
    https://github.com/zen-browser/desktop.git

cd desktop

git config --global user.name "Zen RPM Builder"
git config --global user.email "builder@localhost"

# Install the upstream Rust version
RUST_VERSION="$(sed -n \
    's/^channel *= *"\(.*\)"/\1/p' \
    rust-toolchain.toml)"

curl --proto '=https' --tlsv1.2 -fsSL \
    https://sh.rustup.rs \
    -o /tmp/rustup.sh

sh /tmp/rustup.sh \
    -y --default-toolchain "$RUST_VERSION"

export PATH="$HOME/.cargo/bin:$PATH"

# Configure the build
export SURFER_PLATFORM=linux
export SURFER_COMPAT=x86_64
export ZEN_RELEASE_BRANCH=release
export ZEN_GA_DISABLE_PGO=1
export ZEN_DISABLE_LTO=1
export CARGO_INCREMENTAL=0

# Install JavaScript dependencies
npm ci

# Configure Zen's build system
npm run surfer -- ci \
    --brand release \
    --display-version "$VERSION"

# Download Firefox and apply Zen modifications
npm run download
npm run import

# Prepare localization files
bash scripts/download-language-packs.sh

# Bootstrap Mozilla's compiler and build tools
(
    cd engine
    ./mach --no-interactive bootstrap \
        --application-choice browser
)

# Select Mozilla's compiler if available
if [[ -x "$HOME/.mozbuild/clang/bin/clang" ]]; then
    export CC="$HOME/.mozbuild/clang/bin/clang"
    export CXX="$HOME/.mozbuild/clang/bin/clang++"
else
    export CC=clang
    export CXX=clang++
fi

# Compile and package the browser
# Prefer the matching Mozilla bootstrap toolchain when available.
if [[ -x "$HOME/.mozbuild/clang/bin/llvm-config" ]]; then
    export LLVM_CONFIG="$HOME/.mozbuild/clang/bin/llvm-config"
    export PATH="$HOME/.mozbuild/clang/bin:$PATH"
fi
export ZEN_RELEASE=1

npm run build -- --jobs 4 
npm run package

# Prepare RPM source files
rpmdev-setuptree

SOURCES="$HOME/rpmbuild/SOURCES"

RPM_VERSION="${VERSION%b}"

if [[ "$VERSION" == *b ]]; then
    RPM_VERSION="${RPM_VERSION}~b"
fi

cp dist/zen-*.tar.xz "$SOURCES/zen.tar.xz"

cp LICENSE "$SOURCES/LICENSE"

cp configs/branding/release/logo128.png \
    "$SOURCES/zen.png"

cp build/AppDir/zen.desktop \
    "$SOURCES/zen.desktop"

# Build the RPM
rpmbuild -bb \
    --define "zen_version $RPM_VERSION" \
    /workspace/zen-browser.spec

# Export the RPM
mkdir -p /workspace/out

cp "$HOME"/rpmbuild/RPMS/x86_64/*.rpm \
    /workspace/out/

ls -lh /workspace/out/
