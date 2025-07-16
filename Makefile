include $(TOPDIR)/rules.mk

PKG_NAME:=myproxy
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/myproxy
  SECTION:=net
  CATEGORY:=Network
  TITLE:=DHCP Device Proxy Manager
  DEPENDS:=+luci +iptables
endef

define Package/myproxy/description
  Assign different SOCKS proxies to each DHCP client via LuCI.
endef

define Build/Prepare
    mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
    true
endef

define Package/myproxy/install
    $(INSTALL_DIR) $(1)/etc/config
    $(INSTALL_DATA) ./files/etc/config/myproxy $(1)/etc/config/

    $(INSTALL_DIR) $(1)/etc/init.d
    $(INSTALL_BIN) ./files/etc/init.d/myproxy $(1)/etc/init.d/

    $(INSTALL_DIR) $(1)/usr/bin
    $(INSTALL_BIN) ./files/usr/bin/myproxy_apply.sh $(1)/usr/bin/

    $(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
    $(INSTALL_DATA) ./luasrc/controller/myproxy.lua $(1)/usr/lib/lua/luci/controller/
endef

$(eval $(call BuildPackage,myproxy))