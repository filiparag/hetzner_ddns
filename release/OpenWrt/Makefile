include $(TOPDIR)/rules.mk

PKG_NAME:=hetzner_ddns
PKG_VERSION:=0.2.5
PKG_RELEASE:=1
PKG_LICENSE:=BSD-2-Clause-license
PKG_MAINTAINER:=Filip Parag

# clone sources
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/filiparag/hetzner_ddns.git
PKG_SOURCE_VERSION:=master

# define src variables
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_MIRROR_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Hetzner Dynamic DNS Daemon
	DEPENDS:=+jq +gawk +curl
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
A simple daemon to continuously update Hetzner DNS A and AAAA records for your server with a dynamic IP address.
It features support for multiple subdomain records with painless configuration and administration.
Please see https://github.com/filiparag/hetzner_ddns/README.md for further information.
endef

define Build/Prepare
	$(call Build/Prepare/Default)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/hetzner_ddns/install
	# copy shell script and conf as preparation
	cp $(PKG_BUILD_DIR)/$(PKG_NAME).sh ./files/
	cp $(PKG_BUILD_DIR)/$(PKG_NAME).conf ./files/

	# modify conf dir to match openwrt defaults /etc/config
	sed -i 's|/usr/local/etc|/etc/config|g' ./files/$(PKG_NAME).sh

	# install shell script, conf and service
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/hetzner_ddns.sh $(1)/usr/bin

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/hetzner_ddns $(1)/etc/init.d

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/hetzner_ddns.conf $(1)/etc/config/hetzner_ddns.conf
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
