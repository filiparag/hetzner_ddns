Name:           hetzner_ddns
Version:        1.0.1
Release:        1%{?dist}
Summary:        Hetzner Dynamic DNS Daemon
BuildArch:      noarch
License:        BSD
URL:            https://github.com/filiparag/%{name}
Source0:        %{url}/archive/refs/tags/%{version}.tar.gz
Obsoletes:      %{name} <= %{version}-%{release}
Provides:       %{name} = %{version}-%{release}
BuildRequires:  make
Requires:       jq curl net-tools
AutoReq:        no

%description
Continuously update your servers' A and AAAA records with dynamic IP addresses.

Manage Hetzner DNS records across several domains, with various records at
different TTLs, on multiple network interfaces. This portable utility helps you
get it done quickly and easily.

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
/etc/%{name}.json.sample
/etc/systemd/system/%{name}.service
%config(noreplace) /etc/%{name}.json
