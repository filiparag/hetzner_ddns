Name:           hetzner_ddns
Version:        0.2.2
Release:        1%{?dist}
Summary:        Hetzner Dynamic DNS Daemon
BuildArch:      noarch
License:        BSD
URL:            https://github.com/filiparag/%{name}
Source0:        %{url}/archive/refs/tags/%{version}.tar.gz
Obsoletes:      %{name} <= %{version}-%{release}
Provides:       %{name} = %{version}-%{release}
BuildRequires:  make
Requires:       jq curl
AutoReq:        no

%description
A simple daemon to continuously update Hetzner DNS
A and AAAA records for your server with a dynamic IP address.

It features support for multiple subdomain records with painless
configuration and administration.

%prep
%setup -q
find . -maxdepth 1 -type f \
	-exec sed -i 's:/usr/local/etc:/etc:g' {} \; \
	-exec sed -i 's:/usr/local:/usr:g' {} \;

%install
make prefix=%{buildroot} install systemd

%files
/usr/bin/%{name}
/usr/share/man/man1/%{name}.1.gz
/etc/%{name}.conf.sample
/etc/systemd/system/%{name}.service
/etc/systemd/system/%{name}@.service
%config(noreplace) /etc/%{name}.conf
