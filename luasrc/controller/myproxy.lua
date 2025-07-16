module("luci.controller.myproxy", package.seeall)

function index()
    entry({"admin", "services", "myproxy"}, cbi("myproxy"), _("Device Proxy Settings"), 50)
end