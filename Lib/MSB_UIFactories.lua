-- MSB_UIFactories.lua
-- Reusable factory functions for common UI elements: Glow frames, Badge frames.

function MSB_CreateGlow(parent, size, color, frameLevel, texture)
    local glowFrame = CreateFrame("Frame", nil, parent)
    glowFrame:SetWidth(size)
    glowFrame:SetHeight(size)
    glowFrame:SetFrameLevel(parent:GetFrameLevel() + (frameLevel or 5))
    glowFrame:Hide()

    local glowTex = glowFrame:CreateTexture(nil, "OVERLAY")
    glowTex:SetAllPoints(glowFrame)
    glowTex:SetTexture(texture or "Interface\\Buttons\\CheckButtonGlow")
    glowTex:SetBlendMode("ADD")
    if color then
        glowTex:SetVertexColor(color[1], color[2], color[3])
    end
    glowTex:SetAlpha(1)

    return glowFrame, glowTex
end

function MSB_CreateBadge(parent, text, bgColor, borderColor, frameLevel)
    local badge = CreateFrame("Frame", nil, parent)
    badge:SetWidth(32)
    badge:SetHeight(14)
    badge:SetFrameLevel(parent:GetFrameLevel() + (frameLevel or 7))
    badge:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    badge:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    badge:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
    badge:Hide()

    local badgeText = badge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    badgeText:SetPoint("CENTER", badge, "CENTER", 0, 1)
    badgeText:SetText(text)
    badgeText:SetFont("Fonts\\FRIZQT__.TTF", 8)
    badgeText:SetTextColor(1, 1, 1)

    return badge, badgeText
end
