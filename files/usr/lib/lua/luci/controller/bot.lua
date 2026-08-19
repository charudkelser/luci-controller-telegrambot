module("luci.controller.bot", package.seeall)

function index()
    entry({"admin", "services", "bot"}, cbi("bot"), _("Telegram Bot"), 60).dependent = true
end

