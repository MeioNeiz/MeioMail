-- Esc > Options > AddOns > MeioMail
local _, M = ...

local category

function M.RegisterSettings()
  if category or not (Settings and Settings.RegisterVerticalLayoutCategory) then return end
  local layout
  category, layout = Settings.RegisterVerticalLayoutCategory("MeioMail")
  local panel = Settings.RegisterAddOnSetting(category, "MEIOMAIL_PANEL", "panel", M.db,
    Settings.VarType.Boolean, "List at mailbox", true)
  Settings.CreateCheckbox(category, panel, "At the mailbox's Send tab, a list of the mail "
    .. "you sent (hover a row for what was in it). /meiomail panel on||off")
  if panel.SetValueChangedCallback then
    panel:SetValueChangedCallback(function() M.Changed() end)
  end
  if CreateSettingsButtonInitializer and layout then
    layout:AddInitializer(CreateSettingsButtonInitializer("Sent mail", "List in chat",
      function() M.List() end, "Prints the mail you sent. /sent", true))
  end
  Settings.RegisterAddOnCategory(category)
end

function M.OpenSettings()
  if not (category and Settings and Settings.OpenToCategory) then return false end
  Settings.OpenToCategory(category:GetID())
  return true
end
