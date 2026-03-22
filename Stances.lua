-- Stance state is set during DrawPage/Set() via GetShapeshiftFormInfo
-- Real-time updates happen via PLAYER_AURAS_CHANGED which triggers a redraw

local stanceTracker = CreateFrame("Frame")
stanceTracker:RegisterEvent("PLAYER_AURAS_CHANGED")

stanceTracker:SetScript("OnEvent", function()
    if not ModernSpellBookFrame:IsVisible() then return end
    if not ModernSpellBookFrame.stanceButtons then return end

    local activeName = nil
    for i = 1, 20 do
        local texture, name, isActive, isCastable = GetShapeshiftFormInfo(i)
        if not texture then break end
        if isActive then
            activeName = name
            break
        end
    end

    for stanceName, stanceButton in pairs(ModernSpellBookFrame.stanceButtons) do
        stanceButton:SetStance(stanceName == activeName)
    end
end)
