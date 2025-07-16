m = Map("myproxy", translate("Device Proxy Settings"))

s = m:section(TypedSection, "device_proxy", translate("Device Proxy Mapping"))
s.addremove = true
s.anonymous = false
s.template = "cbi/tblsection"

-- Client IP
o = s:option(Value, "ip", translate("Client IP"))
o.datatype = "ipaddr"
o.placeholder = "192.168.1.100"
o.rmempty = false

-- Proxy Server IP
o = s:option(Value, "proxy_ip", translate("Proxy Server IP"))
o.datatype = "ipaddr"
o.default = "127.0.0.1"
o.placeholder = "127.0.0.1"
o.rmempty = false

-- Proxy Port
o = s:option(Value, "proxy_port", translate("Proxy Port"))
o.datatype = "port"
o.placeholder = "1080"
o.rmempty = false

-- Proxy Type
o = s:option(ListValue, "proxy_type", translate("Proxy Type"))
o:value("socks5", translate("SOCKS5"))
o:value("http", translate("HTTP"))
o.default = "socks5"

-- Enable/Disable
o = s:option(Flag, "enabled", translate("Enable"))
o.default = "1"

return m