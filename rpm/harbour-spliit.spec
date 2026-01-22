Name:       harbour-spliit

Summary:    Spliit
Version:    0.8.3
Release:    1
License:    MIT
URL:        http://example.org/
Source0:    %{name}-%{version}.tar.bz2
%{!?harbour_store:%define harbour_store %(if [ -n "$HARBOUR_STORE" ]; then echo 1; elif echo "$PWD" | grep -q -- '-Store'; then echo 1; else echo 0; fi)}

%if 0%{?harbour_store}
%global __provides_exclude_from ^%{_datadir}/%{name}/lib/.*$
%global __requires_exclude_from ^%{_datadir}/%{name}/lib/.*$
%global __requires_exclude ^libspliit\\.so$|^libspliit\\.so\\(\\)\\(64bit\\)$|^libicui18n\\.so\\..*$|^libicuuc\\.so\\..*$|^libicudata\\.so\\..*$|^libresolv\\.so\\..*$
%endif
Requires:   sailfishsilica-qt5 >= 0.10.9
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(icu-uc)
BuildRequires:  pkgconfig(icu-i18n)
BuildRequires:  libicu-devel
BuildRequires:  desktop-file-utils
BuildRequires:  patchelf

%description
Share Expenses with Friends & Family - No ads. No account.
Open Source. Forever Free.


%prep
%setup -q -n %{name}-%{version}

%build

%if 0%{?harbour_store}
%qmake5 CONFIG+=harbour_store
%else
%qmake5
%endif

%make_build


%install
%qmake5_install

desktop-file-install --delete-original --dir %{buildroot}%{_datadir}/applications %{buildroot}%{_datadir}/applications/*.desktop

strip --strip-unneeded %{buildroot}%{_datadir}/%{name}/lib/libspliit.so
strip --strip-unneeded %{buildroot}%{_bindir}/%{name}
patchelf --remove-rpath %{buildroot}%{_datadir}/%{name}/lib/libspliit.so
patchelf --set-soname libspliit.so %{buildroot}%{_datadir}/%{name}/lib/libspliit.so

# ICU is loaded dynamically (if present); do not ship ICU shared libraries.

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png

%changelog
* Thu Jan 22 2026 Dominik <dominik@chrastecky.cz> - 0.8.2-1
- Initial package
