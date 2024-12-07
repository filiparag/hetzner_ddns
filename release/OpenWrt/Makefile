include $(TOPDIR)/rules.mk

PKG_NAME:=hetzner-ddns
PKG_VERSION:=0.2.6
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
A simple daemon to continuously update Hetzner DNS A and AAAA records for your server with a dynamic IP address.
It features support for multiple subdomain records with painless configuration and administration.
Please see https://github.com/filiparag/hetzner_ddns/README.md for further information.
endef

define Package/$(PKG_NAME)/conffiles
	/etc/config/hetzner_ddns.conf
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
	cp $(PKG_BUILD_DIR)/hetzner_ddns.sh ./files/
	cp $(PKG_BUILD_DIR)/hetzner_ddns.conf ./files/
	cp $(PKG_BUILD_DIR)/hetzner_ddns.openwrt.rc ./files/

	# modify conf dir to match openwrt defaults /etc/config
	sed -i 's|/usr/local/etc|/etc/config|g' ./files/hetzner_ddns.sh

	# install shell script, conf and service
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/hetzner_ddns.sh $(1)/usr/bin

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/hetzner_ddns.openwrt.rc $(1)/etc/init.d/hetzner_ddns

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/hetzner_ddns.conf $(1)/etc/config/hetzner_ddns.conf
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

	# cleanup log file
	if [ -f /var/log/hetzner_ddns.log ]
	then
		echo "Cleaning up /var/log/hetzner_ddns.log..."
		rm /var/log/hetzner_ddns.log
	fi
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
