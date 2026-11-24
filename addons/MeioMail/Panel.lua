-- The sent mail list beside the mailbox, on the Send tab only (the Inbox's open letter,
-- OpenMailFrame, takes the same spot). Parented to SendMailFrame so it follows that tab.
local _, M = ...

local WIDTH = 290
local ROW_H = 32
local TOP, BOTTOM = 62, 14

local panel, empty
local rows = {}

local function Label(text) return NORMAL_FONT_COLOR:WrapTextInColorCode(text) end

local function Tooltip(row)
  local m = row.mail
  if not m then return end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:AddLine("To " .. M.To(m))
  if m.subject then GameTooltip:AddLine(m.subject, 1, 1, 1, true) end
  for _, it in ipairs(m.items) do
    GameTooltip:AddDoubleLine(it.link, "x" .. it.count, 1, 1, 1, 1, 1, 1)
  end
  if m.money > 0 then GameTooltip:AddDoubleLine(Label("Money"), M.Money(m.money)) end
  if m.cod > 0 then GameTooltip:AddDoubleLine(Label("COD"), M.Money(m.cod)) end
  local sent = M.When(m.at, time())
  if m.from ~= UnitName("player") then sent = sent .. " from " .. m.from end
  GameTooltip:AddDoubleLine(Label("Sent"), sent, nil, nil, nil, 1, 1, 1)
  GameTooltip:Show()
end

local function Row(i)
  local row = CreateFrame("Button", nil, panel)
  row:SetHeight(ROW_H)
  row:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -TOP - (i - 1) * ROW_H)
  row:SetPoint("RIGHT", panel, "RIGHT", -12, 0)
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
  row.to = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.to:SetPoint("TOPLEFT", 4, -3)
  row.sent = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.sent:SetPoint("TOPRIGHT", -4, -4)
  row.to:SetPoint("RIGHT", row.sent, "LEFT", -6, 0)
  row.to:SetJustifyH("LEFT")
  row.to:SetWordWrap(false)
  row.what = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.what:SetPoint("BOTTOMLEFT", 4, 3)
  row.what:SetPoint("BOTTOMRIGHT", -4, 3)
  row.what:SetJustifyH("LEFT")
  row.what:SetWordWrap(false)
  row:SetScript("OnEnter", Tooltip)
  row:SetScript("OnLeave", GameTooltip_Hide)
  return row
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
  for i, row in ipairs(rows) do
    local m = M.db.sent[i]
    row.mail = m
    row:SetShown(m ~= nil)
    if m then
      row.to:SetText(M.To(m))
      row.sent:SetText(M.When(m.at, now))
      local what = M.Contents(m)
      if m.from ~= me then what = what .. " |cff999999from " .. m.from .. "|r" end
      row.what:SetText(what)
    end
  end
  empty:SetShown(#M.db.sent == 0)
  local owner = GameTooltip:IsShown() and GameTooltip:GetOwner()
  for _, row in ipairs(rows) do
    if owner == row then Tooltip(row) end
  end
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
  to:SetPoint("TOPLEFT", 18, -40)
  to:SetText("To, newest first")
  local sent = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  sent:SetPoint("TOPRIGHT", -18, -40)
  sent:SetText("Sent")

  local n = math.max(4, math.floor((MailFrame:GetHeight() - TOP - BOTTOM) / ROW_H))
  for i = 1, n do rows[i] = Row(i) end

  empty = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  empty:SetPoint("TOPLEFT", 20, -TOP - 8)
  empty:SetPoint("RIGHT", -20, 0)
  empty:SetJustifyH("LEFT")
  empty:SetText("Mail you send shows here.")

  panel:SetScript("OnShow", function() Anchor() M.Refresh() end)
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
