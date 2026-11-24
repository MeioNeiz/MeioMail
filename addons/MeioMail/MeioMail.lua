-- Log of sent mail. On Forever all mail arrives at once, even items or money to another
-- account, so there is no arrival time to count down.
local _, M = ...
MeioMail = M

M.PREFIX = "|cffb090ffMeioMail:|r "
local KEEP = 50
local KEEP_DAYS = 30
local LIST_MAX = 10

local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage(M.PREFIX .. msg) end
local function Line(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end

local function Realm()
  local r = GetNormalizedRealmName and GetNormalizedRealmName()
  if not r or r == "" then r = (GetRealmName() or ""):gsub("%s", "") end
  return r ~= "" and r or nil
end

------------------------------------------------------------------------------ formatting

function M.Money(copper)
  local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
  local parts = {}
  if g > 0 then parts[#parts + 1] = "|cffffd700" .. g .. "g|r" end
  if s > 0 and #parts < 2 then parts[#parts + 1] = "|cffc7c7cf" .. s .. "s|r" end
  if c > 0 and #parts < 2 and g == 0 then parts[#parts + 1] = "|cffeda55f" .. c .. "c|r" end
  return #parts > 0 and table.concat(parts, " ") or "|cffeda55f0c|r"
end

local function When(t, now)
  if now - t < 20 * 3600 then return date("%H:%M", t) --[[@as string]] end
  return date("%d %b %H:%M", t) --[[@as string]]
end
M.When = When

function M.To(m)
  local n, r = strsplit("-", m.to, 2)
  n = n:sub(1, 1):upper() .. n:sub(2)
  if r and r ~= "" and r:gsub("%s", ""):lower() ~= (Realm() or ""):lower() then
    return n .. "-" .. r
  end
  return n
end

function M.Contents(m)
  local parts = {}
  if #m.items == 1 then
    local it = m.items[1]
    parts[1] = it.link .. (it.count > 1 and (" x" .. it.count) or "")
  elseif #m.items > 1 then
    parts[1] = #m.items .. " items"
  end
  if m.money > 0 then parts[#parts + 1] = M.Money(m.money) end
  if m.cod > 0 then parts[#parts + 1] = "COD " .. M.Money(m.cod) end
  if #parts == 0 then return "|cff999999letter|r" end
  return table.concat(parts, ", ")
end

------------------------------------------------------------------------------ log

function M.Changed()
  if M.Refresh then M.Refresh() end
end

local function Prune()
  local list, cutoff = M.db.sent, time() - KEEP_DAYS * 86400
  for i = #list, 1, -1 do
    if i > KEEP or list[i].at < cutoff then table.remove(list, i) end
  end
end

-- SendMail is only a request: the mail counts once MAIL_SEND_SUCCESS comes back
local sending
hooksecurefunc("SendMail", function(to, subject)
  local cod = GetSendMailCOD and GetSendMailCOD() or 0
  local m = {
    to = strtrim(to or ""), subject = subject ~= "" and subject or nil,
    from = UnitName("player"), items = {},
    money = cod > 0 and 0 or (GetSendMailMoney() or 0), cod = cod,
  }
  for i = 1, ATTACHMENTS_MAX_SEND or 12 do
    local name, _, _, count = GetSendMailItem(i)
    if name then
      local link = GetSendMailItemLink and GetSendMailItemLink(i)
      m.items[#m.items + 1] = { link = link or name, count = count or 1 }
    end
  end
  sending = m
end)

local function Sent()
  local m = sending
  sending = nil
  if not m then return end
  m.at = time()
  table.insert(M.db.sent, 1, m)
  Prune()
  M.Changed()
end

------------------------------------------------------------------------------ slash

local function List()
  local list = M.db.sent
  if #list == 0 then
    Print("no sent mail yet")
    return
  end
  Print("sent mail, newest first")
  local now, me = time(), UnitName("player")
  for i = 1, math.min(#list, LIST_MAX) do
    local m = list[i]
    local from = m.from ~= me and (" |cff999999from " .. m.from .. "|r") or ""
    Line(("  %s - %s - %s%s"):format(M.To(m), M.Contents(m), When(m.at, now), from))
  end
  if #list > LIST_MAX then
    Line(("  |cff999999%d older ones: at the mailbox's Send tab|r"):format(#list - LIST_MAX))
  end
end
M.List = List

local function Now(on)
  return " (now " .. (on and "|cff80ff80on|r" or "|cffff8080off|r") .. ")"
end

local function Help()
  Print("remembers the mail you send")
  for _, l in ipairs({
    "  |cffffd100/meiomail list|r - the mail you sent (also |cffffd100/sent|r)",
    "  |cffffd100/meiomail panel on||off|r - sent mail beside the mailbox's Send tab"
      .. Now(M.db.panel ~= false),
    "  |cffffd100/meiomail clear|r - forget the sent mail",
    "  Settings: Esc > Options > AddOns > MeioMail (|cffffd100/meiomail settings|r)",
  }) do Line(l) end
end

function M.SetPanel(on)
  M.db.panel = on
  Print("sent mail beside the mailbox " .. (on and "|cff80ff80on|r" or "|cffff8080off|r"))
  M.Changed()
end

local function Command(msg)
  local cmd, arg = strsplit(" ", strtrim(msg or ""):lower(), 2)
  arg = arg and strtrim(arg)
  if cmd == "" then
    if not (M.OpenSettings and M.OpenSettings()) then Help() end
  elseif cmd == "help" or cmd == "?" then
    Help()
  elseif cmd == "list" then
    List()
  elseif cmd == "panel" then
    local on = M.db.panel ~= false
    if arg == "on" then on = true elseif arg == "off" then on = false else on = not on end
    M.SetPanel(on)
  elseif cmd == "clear" then
    wipe(M.db.sent)
    Print("sent mail forgotten")
    M.Changed()
  elseif cmd == "settings" or cmd == "options" then
    if not (M.OpenSettings and M.OpenSettings()) then Help() end
  else
    Print(('unknown command "%s"'):format(cmd))
    Help()
  end
end

SLASH_MEIOMAIL1 = "/meiomail"
SlashCmdList.MEIOMAIL = Command
SLASH_MEIOMAILSENT1 = "/sent"
SlashCmdList.MEIOMAILSENT = function(msg)
  if strtrim(msg or "") == "" then List() else Command(msg) end
end

function MeioMail_OnAddonCompartmentClick()
  if not (M.OpenSettings and M.OpenSettings()) then List() end
end

------------------------------------------------------------------------------ events

local events = CreateFrame("Frame")
local handlers = {
  ADDON_LOADED = function(name)
    if name == "MeioMail" then
      MeioMailDB = MeioMailDB or {}
      M.db = MeioMailDB
      M.db.sent = M.db.sent or {}
      -- left by the version that counted down a 1 hour delay
      M.db.chars = nil
      for _, m in ipairs(M.db.sent) do m.arrives, m.own = nil, nil end
      if M.db.panel == nil then M.db.panel = true end
      Prune()
    end
    if M.OnAddonLoaded then M.OnAddonLoaded(name) end
  end,
  PLAYER_LOGIN = function()
    if M.RegisterSettings then pcall(M.RegisterSettings) end
  end,
  MAIL_SHOW = function() if M.OnMailShow then M.OnMailShow() end end,
  MAIL_SEND_SUCCESS = Sent,
  MAIL_FAILED = function() sending = nil end,
}
for e in pairs(handlers) do events:RegisterEvent(e) end
events:SetScript("OnEvent", function(_, e, ...) handlers[e](...) end)
