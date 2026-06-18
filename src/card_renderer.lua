-- Card renderer: draws cards with rounded rects, text, and simple animations
-- Replaces SpriteKit CardNode + CardTableScene

local Card = require("src.models.card")
local Modifier = require("src.models.modifiers")

local Renderer = {}

-- Layout constants
Renderer.CARD_W = 72
Renderer.CARD_H = 108
Renderer.CARD_CORNER = 8
Renderer.CARD_SPACING = 84
Renderer.DEALER_Y = 120
Renderer.PLAYER_Y = -120

-- Accent colors
Renderer.AccentColor = {
    dustyGreen = { r = 0.44, g = 0.60, b = 0.50 },
    slateBlue  = { r = 0.45, g = 0.52, b = 0.72 },
    warmOchre  = { r = 0.76, g = 0.62, b = 0.38 },
}

Renderer.FeltColor = {
    dustyGreen = { r = 0.07, g = 0.13, b = 0.09 },
    slateBlue  = { r = 0.07, g = 0.08, b = 0.16 },
    warmOchre  = { r = 0.14, g = 0.10, b = 0.06 },
}

function Renderer.getAccent(name)
    return Renderer.AccentColor[name] or Renderer.AccentColor.dustyGreen
end

function Renderer.getFeltColor(name, tinted)
    if tinted then
        return Renderer.FeltColor[name] or Renderer.FeltColor.dustyGreen
    end
    return { r = 0.07, g = 0.07, b = 0.07 }
end

-- Helper: convert color table to LÖVE2D color values
local function color(c, alpha)
    return c.r, c.g, c.b, alpha or 1
end

-- Draw a rounded rectangle card shape
function Renderer.drawCardShape(x, y, w, h, radius, fillR, fillG, fillB, fillA, strokeR, strokeG, strokeB, strokeA, lineWidth)
    lineWidth = lineWidth or 1
    -- Fill
    love.graphics.setColor(fillR, fillG, fillB, fillA or 1)
    love.graphics.rectangle("fill", x, y, w, h, radius, radius, radius, radius)
    -- Stroke
    if strokeR then
        love.graphics.setColor(strokeR, strokeG, strokeB, strokeA or 1)
        love.graphics.setLineWidth(lineWidth)
        love.graphics.rectangle("line", x, y, w, h, radius, radius, radius, radius)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a standard playing card face
function Renderer.drawCardFace(card, x, y, w, h)
    w = w or Renderer.CARD_W
    h = h or Renderer.CARD_H
    local radius = Renderer.CARD_CORNER

    -- Background
    Renderer.drawCardShape(x, y, w, h, radius, 0.97, 0.97, 0.97, 1, 0.85, 0.85, 0.85, 1, 1)

    -- Rank (top-left)
    local rankName = Card.RankNames[card.rank] or "?"
    local isRed = Card.isRed(card.suit)
    local textCol = isRed and { 0.8, 0.15, 0.15 } or { 0.1, 0.1, 0.1 }

    love.graphics.setColor(textCol[1], textCol[2], textCol[3], 1)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print(rankName, x + 6, y + 4)

    -- Suit symbol (center)
    local symbol = Card.SuitSymbol[card.suit] or "?"
    love.graphics.setFont(love.graphics.newFont(28))
    local symW = love.graphics.getFont():getWidth(symbol)
    love.graphics.print(symbol, x + (w - symW) / 2, y + (h - 28) / 2)

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a voyage card face (dark, distinct)
function Renderer.drawVoyageCardFace(card, x, y, w, h, accentName)
    w = w or Renderer.CARD_W
    h = h or Renderer.CARD_H
    local radius = Renderer.CARD_CORNER
    local accent = Renderer.getAccent(accentName)

    -- Dark background with accent border
    Renderer.drawCardShape(x, y, w, h, radius, 0.08, 0.08, 0.08, 1,
        accent.r, accent.g, accent.b, 0.6, 1.2)

    local effect = card.voyageEffect
    local displayText
    if effect == "fogBank" then
        displayText = card.fogRevealed and tostring(card.fogValue or 7) or "?"
    else
        displayText = require("src.models.voyage_card").Icon[effect] or "?"
    end

    -- Icon (center)
    love.graphics.setColor(accent.r, accent.g, accent.b, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    local tw = love.graphics.getFont():getWidth(displayText)
    love.graphics.print(displayText, x + (w - tw) / 2, y + (h - 24) / 2 - 8)

    -- Name (bottom)
    local name = require("src.models.voyage_card").DisplayName[effect] or ""
    love.graphics.setFont(love.graphics.newFont(7))
    local nw = love.graphics.getFont():getWidth(name:upper())
    love.graphics.setColor(0.45, 0.45, 0.45, 1)
    love.graphics.print(name:upper(), x + (w - nw) / 2, y + h - 18)

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a card back (standard: accent-tinted border)
function Renderer.drawCardBack(x, y, w, h, accentName)
    w = w or Renderer.CARD_W
    h = h or Renderer.CARD_H
    local radius = Renderer.CARD_CORNER
    local accent = Renderer.getAccent(accentName)

    Renderer.drawCardShape(x, y, w, h, radius,
        accent.r * 0.18, accent.g * 0.18, accent.b * 0.18, 1,
        accent.r, accent.g, accent.b, 0.4, 1)

    -- Inner border
    local inset = 6
    love.graphics.setColor(accent.r, accent.g, accent.b, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x + inset, y + inset, w - inset * 2, h - inset * 2, radius - 2, radius - 2, radius - 2, radius - 2)

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a card (auto-detects face/back/voyage)
function Renderer.drawCard(card, x, y, w, h, accentName)
    if card.isFaceDown then
        Renderer.drawCardBack(x, y, w, h, accentName)
    elseif card.voyageEffect then
        Renderer.drawVoyageCardFace(card, x, y, w, h, accentName)
    else
        Renderer.drawCardFace(card, x, y, w, h)
    end
end

-- Draw the felt background
function Renderer.drawFelt(accentName, tinted, width, height)
    local fc = Renderer.getFeltColor(accentName, tinted)
    love.graphics.setColor(fc.r, fc.g, fc.b, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)

    -- Subtle felt lines
    love.graphics.setColor(1, 1, 1, 0.02)
    for i = -3, 3 do
        local y = height / 2 + i * 60
        love.graphics.rectangle("fill", 0, y, width, 1)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Fust flash overlay
function Renderer.drawFustFlash(alpha)
    love.graphics.setColor(0.75, 0.15, 0.15, alpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    love.graphics.setColor(1, 1, 1, 1)
end

return Renderer