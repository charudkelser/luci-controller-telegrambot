m = Map("bot", translate("Telegram Bot Controller"), translate("Pengaturan Telegram Bot OpenWrt"))

s = m:section(NamedSection, "main", "bot", translate("Konfigurasi"))

-- FITUR TAMBAHAN: Indikator Status Realtime
local is_running = (luci.sys.call("pgrep -f /usr/bin/bot >/dev/null") == 0)
st = s:option(DummyValue, "_status", translate("Status Bot"))
if is_running then
    st.value = "<span style='color:green; font-weight:bold;'>🟢 Berjalan (Running)</span>"
else
    st.value = "<span style='color:red; font-weight:bold;'>🔴 Nonaktif (Stopped)</span>"
end
st.rawhtml = true

-- KODE UTAMA
o = s:option(Flag, "enabled", translate("Aktifkan"))
o.rmempty = false

o = s:option(Value, "bot_token", translate("Token Bot"))
o.orient = "vertical"
o.rmempty = true

o = s:option(Value, "chat_id", translate("Chat ID"))
o.orient = "vertical"
o.rmempty = true

function m.on_after_commit(self)
    local enabled = m:get("main", "enabled")
    if enabled == "1" then
        luci.sys.exec("sleep 1; /etc/init.d/bot restart >/dev/null 2>&1 &")
    else
        luci.sys.exec("sleep 1; /etc/init.d/bot stop >/dev/null 2>&1 &")
    end
end

return m
