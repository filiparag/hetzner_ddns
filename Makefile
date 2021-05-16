install: script config rc docs

script: hetzner_ddns.sh
	@install -m 0755 -p hetzner_ddns.sh /usr/local/bin/hetzner_ddns

config: hetzner_ddns.conf
	@install -m 0644 -p hetzner_ddns.conf /usr/local/etc/hetzner_ddns.conf.sample
	@test -f /usr/local/etc/hetzner_ddns.conf || \
		install -m 0644 -p hetzner_ddns.conf /usr/local/etc/hetzner_ddns.conf

rc: hetzner_ddns.rc
	@install -m 0755 -p hetzner_ddns.rc /usr/local/etc/rc.d/hetzner_ddns

docs:
	@install -m 0644 -p hetzner_ddns.1.man /usr/local/share/man/man1/hetzner_ddns.1
	@gzip -f /usr/local/share/man/man1/hetzner_ddns.1.gz

remove:
	@rm -f 	/usr/local/bin/hetzner_ddns \
			/usr/local/etc/hetzner_ddns.conf.sample \
			/usr/local/etc/rc.d/hetzner_ddns \
			/usr/local/share/man/man1/hetzner_ddns.1.gz