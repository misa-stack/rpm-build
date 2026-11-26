%global debug_package %{nil}
%global _build_id_links none

Name:           zen-browser
Version:        %{zen_version}
Release:        1%{?dist}
Summary:        Zen Browser
License:        MPL-2.0 AND CC-BY-NC-SA-4.0
URL:            https://zen-browser.app

Source0:        zen.tar.xz
Source1:        LICENSE
Source2:        zen.png
Source3:        zen.desktop

ExclusiveArch:  x86_64

BuildRequires:  desktop-file-utils

Requires:       gtk3
Requires:       alsa-lib
Requires:       dbus-glib
Requires:       libXt
Requires:       libX11
Requires:       libxcb
Requires:       libdrm
Requires:       mesa-libGL
Requires:       pulseaudio-libs

%description
Zen Browser compiled from upstream source code
and packaged for Fedora Linux.

%prep
%setup -q -n zen

%build
# Already compiled by build.sh

%install
mkdir -p %{buildroot}%{_libdir}/zen-browser

cp -a . %{buildroot}%{_libdir}/zen-browser/

# Executable
mkdir -p %{buildroot}%{_bindir}

ln -s %{_libdir}/zen-browser/zen \
    %{buildroot}%{_bindir}/zen

# License
install -Dpm 0644 %{SOURCE1} LICENSE

# Application icon
install -Dpm 0644 %{SOURCE2} \
    %{buildroot}%{_datadir}/icons/hicolor/128x128/apps/zen.png

# Desktop entry
install -Dpm 0644 %{SOURCE3} \
    %{buildroot}%{_datadir}/applications/zen.desktop

# Disable built-in updates
mkdir -p \
    %{buildroot}%{_libdir}/zen-browser/distribution

echo '{"policies":{"DisableAppUpdate":true}}' \
    > %{buildroot}%{_libdir}/zen-browser/distribution/policies.json

%check
test -x %{buildroot}%{_libdir}/zen-browser/zen

desktop-file-validate \
    %{buildroot}%{_datadir}/applications/zen.desktop

%files
%license LICENSE
%{_bindir}/zen
%{_libdir}/zen-browser/
%{_datadir}/applications/zen.desktop
%{_datadir}/icons/hicolor/128x128/apps/zen.png
