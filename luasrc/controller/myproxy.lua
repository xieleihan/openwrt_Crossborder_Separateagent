module("luci.controller.myproxy", package.seeall)

function index()
    entry({"admin", "services", "myproxy"}, cbi("myproxy"), _("Device Proxy Settings"), 50)
    entry({"admin", "services", "myproxy", "status"}, cbi("myproxy_status"), _("Status"), 60)
end