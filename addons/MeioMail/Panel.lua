-- The sent mail list beside the mailbox, on the Send tab only (the Inbox's open letter,
-- OpenMailFrame, takes the same spot). Parented to SendMailFrame so it follows that tab.
local _, M = ...

local WIDTH = 332
local ROW_H = 45
local TOP, BOTTOM = 60, 52
-- Blizzard's colour for read mail in the Inbox
local SOFT = 0.75

local panel, empty, prevButton, nextButton
local page = 1
local rows = {}

local function Label(text) return NORMAL_FONT_COLOR:WrapTextInColorCode(text) end

local function Soft(text) return ("|cffbfbfbf%s|r"):format(text) end

local function Tooltip(row)
  local m = row.mail
  if not m then return end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:AddLine("To " .. M.To(m))
  if m.subject then GameTooltip:AddLine(m.subject, SOFT, SOFT, SOFT, true) end
  for _, it in ipairs(m.items) do
    GameTooltip:AddDoubleLine(("|T%s:16|t %s"):format(M.ItemIcon(it), M.ItemName(it)),
      it.count > 1 and Soft("x" .. it.count) or " ")
  end
  if m.money > 0 then GameTooltip:AddDoubleLine(Label("Money"), M.Coins(m.money)) end
  if m.cod > 0 then GameTooltip:AddDoubleLine(Label("C.O.D."), M.Coins(m.cod)) end
  local sent = M.When(m.at, time())
  if m.from ~= UnitName("player") then sent = sent .. " from " .. m.from end
  GameTooltip:AddDoubleLine(Label("Sent"), sent, nil, nil, nil, SOFT, SOFT, SOFT)
  GameTooltip:AddLine("Click to mail " .. M.To(m) .. " again", 0, 1, 0)
  GameTooltip:Show()
end

-- the subject is left to the player (or Subject.lua once an item goes in)
local function MailAgain(row)
  local m = row.mail
  if not (m and SendMailNameEditBox) then return end
  SendMailNameEditBox:SetText(M.To(m))
  SendMailNameEditBox:SetCursorPosition(0)
  if SendMailSubjectEditBox then SendMailSubjectEditBox:SetFocus() end
  if SendMailFrame_Update then SendMailFrame_Update() end
end

-- Blizzard's Inbox row (MailItemTemplate): item button with count, quality border and
-- C.O.D. badge, name in gold, subject below, time on the right
local function Row(i)
  local name = "MeioMailRow" .. i
  local row = CreateFrame("Button", name, panel, "MailItemTemplate")
  row:SetPoint("TOPLEFT", panel, "TOPLEFT", 13, -TOP - (i - 1) * ROW_H)
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
  row.to = _G[name .. "Sender"]
  row.subject = _G[name .. "Subject"]
  row.sent = _G[name .. "ExpireTime"]
  row.sent:EnableMouse(false)
  row.sent:SetWidth(76)
  row.icon = row.Button or _G[name .. "Button"]
  row.icon:UnregisterAllEvents()
  row.icon:EnableMouse(false)
  row.icon:Show()
  row.cod = _G[name .. "ButtonCOD"]
  row.codBack = _G[name .. "ButtonCODBackground"]
  row.money = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.money:SetPoint("TOPRIGHT", row.sent, "BOTTOMRIGHT", 0, -2)
  row.money:SetJustifyH("RIGHT")
  row.subject:SetPoint("RIGHT", row.money, "LEFT", -6, 0)
  row.subject:SetWordWrap(false)
  row.subject:SetTextColor(SOFT, SOFT, SOFT)
  row.to:SetPoint("RIGHT", row.sent, "LEFT", -6, 0)
  row.to:SetWordWrap(false)
  row:SetScript("OnClick", MailAgain)
  row:SetScript("OnEnter", Tooltip)
  row:SetScript("OnLeave", GameTooltip_Hide)
  return row
end

local function Icon(row, m)
  local b, it = row.icon, m.items[1]
  local icon = it and M.ItemIcon(it)
    or (m.money > 0 and (C_CurrencyInfo and C_CurrencyInfo.GetCoinIcon
      and C_CurrencyInfo.GetCoinIcon(m.money) or "Interface\\Icons\\INV_Misc_Coin_01"))
    or "Interface\\Icons\\INV_Misc_Note_01"
  b.Icon:SetTexture(icon)
  SetItemButtonCount(b, it and it.count or 0)
  local q = it and M.ItemQuality(it)
  if q and SetItemButtonQuality then
    SetItemButtonQuality(b, q, it.link)
  elseif b.IconBorder then
    b.IconBorder:Hide()
  end
  local cod = m.cod > 0
  row.cod:SetShown(cod)
  row.codBack:SetShown(cod)
end

-- what a mail with no subject held, in words
local function Summary(m)
  if #m.items == 1 then
    local it = m.items[1]
    return M.ItemName(it) .. (it.count > 1 and (" x" .. it.count) or "")
  elseif #m.items > 1 then
    return #m.items .. " items"
  end
  return m.money > 0 and "" or "letter"
end

local function Anchor()
  if not panel then return end
  local beside = OpenMailFrame and OpenMailFrame:IsShown() and OpenMailFrame or MailFrame
  panel:ClearAllPoints()
  panel:SetPoint("TOPLEFT", beside, "TOPRIGHT", 2, 0)
end

function M.Refresh()
  if not panel then return end
  panel:SetShown(M.db.panel ~= false)
  if not panel:IsVisible() then return end
  local now, me = time(), UnitName("player")
  local pages = math.max(1, math.ceil(#M.db.sent / #rows))
  page = math.min(page, pages)
  prevButton:SetEnabled(page > 1)
  nextButton:SetEnabled(page < pages)
  local first = (page - 1) * #rows
  for i, row in ipairs(rows) do
    local m = M.db.sent[first + i]
    row.mail = m
    row:SetShown(m ~= nil)
    if m then
      row.to:SetText(M.To(m))
      row.sent:SetText(Soft(M.When(m.at, now)))
      local subject = m.subject or Summary(m)
      if m.from ~= me then subject = subject .. " |cff808080from " .. m.from .. "|r" end
      row.subject:SetText(subject)
      local money = ""
      if m.cod > 0 then
        money = Soft("C.O.D. ") .. M.Coins(m.cod)
      elseif m.money > 0 then
        money = M.Coins(m.money)
      end
      row.money:SetText(money)
      Icon(row, m)
    end
  end
  empty:SetShown(#M.db.sent == 0)
  local owner = GameTooltip:IsShown() and GameTooltip:GetOwner()
  for _, row in ipairs(rows) do
    if owner == row then Tooltip(row) end
  end
end

local function Turn(by)
  page = math.max(1, page + by)
  M.Refresh()
end

-- as on the Inbox: Prev bottom left, Next bottom right
local function PageButton(label, by)
  local b = CreateFrame("Button", nil, panel)
  b:SetSize(32, 32)
  local side = by < 0 and "Prev" or "Next"
  b:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. side .. "Page-Up")
  b:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. side .. "Page-Down")
  b:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. side .. "Page-Disabled")
  b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  local text = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  text:SetText(label)
  if by < 0 then
    b:SetPoint("BOTTOMLEFT", 14, 10)
    text:SetPoint("LEFT", b, "RIGHT")
  else
    b:SetPoint("BOTTOMRIGHT", -14, 10)
    text:SetPoint("RIGHT", b, "LEFT")
  end
  b:SetScript("OnClick", function()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    Turn(by)
  end)
  return b
end

local function Create()
  if panel or not (SendMailFrame and MailFrame) then return end
  panel = CreateFrame("Frame", "MeioMailPanel", SendMailFrame, "ButtonFrameTemplate")
  ButtonFrameTemplate_HidePortrait(panel)
  if ButtonFrameTemplate_HideButtonBar then ButtonFrameTemplate_HideButtonBar(panel) end
  if panel.SetTitle then panel:SetTitle("Sent mail") end
  panel:SetSize(WIDTH, MailFrame:GetHeight())
  panel:EnableMouse(true)
  Anchor()
  if panel.CloseButton then
    panel.CloseButton:SetScript("OnClick", function() M.SetPanel(false) end)
  end

  local to = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  to:SetPoint("TOPLEFT", 60, -40)
  to:SetText("To, newest first")
  local sent = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  sent:SetPoint("TOPRIGHT", -18, -40)
  sent:SetText("Sent")

  local n = math.max(4, math.floor((MailFrame:GetHeight() - TOP - BOTTOM) / ROW_H))
  for i = 1, n do rows[i] = Row(i) end
  prevButton = PageButton("Prev", -1)
  nextButton = PageButton("Next", 1)
  panel:EnableMouseWheel(true)
  panel:SetScript("OnMouseWheel", function(_, delta) Turn(-delta) end)

  empty = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  empty:SetPoint("TOPLEFT", 20, -TOP - 8)
  empty:SetPoint("RIGHT", -20, 0)
  empty:SetJustifyH("LEFT")
  empty:SetText("Mail you send shows here.")

  panel:SetScript("OnShow", function() page = 1 Anchor() M.Refresh() end)
  if OpenMailFrame then
    OpenMailFrame:HookScript("OnShow", Anchor)
    OpenMailFrame:HookScript("OnHide", Anchor)
  end
  M.Refresh()
end

function M.OnAddonLoaded(name)
  if name == "Blizzard_MailFrame" or name == "MeioMail" then Create() end
end

function M.OnMailShow() Create() end
