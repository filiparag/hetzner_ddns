include $(TOPDIR)/rules.mk

PKG_NAME:=hetzner_ddns
PKG_VERSION:=0.2.5
PKG_RELEASE:=1
PKG_LICENSE:=BSD-2-Clause-license
PKG_MAINTAINER:=Filip Parag

include $(INCLUDE_DIR)/package.mk

define Package/hetzner_ddns
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Hetzner Dynamic DNS Daemon
	DEPENDS:=+jq +gawk +curl
	PKGARCH:=all
endef

define Package/hetzner_ddns/description
A simple daemon to continuously update Hetzner DNS A and AAAA records for your server with a dynamic IP address.
It features support for multiple subdomain records with painless configuration and administration.
Please see https://github.com/filiparag/hetzner_ddns/README.md for further information.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/hetzner_ddns/install
	# modify conf dir to match openwrt defaults /etc/config
	sed -i 's|/usr/local/etc|/etc/config|g' ./files/hetzner_ddns.sh

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/hetzner_ddns.sh $(1)/usr/bin

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/hetzner_ddns $(1)/etc/init.d

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/hetzner_ddns.conf $(1)/etc/config/hetzner_ddns.conf
endef

$(eval $(call BuildPackage,hetzner_ddns))
