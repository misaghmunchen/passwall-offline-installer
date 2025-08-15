include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-passwall-installer
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_MAINTAINER:=you <you@example.com>
PKG_LICENSE:=MIT

LUCI_TITLE:=Passwall Offline Installer (23.05 & 24.10.2)
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luci-compat +luci-base +curl +wget +tar +coreutils +coreutils-sha256sum +unzip

define Package/$(PKG_NAME)/conffiles
endef

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./root/usr/bin/pw_offline_install.sh $(1)/usr/bin/pw_offline_install.sh

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/pw-installer-clean $(1)/etc/init.d/pw-installer-clean
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
