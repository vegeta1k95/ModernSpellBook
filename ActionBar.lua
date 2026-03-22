function ModernSpellBookFrame:ShowActionButtonGrid(button)
    if ActionButton_ShowGrid == nil then return end
    -- In vanilla, use direct approach instead of SetAttribute for showgrid
    if button.GetAttribute and button:GetAttribute("showgrid") then
        button:SetAttribute("showgrid", button:GetAttribute("showgrid") + 1)
    end
    ActionButton_ShowGrid(button)
end

function ModernSpellBookFrame:HideActionButtonGrid(button)
    if ActionButton_ShowGrid == nil then return end
    if button.GetAttribute and button:GetAttribute("showgrid") then
        local showgrid = button:GetAttribute("showgrid")
        if showgrid > 0 then
            button:SetAttribute("showgrid", showgrid - 1)
        end
    end
    ActionButton_HideGrid(button)
end

function ModernSpellBookFrame:ShowAllMultiActionBarGrids()
    ModernSpellBookFrame:UpdateMultiActionBarGrid("MultiBarBottomLeft", true)
    ModernSpellBookFrame:UpdateMultiActionBarGrid("MultiBarBottomRight", true)
    ModernSpellBookFrame:UpdateMultiActionBarGrid("MultiBarRight", true)
    ModernSpellBookFrame:UpdateMultiActionBarGrid("MultiBarLeft", true)
end

function ModernSpellBookFrame:HideAllMultiActionBarGrids()
    ModernSpellBookFrame:UpdateMultiActionBarGrid("MultiBarBottomLeft", false)
    ModernSpellBookFrame:UpdateMultiActionBarGrid("MultiBarBottomRight", false)
    ModernSpellBookFrame:UpdateMultiActionBarGrid("MultiBarRight", false)
    ModernSpellBookFrame:UpdateMultiActionBarGrid("MultiBarLeft", false)
end

function ModernSpellBookFrame:UpdateMultiActionBarGrid(barName, show)
    local numButtons = NUM_MULTIBAR_BUTTONS or 12
    for i = 1, numButtons do
        local button = _G[barName.."Button"..i];

        if button then
            if ( show and not button.noGrid) then
                ModernSpellBookFrame:ShowActionButtonGrid(button)
            else
                ModernSpellBookFrame:HideActionButtonGrid(button)
            end
        end
    end
end
