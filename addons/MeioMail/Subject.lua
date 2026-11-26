-- An empty subject fills itself again: the attached item ("Linen Cloth (20)"), which Forever's
-- mailbox stopped doing on 17 Nov (Blizzard's fill waits on HasSendMailItem, now always
-- false), or the money sent ("5g 25s"), so mail to an alt can go without typing a subject
-- (Send stays grey until there is one). Only ever replaces a blank subject or one we
-- filled, so it goes quiet if Blizzard's own fill comes back.
-- C.O.D. stays as the game leaves it: it lost gold in Forever's first weeks and may be
-- switched off on purpose, so re-enabling it could send an item without the payment.
local _, M = ...

local MAX_LEN = 64
local filled

local function Box()
  return SendMailSubjectEditBox
    or (SendMailFrame and SendMailFrame.SendMailSubjectEditBox)
end

local function ItemText()
  local order, counts = {}, {}
  for i = 1, ATTACHMENTS_MAX_SEND or 12 do
    local name, _, _, count = GetSendMailItem(i)
    if not name then
      local link = GetSendMailItemLink and GetSendMailItemLink(i)
      name = link and link:match("|h%[(.-)%]|h")
    end
    if name then
      if not counts[name] then order[#order + 1] = name end
      counts[name] = (counts[name] or 0) + (count or 1)
    end
  end
  if #order == 0 then return nil end
  local function One(name)
    return counts[name] > 1 and ("%s (%d)"):format(name, counts[name]) or name
  end
  local all = {}
  for i, name in ipairs(order) do all[i] = One(name) end
  local text = table.concat(all, ", ")
  if #text <= MAX_LEN then return text end
  return ("%s and %d more"):format(One(order[1]), #order - 1)
end

local function MoneyText()
  if not (SendMailMoney and MoneyInputFrame_GetCopper) then return nil end
  if SendMailCODButton and SendMailCODButton:GetChecked() then return nil end
  local copper = MoneyInputFrame_GetCopper(SendMailMoney) or 0
  if copper <= 0 then return nil end
  local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
  local parts = {}
  if g > 0 then parts[#parts + 1] = g .. "g" end
  if s > 0 then parts[#parts + 1] = s .. "s" end
  if c > 0 then parts[#parts + 1] = c .. "c" end
  return table.concat(parts, " ")
end

function M.FillSubject()
  if M.db and M.db.subject == false then return end
  local box = Box()
  if not box then return end
  local current = box:GetText() or ""
  if current ~= "" and current ~= filled then
    filled = nil
    return
  end
  local text = ItemText() or MoneyText()
  if text then
    if text ~= current then box:SetText(text) end
    filled = text
  elseif filled then
    box:SetText("")
    filled = nil
  end
end

-- after Blizzard's own update, so a fill of its own (if it comes back) wins
local hooked, moneyHooked
local function Hook()
  if not hooked and type(SendMailFrame_Update) == "function" then
    hooksecurefunc("SendMailFrame_Update", M.FillSubject)
    hooked = true
  end
  -- the money boxes call the function SendMailMoney kept at load, not the global
  if not moneyHooked and SendMailMoney
    ---@diagnostic disable-next-line: undefined-field
    and type(SendMailMoney.onValueChangedFunc) == "function" then
    hooksecurefunc(SendMailMoney, "onValueChangedFunc", M.FillSubject)
    moneyHooked = true
  end
end
Hook()

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("MAIL_SEND_INFO_UPDATE")
events:RegisterEvent("MAIL_SEND_SUCCESS")
events:RegisterEvent("MAIL_CLOSED")
events:SetScript("OnEvent", function(_, e)
  if e == "ADDON_LOADED" then
    Hook()
  elseif e == "MAIL_SEND_INFO_UPDATE" then
    if not hooked then M.FillSubject() end
  else
    filled = nil
  end
end)
