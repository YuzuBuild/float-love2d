-- card_renderer.lua — visual rendering of playing cards and the felt.
-- Pure presentation. No game logic. Designed for portrait mobile (390x844).
--
-- Style notes:
--   * Cards are white-faced, with a soft drop shadow, rounded corners, and
--     a small rank + large suit. Suits are color-coded red/black.
--   * Voyage cards are dark, accent-bordered, icon-forward.
--   * Card backs are patterned with the run's accent color.
--   * The felt is a vertical gradient, tinted by the run accent, with a
--     few subtle horizontal lines for texture.
--
-- All functions are pure: they take positions + the accent name string
-- (e.g. "dustyGreen") and draw via love.graphics. They never mutate
-- love.graphics state beyond the color (which is always reset to white
-- at the end of each public function).

local Card = require("src.models.card")
local Modifier = require("src.models.modifiers")

local Renderer = {}

-- ----------------------------------------------------------------------------
-- Layout
-- ----------------------------------------------------------------------------

-- Mobile-friendly playing card aspect (2.5 : 3.5). Width fixed at 68.
Renderer.CARD_W = 68
Renderer.CARD_H = 95
Renderer.CARD_CORNER = 6
Renderer.CARD_SPACING = 78
Renderer.DEALER_Y = 130
Renderer.PLAYER_Y = 110

-- ----------------------------------------------------------------------------
-- Color palette
-- ----------------------------------------------------------------------------

-- Three run identity accents. Picked once per voyage and referenced by name.
Renderer.AccentColor = {
    dustyGreen = { r = 0.44, g = 0.60, b = 0.50 },
    slateBlue  = { r = 0.45, g = 0.52, b = 0.72 },
    warmOchre  = { r = 0.78, g = 0.64, b = 0.38 },
}

-- Base felt tints per accent. These are the "deep" stops the gradient uses.
Renderer.FeltColor = {
    dustyGreen = { r = 0.06, g = 0.11, b = 0.08 },
    slateBlue  = { r = 0.05, g = 0.07, b = 0.13 },
    warmOchre  = { r = 0.12, g = 0.09, b = 0.05 },
}

-- Neutral near-black for everything that should not pull accent color.
Renderer.Neutral = { r = 0.045, g = 0.05, b = 0.06 }

-- ----------------------------------------------------------------------------
-- Accessors
-- ----------------------------------------------------------------------------

function Renderer.getAccent(name)
    return Renderer.AccentColor[name] or Renderer.AccentColor.dustyGreen
end

function Renderer.getFeltColor(name)
    return Renderer.FeltColor[name] or Renderer.FeltColor.dustyGreen
end

-- ----------------------------------------------------------------------------
-- Internal helpers
-- ----------------------------------------------------------------------------

-- Draw a rounded rectangle. Either filled, stroked, or both.
--   mode = "fill" | "line" | "both"
local function roundedRect(x, y, w, h, r, mode, cr, cg, cb, ca, lw)
    if mode == "fill" or mode == "both" then
        love.graphics.setColor(cr, cg, cb, ca or 1)
        love.graphics.rectangle("fill", x, y, w, h, r, r, r, r)
    end
    if mode == "line" or mode == "both" then
        love.graphics.setColor(cr, cg, cb, ca or 1)
        love.graphics.setLineWidth(lw or 1)
        love.graphics.rectangle("line", x, y, w, h, r, r, r, r)
    end
end

-- Lerp helper
local function lerp(a, b, t) return a + (b - a) * t end
local function mixColor(c1, c2, t)
    return {
        r = lerp(c1.r, c2.r, t),
        g = lerp(c1.g, c2.g, t),
        b = lerp(c1.b, c2.b, t),
    }
end

-- ----------------------------------------------------------------------------
-- Public drawing helpers
-- ----------------------------------------------------------------------------

-- Draw a soft drop shadow underneath a card. Use before drawing the card.
--   intensity: 0..1, how dark the shadow is. Default 0.35.
function Renderer.drawShadow(x, y, w, h, intensity)
    intensity = intensity or 0.35
    local pad = 3
    love.graphics.setColor(0, 0, 0, intensity)
    love.graphics.rectangle("fill",
        x + pad, y + pad + 1, w, h,
        Renderer.CARD_CORNER, Renderer.CARD_CORNER,
        Renderer.CARD_CORNER, Renderer.CARD_CORNER)
    -- softer second pass offset further for ambient occlusion
    love.graphics.setColor(0, 0, 0, intensity * 0.4)
    love.graphics.rectangle("fill",
        x + pad - 1, y + pad + 3, w + 2, h + 1,
        Renderer.CARD_CORNER, Renderer.CARD_CORNER,
        Renderer.CARD_CORNER, Renderer.CARD_CORNER)
end

-- ----------------------------------------------------------------------------
-- Playing card face (the white card with rank + suit)
-- ----------------------------------------------------------------------------

-- Draw a suit symbol as a vector shape (avoids Unicode font issues)
-- cx, cy = center; size = overall width
local function drawSuit(suit, cx, cy, size, r, g, b)
    love.graphics.setColor(r, g, b, 1)
    local s = size

    if suit == "hearts" then
        -- Two circles + triangle
        love.graphics.circle("fill", cx - s * 0.22, cy - s * 0.12, s * 0.28)
        love.graphics.circle("fill", cx + s * 0.22, cy - s * 0.12, s * 0.28)
        love.graphics.polygon("fill",
            cx - s * 0.48, cy - s * 0.05,
            cx + s * 0.48, cy - s * 0.05,
            cx, cy + s * 0.48)

    elseif suit == "diamonds" then
        -- Rotated square
        love.graphics.polygon("fill",
            cx, cy - s * 0.5,
            cx + s * 0.35, cy,
            cx, cy + s * 0.5,
            cx - s * 0.35, cy)

    elseif suit == "clubs" then
        -- Three circles + stem
        love.graphics.circle("fill", cx, cy - s * 0.25, s * 0.26)
        love.graphics.circle("fill", cx - s * 0.28, cy + s * 0.08, s * 0.26)
        love.graphics.circle("fill", cx + s * 0.28, cy + s * 0.08, s * 0.26)
        love.graphics.polygon("fill",
            cx - s * 0.12, cy + s * 0.15,
            cx + s * 0.12, cy + s * 0.15,
            cx + s * 0.2, cy + s * 0.5,
            cx - s * 0.2, cy + s * 0.5)

    elseif suit == "spades" then
        -- Inverted heart + stem
        love.graphics.circle("fill", cx - s * 0.22, cy + s * 0.12, s * 0.28)
        love.graphics.circle("fill", cx + s * 0.22, cy + s * 0.12, s * 0.28)
        love.graphics.polygon("fill",
            cx - s * 0.48, cy + s * 0.05,
            cx + s * 0.48, cy + s * 0.05,
            cx, cy - s * 0.48)
        -- Stem
        love.graphics.polygon("fill",
            cx - s * 0.14, cy + s * 0.3,
            cx + s * 0.14, cy + s * 0.3,
            cx + s * 0.22, cy + s * 0.5,
            cx - s * 0.22, cy + s * 0.5)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Renderer.drawCardFace(card, x, y, w, h)
    w = w or Renderer.CARD_W
    h = h or Renderer.CARD_H
    local radius = Renderer.CARD_CORNER

    -- Shadow
    Renderer.drawShadow(x, y, w, h, 0.32)

    -- Card body: white with a subtle off-white tint for warmth
    roundedRect(x, y, w, h, radius, "fill", 0.985, 0.978, 0.965, 1)
    -- Thin border to crisp the edge
    love.graphics.setColor(0.78, 0.74, 0.66, 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, radius, radius, radius, radius)

    local rankName = Card.RankNames[card.rank] or "?"
    local isRed = Card.isRed(card.suit)
    local r, g, b = isRed and 0.78 or 0.12, isRed and 0.13 or 0.12, isRed and 0.16 or 0.14

    -- Top-left rank (text)
    local smallFont = love.graphics.newFont(13)
    love.graphics.setFont(smallFont)
    love.graphics.setColor(r, g, b, 1)
    love.graphics.print(rankName, x + 5, y + 4)

    -- Small suit in top-left corner (below rank)
    drawSuit(card.suit, x + 11, y + 22, 10, r, g, b)

    -- Bottom-right rank (rotated 180°)
    love.graphics.push()
    love.graphics.translate(x + w - 5, y + h - 4)
    love.graphics.rotate(math.rad(180))
    love.graphics.print(rankName, 0, -14)
    love.graphics.pop()

    -- Small suit in bottom-right corner (rotated)
    love.graphics.push()
    love.graphics.translate(x + w - 11, y + h - 22)
    love.graphics.rotate(math.rad(180))
    drawSuit(card.suit, 0, 0, 10, r, g, b)
    love.graphics.pop()

    -- Big suit centered
    drawSuit(card.suit, x + w / 2, y + h / 2 + 2, 28, r, g, b)

    love.graphics.setColor(1, 1, 1, 1)
end

-- ----------------------------------------------------------------------------
-- Voyage card face — dark with accent border
-- ----------------------------------------------------------------------------

function Renderer.drawVoyageCardFace(card, x, y, w, h, accentName)
    w = w or Renderer.CARD_W
    h = h or Renderer.CARD_H
    local radius = Renderer.CARD_CORNER
    local accent = Renderer.getAccent(accentName)

    Renderer.drawShadow(x, y, w, h, 0.4)

    -- Card body: very dark
    roundedRect(x, y, w, h, radius, "fill", 0.08, 0.09, 0.11, 1)
    -- Accent border
    love.graphics.setColor(accent.r, accent.g, accent.b, 0.9)
    love.graphics.setLineWidth(1.4)
    love.graphics.rectangle("line", x, y, w, h, radius, radius, radius, radius)

    -- Inner accent stripe
    local inset = 4
    love.graphics.setColor(accent.r, accent.g, accent.b, 0.35)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line",
        x + inset, y + inset, w - inset * 2, h - inset * 2,
        radius - 1, radius - 1, radius - 1, radius - 1)

    -- Decide what to show
    local effect = card.voyageEffect
    local VoyageCard = require("src.models.voyage_card")

    local displayText
    if effect == "fogBank" then
        displayText = card.fogRevealed and tostring(card.fogValue or 7) or "?"
    else
        -- Use short text labels instead of Unicode icons
        local labels = { deadweight = "13", undertow = "0", squall = "3" }
        displayText = labels[effect] or "?"
    end

    -- Big icon centered
    local bigFont = love.graphics.newFont(26)
    love.graphics.setFont(bigFont)
    love.graphics.setColor(accent.r, accent.g, accent.b, 1)
    local tw = bigFont:getWidth(displayText)
    love.graphics.print(displayText, x + (w - tw) / 2, y + (h - 26) / 2 - 10)

    -- Name at the bottom
    local name = VoyageCard.DisplayName[effect] or ""
    local labelFont = love.graphics.newFont(8)
    love.graphics.setFont(labelFont)
    local upper = name:upper()
    local nw = labelFont:getWidth(upper)
    love.graphics.setColor(0.85, 0.85, 0.85, 0.85)
    love.graphics.print(upper, x + (w - nw) / 2, y + h - 16)

    love.graphics.setColor(1, 1, 1, 1)
end

-- ----------------------------------------------------------------------------
-- Card back — patterned, accent-tinted
-- ----------------------------------------------------------------------------

function Renderer.drawCardBack(x, y, w, h, accentName)
    w = w or Renderer.CARD_W
    h = h or Renderer.CARD_H
    local radius = Renderer.CARD_CORNER
    local accent = Renderer.getAccent(accentName)

    Renderer.drawShadow(x, y, w, h, 0.32)

    -- Base
    roundedRect(x, y, w, h, radius, "fill",
        accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 1)

    -- Border
    love.graphics.setColor(accent.r, accent.g, accent.b, 0.75)
    love.graphics.setLineWidth(1.2)
    love.graphics.rectangle("line", x, y, w, h, radius, radius, radius, radius)

    -- Inner border
    local inset = 5
    love.graphics.setColor(accent.r, accent.g, accent.b, 0.45)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line",
        x + inset, y + inset, w - inset * 2, h - inset * 2,
        radius - 1, radius - 1, radius - 1, radius - 1)

    -- Diamond pattern across the face
    love.graphics.setColor(accent.r, accent.g, accent.b, 0.35)
    love.graphics.setLineWidth(1)
    local step = 8
    for row = 0, math.floor(h / step) do
        for col = 0, math.floor(w / step) do
            local cx = x + 4 + col * step + (row % 2) * (step / 2)
            local cy = y + 4 + row * step
            if cx < x + w - 4 and cy < y + h - 4 then
                love.graphics.points(cx, cy)
            end
        end
    end

    -- Center motif: a small accent-tinted pip area
    local motifR = 5
    love.graphics.setColor(accent.r * 0.4, accent.g * 0.4, accent.b * 0.4, 0.9)
    love.graphics.circle("fill", x + w / 2, y + h / 2 - 4, motifR)
    love.graphics.setColor(accent.r, accent.g, accent.b, 0.9)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", x + w / 2, y + h / 2 - 4, motifR)

    love.graphics.setColor(1, 1, 1, 1)
end

-- ----------------------------------------------------------------------------
-- Card dispatcher
-- ----------------------------------------------------------------------------

function Renderer.drawCard(card, x, y, w, h, accentName)
    if card.isFaceDown then
        Renderer.drawCardBack(x, y, w, h, accentName)
    elseif card.voyageEffect then
        Renderer.drawVoyageCardFace(card, x, y, w, h, accentName)
    else
        Renderer.drawCardFace(card, x, y, w, h)
    end
end

-- ----------------------------------------------------------------------------
-- Felt — gradient + accent tint + subtle horizontal lines
-- ----------------------------------------------------------------------------

function Renderer.drawFelt(accentName, width, height)
    local felt = Renderer.getFeltColor(accentName)
    local accent = Renderer.getAccent(accentName)

    -- Top and bottom stops. Top is a touch lighter (atmospheric haze),
    -- bottom pulls the accent down for depth.
    local top = {
        r = math.min(1, felt.r + 0.04 + accent.r * 0.05),
        g = math.min(1, felt.g + 0.04 + accent.g * 0.05),
        b = math.min(1, felt.b + 0.04 + accent.b * 0.05),
    }
    local bot = {
        r = felt.r * 0.85 + accent.r * 0.04,
        g = felt.g * 0.85 + accent.g * 0.04,
        b = felt.b * 0.85 + accent.b * 0.04,
    }

    -- Vertical gradient: draw ~32 horizontal stripes
    local steps = 32
    for i = 0, steps - 1 do
        local t = i / (steps - 1)
        local c = mixColor(top, bot, t)
        love.graphics.setColor(c.r, c.g, c.b, 1)
        local y = i * (height / steps)
        love.graphics.rectangle("fill", 0, y, width, height / steps + 1)
    end

    -- Vignette: a soft radial-style darkening at the edges (cheap)
    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.rectangle("fill", 0, 0, width, 24)
    love.graphics.rectangle("fill", 0, height - 32, width, 32)

    -- Subtle horizontal lines (felt texture)
    love.graphics.setColor(1, 1, 1, 0.018)
    local lineSpacing = 48
    local y = lineSpacing
    while y < height do
        love.graphics.rectangle("fill", 0, y, width, 1)
        y = y + lineSpacing
    end

    -- Faint accent hue wash to keep the run's identity visible
    love.graphics.setColor(accent.r, accent.g, accent.b, 0.025)
    love.graphics.rectangle("fill", 0, 0, width, height)

    love.graphics.setColor(1, 1, 1, 1)
end

-- ----------------------------------------------------------------------------
-- Fust flash — red overlay for bust
-- ----------------------------------------------------------------------------

function Renderer.drawFustFlash(alpha)
    local w, h = love.graphics.getDimensions()
    -- Two-pass: a strong red wash + a deeper red vignette
    love.graphics.setColor(0.75, 0.15, 0.15, alpha * 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(0.45, 0.05, 0.05, alpha * 0.5)
    love.graphics.rectangle("fill", 0, 0, w, 40)
    love.graphics.rectangle("fill", 0, h - 60, w, 60)
    love.graphics.setColor(1, 1, 1, 1)
end

return Renderer
