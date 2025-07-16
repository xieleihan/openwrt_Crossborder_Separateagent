m = Map("myproxy", translate("Device Proxy Settings"))
s = m:section(TypedSection, "device_proxy", translate("Device Proxy Mapping"))
s.addremove = true
s.anonymous = false

o = s:option(Value, "ip", translate("Client IP"))
o.datatype = "ipaddr"

o = s:option(Value, "proxy_ip", translate("Proxy Server IP"))
o.default = "127.0.0.1"

o = s:option(Value, "proxy_port", translate("Proxy Port"))
o.datatype = "port"

return m