include $(TOPDIR)/rules.mk

PKG_NAME:=hetzner-ddns
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_LICENSE:=BSD-2-Clause-license
PKG_MAINTAINER:=Filip Parag

# clone sources
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/filiparag/hetzner_ddns.git
PKG_SOURCE_VERSION:=0.2.6

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
Continuously update your servers' A and AAAA records with dynamic IP addresses.
Manage Hetzner DNS records across several domains, with various records at different TTLs,
on multiple network interfaces. This portable utility helps you get it done quickly and easily.
Please see https://github.com/filiparag/hetzner_ddns/README.md for further information.
endef

define Package/$(PKG_NAME)/conffiles
	/etc/config/hetzner_ddns.json
endef


define Build/Prepare
	$(call Build/Prepare/Default)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	# copy shell script, init.d file and conf as preparation
	mkdir -p files
	cp $(PKG_BUILD_DIR)/hetzner_ddns.sh ./files/hetzner_ddns
	cp $(PKG_BUILD_DIR)/hetzner_ddns.json ./files/
	cp $(PKG_BUILD_DIR)/hetzner_ddns.openwrt.rc ./files/

	# modify conf dir to match openwrt defaults /etc/config
	sed -i 's|/usr/local/etc|/etc/config|g' ./files/hetzner_ddns

	# install shell script, conf and service
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/hetzner_ddns $(1)/usr/bin

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/hetzner_ddns.openwrt.rc $(1)/etc/init.d/hetzner_ddns

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/hetzner_ddns.json $(1)/etc/config/hetzner_ddns.json
endef

define Package/$(PKG_NAME)/prerm
	# first stop service and make sure command does not fail
	echo "Stopping hetzner_ddns service..."
	service hetzner_ddns stop || true

	# remove pid file just in case it is still here
	if [ -f /var/run/hetzner_ddns.pid ]
	then
		echo "Cleaning up /var/run/hetzner_ddns.pid..."
		rm /var/run/hetzner_ddns.pid
	fi
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
