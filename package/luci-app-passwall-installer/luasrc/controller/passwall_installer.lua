
module("luci.controller.passwall_installer", package.seeall)

function index()
	if not nixio.fs.access("/usr/bin/pw_offline_install.sh") then return end

	entry({"admin","services","passwall_installer"},
		call("action_index"), _("Passwall Offline Installer"), 50).leaf = true

	entry({"admin","services","passwall_installer","run"},
		call("action_run"), nil).leaf = true

	entry({"admin","services","passwall_installer","log"},
		call("action_log"), nil).leaf = true
end

function action_index()
	luci.template.render("passwall_installer/index")
end

function action_run()
	luci.http.prepare_content("application/json")
	local ver = luci.http.formvalue("ver") or "23"
	local cmd = string.format("nohup /usr/bin/pw_offline_install.sh %q >/tmp/pw_installer.log 2>&1 &", ver)
	os.execute(cmd)
	luci.http.write_json({ ok = true })
end

function action_log()
	luci.http.prepare_content("text/plain; charset=utf-8")
	local f = io.open("/tmp/pw_installer.log", "r")
	if f then
		luci.http.write(f:read("*a"))
		f:close()
	else
		luci.http.write("Log is empty.\n")
	end
end
