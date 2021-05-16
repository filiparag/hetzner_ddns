install: script config docs

script: hetzner_ddns.sh
	@mkdir -p /usr/local/bin
	@install -m 0755 -p hetzner_ddns.sh /usr/local/bin/hetzner_ddns

config: hetzner_ddns.conf
	@mkdir -p /usr/local/etc
	@install -m 0644 -p hetzner_ddns.conf /usr/local/etc/hetzner_ddns.conf.sample
	@test -f /usr/local/etc/hetzner_ddns.conf || \
		install -m 0644 -p hetzner_ddns.conf /usr/local/etc/hetzner_ddns.conf

rc.d: hetzner_ddns.rc
	@mkdir -p /usr/local/etc/rc.d
	@install -m 0755 -p hetzner_ddns.rc /usr/local/etc/rc.d/hetzner_ddns

systemd: hetzner_ddns.service
	@mkdir -p /etc/systemd/system
	@install -m 0755 -p hetzner_ddns.service /etc/systemd/system/hetzner_ddns.service

docs: hetzner_ddns.1.man
	@mkdir -p /usr/local/share/man/man1
	@install -m 0644 -p hetzner_ddns.1.man /usr/local/share/man/man1/hetzner_ddns.1
	@test -f /usr/local/share/man/man1/hetzner_ddns.1.gz || \
		gzip -f /usr/local/share/man/man1/hetzner_ddns.1
	@test -f /usr/local/share/man/man1/hetzner_ddns.1 && \
		rm -f /usr/local/share/man/man1/hetzner_ddns.1 || \
		true

remove:
	@rm -f 	/usr/local/bin/hetzner_ddns \
			/usr/local/etc/hetzner_ddns.conf.sample \
			/usr/local/share/man/man1/hetzner_ddns.1.gz \
			/usr/local/etc/rc.d/hetzner_ddns \
			/etc/systemd/system/hetzner_ddns.service \
