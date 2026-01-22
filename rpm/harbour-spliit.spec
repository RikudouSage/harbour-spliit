Name:       harbour-spliit

Summary:    Spliit
Version:    0.8.2
Release:    1
License:    MIT
URL:        http://example.org/
Source0:    %{name}-%{version}.tar.bz2
%bcond_with harbour_store

%if %{with harbour_store}
%global __provides_exclude_from ^%{_datadir}/%{name}/lib/.*$
%global __requires_exclude_from ^%{_datadir}/%{name}/lib/.*$
%global __requires_exclude ^libspliit\\.so$|^libspliit\\.so\\(\\)\\(64bit\\)$|^libicui18n\\.so\\..*$|^libicuuc\\.so\\..*$|^libicudata\\.so\\..*$
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

%description
Share Expenses with Friends & Family - No ads. No account. Open Source. Forever Free.


%prep
%setup -q -n %{name}-%{version}

%build

%if %{with harbour_store}
%qmake5 CONFIG+=harbour_store
%else
%qmake5
%endif

%make_build


%install
%qmake5_install

desktop-file-install --delete-original --dir %{buildroot}%{_datadir}/applications %{buildroot}%{_datadir}/applications/*.desktop

strip --strip-unneeded %{buildroot}%{_datadir}/%{name}/lib/libspliit.so

# Bundle ICU to avoid external shared-library runtime dependencies.
# ICU is loaded dynamically (if present); do not ship ICU shared libraries.

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
