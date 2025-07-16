m = Map("myproxy", translate("Device Proxy Status"))

-- Status section
s = m:section(TypedSection, "status", translate("Service Status"))
s.template = "myproxy/status"
s.anonymous = true
s.addremove = false

-- Add a dummy section for template
local dummy_section = s:option(DummyValue, "_dummy", "")
dummy_section.template = "myproxy/status"

return m
