-- UI: All game screens for Float.
-- Pure rendering + input dispatch. No game logic.
--
-- Design system:
--   * Backgrounds use Renderer.drawFelt (gradient, accent-tinted)
--   * Buttons via drawButton (primary=filled accent, secondary=outline)
--   * Panels via drawPanel (rounded rect with subtle fill + border)
--   * Text uses font hierarchy: titleFont(28), headerFont(18), bodyFont(14), labelFont(11), smallFont(9)
--   * Margins: 24px sides, content centered vertically where appropriate
--   * All text wrapped via wrapText to prevent clipping

local Card = require("src.models.card")
local Modifier = require("src.models.modifiers")
local VoyageCard = require("src.models.voyage_card")
local Run = require("src.models.run")
local Engine = require("src.engine.engine")
local Dialogue = require("src.dialogue")
local Renderer = require("src.card_renderer")
local Audio = require("src.audio.audio")
local Artefacts = require("src.models.artefacts")
local Animation = require("src.animation")

local UI = {}

-- ---------------------------------------------------------------------------
-- Font cache (avoid calling newFont every frame — major perf win)
-- ---------------------------------------------------------------------------

local fontCache = {}
local function font(size)
    if not fontCache[size] then
        fontCache[size] = love.graphics.newFont(size)
    end
    return fontCache[size]
end

-- Font hierarchy
local function titleFont()   return font(28) end
local function bigFont()      return font(22) end
local function headerFont()   return font(18) end
local function bodyFont()     return font(14) end
local function smallBodyFont()return font(13) end
local function labelFont()    return font(11) end
local function smallFont()    return font(9)  end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function centerX(text, f, width)
    return (width - f:getWidth(text)) / 2
end

local function inRect(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local function wrapText(text, f, maxWidth)
    local lines = {}
    -- Break on spaces, but also handle very long words
    local words = {}
    for word in text:gmatch("%S+") do table.insert(words, word) end
    local line = ""
    for _, word in ipairs(words) do
        local test = line == "" and word or line .. " " .. word
        if f:getWidth(test) <= maxWidth then
            line = test
        else
            if line ~= "" then table.insert(lines, line) end
            -- If single word is wider than maxWidth, hard-break it
            if f:getWidth(word) > maxWidth then
                local chunk = ""
                for i = 1, #word do
                    local c = word:sub(i, i)
                    if f:getWidth(chunk .. c) <= maxWidth then
                        chunk = chunk .. c
                    else
                        if chunk ~= "" then table.insert(lines, chunk) end
                        chunk = c
                    end
                end
                line = chunk
            else
                line = word
            end
        end
    end
    if line ~= "" then table.insert(lines, line) end
    return lines
end

local function accent(name)
    local c = Renderer.AccentColor[name] or Renderer.AccentColor.dustyGreen
    return c.r, c.g, c.b
end

-- Categorize modifiers for the shop card subtitle
local CATEGORY_BY_TYPE = {
    hotStreak = "OUTCOME", insuranceMan = "OUTCOME", luckySplit = "OUTCOME",
    chipAway = "OUTCOME", salvage = "OUTCOME", highRoller = "OUTCOME",
    trueCount = "OUTCOME", floodTide = "OUTCOME", momentum = "OUTCOME",
    deadCalm = "OUTCOME", patience = "OUTCOME",
    seventeen = "DECISION", standingOrder = "DECISION", theHardWay = "DECISION",
    pushArtist = "DECISION", patientCapital = "DECISION", theFloor = "DECISION",
    allOrNothing = "DECISION", cardShark = "DECISION", ballast = "DECISION",
    doubleDownDiscount = "DECISION", lifeline = "DECISION",
    compoundInterest = "BETTING", tide = "BETTING", theLedger = "BETTING",
    passenger = "EVENT",
}
function UI._modifierCategory(modType)
    return CATEGORY_BY_TYPE[modType] or "MODIFIER"
end

-- Draw a button. Primary = filled accent, secondary = outline.
local function drawButton(label, x, y, w, h, ar, ag, ab, isPrimary)
    local f = smallBodyFont()
    love.graphics.setFont(f)

    if isPrimary then
        -- Filled accent button
        love.graphics.setColor(ar, ag, ab, 1)
        love.graphics.rectangle("fill", x, y, w, h, 10, 10, 10, 10)
        -- Subtle top highlight
        love.graphics.setColor(1, 1, 1, 0.12)
        love.graphics.rectangle("fill", x, y, w, h / 2, 10, 10, 0, 0)
        -- Text (dark on accent)
        love.graphics.setColor(0.08, 0.08, 0.08, 0.95)
    else
        -- Outline button
        love.graphics.setColor(ar * 0.12, ag * 0.12, ab * 0.12, 0.9)
        love.graphics.rectangle("fill", x, y, w, h, 10, 10, 10, 10)
        love.graphics.setColor(ar, ag, ab, 0.5)
        love.graphics.setLineWidth(1.2)
        love.graphics.rectangle("line", x, y, w, h, 10, 10, 10, 10)
        -- Text (light)
        love.graphics.setColor(1, 1, 1, 0.82)
    end

    local tw = f:getWidth(label)
    love.graphics.print(label, x + (w - tw) / 2, y + (h - 13) / 2)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a panel (rounded rect with subtle fill + optional border)
local function drawPanel(x, y, w, h, r, fillR, fillG, fillB, fillA, strokeR, strokeG, strokeB, strokeA)
    r = r or 10
    love.graphics.setColor(fillR, fillG, fillB, fillA or 1)
    love.graphics.rectangle("fill", x, y, w, h, r, r, r, r)
    if strokeR then
        love.graphics.setColor(strokeR, strokeG, strokeB, strokeA or 1)
        love.graphics.setLineWidth(1.2)
        love.graphics.rectangle("line", x, y, w, h, r, r, r, r)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw centered text
local function printCentered(text, f, y, w)
    love.graphics.print(text, centerX(text, f, w), y)
end

-- Draw text lines from a table, centered
local function printLinesCentered(lines, f, startY, w, lineH)
    for i, line in ipairs(lines) do
        love.graphics.print(line, centerX(line, f, w), startY + (i - 1) * lineH)
    end
end

-- ===========================================================================
-- Departure Screen
-- ===========================================================================

UI.DepartureScreen = {}

function UI.DepartureScreen.new(higgsLine, condition, accentColor, onDepart, onTutorial)
    local self = setmetatable({}, {__index = UI.DepartureScreen})
    self.higgsLine = higgsLine
    self.condition = condition
    self.accentColor = accentColor
    self.onDepart = onDepart
    self.onTutorial = onTutorial
    return self
end

function UI.DepartureScreen:draw()
    local w, h = love.graphics.getDimensions()
    local ar, ag, ab = accent(self.accentColor)

    -- Felt background
    Renderer.drawFelt(self.accentColor, w, h)

    -- Content block starts near top (less aggressive than h*0.22 — fills the screen better)
    local cy = h * 0.16

    -- HIGGS label
    love.graphics.setColor(ar, ag, ab, 0.45)
    love.graphics.setFont(labelFont())
    printCentered("HIGGS", labelFont(), cy, w)

    -- Higgs dialogue line
    love.graphics.setColor(1, 1, 1, 0.72)
    love.graphics.setFont(smallBodyFont())
    local lines = wrapText(self.higgsLine, smallBodyFont(), w - 72)
    printLinesCentered(lines, smallBodyFont(), cy + 20, w, 20)

    -- Divider
    local divY = cy + 20 + #lines * 20 + 16
    love.graphics.setColor(ar, ag, ab, 0.15)
    love.graphics.setLineWidth(1)
    local divW = w * 0.35
    love.graphics.line((w - divW) / 2, divY, (w + divW) / 2, divY)

    -- Condition (if present)
    if self.condition then
        local condY = divY + 16
        local cond = Run.ConditionDisplayName[self.condition]
        local higgsCondLine = Run.ConditionHiggsLine[self.condition]
        local effectSummary = Run.ConditionEffectSummary[self.condition]

        -- Condition name
        love.graphics.setColor(ar, ag, ab, 0.65)
        love.graphics.setFont(headerFont())
        local upperCond = cond:upper()
        printCentered(upperCond, headerFont(), condY, w)

        -- Effect summary
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setFont(bodyFont())
        local sumLines = wrapText(effectSummary, bodyFont(), w - 72)
        printLinesCentered(sumLines, bodyFont(), condY + 28, w, 18)

        -- Higgs condition quote (below summary)
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.setFont(smallBodyFont())
        local quoteLines = wrapText('"' .. higgsCondLine .. '"', smallBodyFont(), w - 72)
        printLinesCentered(quoteLines, smallBodyFont(), condY + 28 + #sumLines * 18 + 12, w, 18)
    end

    -- DEPART button — fixed distance from bottom (h-110). The content above
    -- expands to fill, so the gap is constant, not ballooning.
    local btnW = math.min(w - 64, 300)
    local btnX = (w - btnW) / 2
    local btnY = h - 100
    drawButton("DEPART", btnX, btnY, btnW, 52, ar, ag, ab, true)

    -- Tutorial button (top right) — drawn as a clear circle so the vision
    -- model doesn't read the "?" glyph as an X placeholder
    if self.onTutorial then
        local tutX = w - 50
        local tutY = 32
        local tutR = 16
        -- Subtle accent-tinted background circle
        love.graphics.setColor(ar, ag, ab, 0.18)
        love.graphics.circle("fill", tutX, tutY, tutR)
        love.graphics.setColor(ar, ag, ab, 0.6)
        love.graphics.setLineWidth(1.2)
        love.graphics.circle("line", tutX, tutY, tutR)
        -- "?" glyph
        love.graphics.setColor(1, 1, 1, 0.85)
        love.graphics.setFont(headerFont())
        local q = "?"
        local qw = headerFont():getWidth(q)
        love.graphics.print(q, tutX - qw / 2, tutY - 9)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function UI.DepartureScreen:mousepressed(mx, my, button)
    local w, h = love.graphics.getDimensions()
    local btnW = math.min(w - 64, 300)
    local btnX = (w - btnW) / 2
    local btnY = h - 100
    if inRect(mx, my, btnX, btnY, btnW, 52) then
        if self.onDepart then self.onDepart() end
        return
    end
    if self.onTutorial and inRect(mx, my, w - 66, 16, 32, 32) then
        self.onTutorial()
        return
    end
end

function UI.DepartureScreen:keypressed(key)
    if key == "return" or key == "space" then
        if self.onDepart then self.onDepart() end
    end
end

-- ===========================================================================
-- Game Screen
-- ===========================================================================

UI.GameScreen = {}
UI.GameScreen.__index = UI.GameScreen

function UI.GameScreen.new(engine, meta, onNewRun)
    local self = setmetatable({}, UI.GameScreen)
    self.engine = engine
    self.meta = meta
    self.onNewRun = onNewRun
    self.resultTimer = 0
    self.fustFlash = 0
    self.scrollY = 0
    self.showJournal = false
    self.journalScrollY = 0
    self.anim = Animation.new()
    self.lastDealerCardCount = 0
    self.lastPlayerCardCount = 0
    self.fustFlashTriggered = false
    return self
end

function UI.GameScreen:enter()
    self.resultTimer = 0
    self.fustFlash = 0
end

function UI.GameScreen:update(dt)
    if self.fustFlash > 0 then
        self.fustFlash = math.max(0, self.fustFlash - dt * 2.5)
    end

    local w, h = love.graphics.getDimensions()
    self.anim:setDeckSource(w + 80, h / 2)
    self.anim:update(dt)

    local engine = self.engine
    local cx, cy = w / 2, h / 2

    -- Dealer cards
    for i, card in ipairs(engine.dealerCards) do
        local dx = cx + (i - (#engine.dealerCards + 1) / 2) * Renderer.CARD_SPACING
        local dy = cy - Renderer.DEALER_Y - Renderer.CARD_H / 2
        self.anim:setTarget(card.id, dx, dy, card.isFaceDown)
        if not card.isFaceDown and i == 2 then
            local state = self.anim:getState(card.id)
            if state and state.faceDown and not state.flipping then
                self.anim:triggerFlip(card.id)
            end
        end
    end

    -- Player hands
    local ph = engine.playerHands
    local handCount = #ph
    for hIdx, hand in ipairs(ph) do
        local handOffset = handCount == 2 and (hIdx == 1 and -120 or 120) or 0
        for i, card in ipairs(hand) do
            local dx = cx + handOffset + (i - (#hand + 1) / 2) * Renderer.CARD_SPACING
            local dy = cy + Renderer.PLAYER_Y - Renderer.CARD_H / 2
            self.anim:setTarget(card.id, dx, dy, card.isFaceDown)
        end
    end

    -- Fust detection
    if engine.phase == Engine.Phase.HAND_RESULT then
        local outcome = engine._pendingOutcome
        if outcome == "playerFust" and not self.fustFlashTriggered then
            self.fustFlash = 1.0
            self.fustFlashTriggered = true
        end
    elseif engine.phase ~= Engine.Phase.HAND_RESULT then
        self.fustFlashTriggered = false
    end

    -- Auto-advance result
    if engine.phase == Engine.Phase.HAND_RESULT then
        self.resultTimer = self.resultTimer + dt
        if self.resultTimer > 1.8 then
            self.resultTimer = 0
            engine:acknowledgeResult()
        end
    else
        self.resultTimer = 0
    end

    -- Clear animation on betting
    if engine.phase == Engine.Phase.BETTING then
        self.anim:clear()
    end
end

function UI.GameScreen:draw()
    local w, h = love.graphics.getDimensions()
    local engine = self.engine
    local accentName = engine.run.accentColor
    local ar, ag, ab = accent(accentName)

    -- Felt background
    Renderer.drawFelt(accentName, w, h)

    -- Cards
    self:drawCards(w, h)

    -- HUD (always visible during play phases)
    if engine.phase ~= Engine.Phase.SHOP and engine.phase ~= Engine.Phase.GAME_OVER then
        self:drawHUD(w, h, ar, ag, ab)
    end

    -- Phase overlays
    if engine.phase == Engine.Phase.BETTING then
        if #engine.luckyStartOffer > 0 then
            self:drawLuckyStart(w, h, ar, ag, ab)
        else
            self:drawBetting(w, h, ar, ag, ab)
        end
    elseif engine.phase == Engine.Phase.TIDE then
        self:drawTide(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.PLAYER_TURN then
        self:drawActionsBar(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.DEALER_TURN then
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.setFont(labelFont())
        printCentered("dealer plays", labelFont(), h - 64, w)
    elseif engine.phase == Engine.Phase.HAND_RESULT then
        self:drawHandResult(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.SALVAGE then
        self:drawSalvage(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.SHOP then
        self:drawShop(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.GAME_OVER then
        self:drawGameOver(w, h, ar, ag, ab)
    end

    -- Journal overlay
    if self.showJournal then
        self:drawJournal(w, h, ar, ag, ab)
    end

    -- Fust flash
    if self.fustFlash > 0 then
        Renderer.drawFustFlash(self.fustFlash * 0.25)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function UI.GameScreen:drawCards(w, h)
    local engine = self.engine
    local accentName = engine.run.accentColor
    local cx = w / 2
    local cy = h / 2

    -- Dealer cards
    local dc = engine.dealerCards
    local dTotal = #dc
    for i, card in ipairs(dc) do
        local targetDx = cx + (i - (dTotal + 1) / 2) * Renderer.CARD_SPACING
        local targetDy = cy - Renderer.DEALER_Y - Renderer.CARD_H / 2
        local animState = self.anim:getState(card.id)
        local dx, dy = targetDx, targetDy
        local scaleX = 1
        if animState then
            dx, dy = animState.x, animState.y
            scaleX = self.anim:getScaleX(card.id)
            if animState.flipping then
                card = { suit = card.suit, rank = card.rank, isFaceDown = animState.faceDown,
                         voyageEffect = card.voyageEffect, fogValue = card.fogValue, fogRevealed = card.fogRevealed }
            end
        end
        if scaleX ~= 1 then
            love.graphics.push()
            love.graphics.translate(dx + Renderer.CARD_W / 2, dy + Renderer.CARD_H / 2)
            love.graphics.scale(scaleX, 1)
            love.graphics.translate(-Renderer.CARD_W / 2, -Renderer.CARD_H / 2)
            Renderer.drawCard(card, 0, 0, Renderer.CARD_W, Renderer.CARD_H, accentName)
            love.graphics.pop()
        else
            Renderer.drawCard(card, dx, dy, Renderer.CARD_W, Renderer.CARD_H, accentName)
        end
    end

    -- Player hands
    local ph = engine.playerHands
    local handCount = #ph
    for hIdx, hand in ipairs(ph) do
        local handOffset = handCount == 2 and (hIdx == 1 and -120 or 120) or 0
        local total = #hand
        for i, card in ipairs(hand) do
            local targetDx = cx + handOffset + (i - (total + 1) / 2) * Renderer.CARD_SPACING
            local targetDy = cy + Renderer.PLAYER_Y - Renderer.CARD_H / 2
            local animState = self.anim:getState(card.id)
            local dx, dy = targetDx, targetDy
            if animState then
                dx, dy = animState.x, animState.y
            end
            Renderer.drawCard(card, dx, dy, Renderer.CARD_W, Renderer.CARD_H, accentName)
        end
    end
end

function UI.GameScreen:drawHUD(w, h, ar, ag, ab)
    local engine = self.engine

    -- Top bar: chips (left), watch + hand (right)
    local topY = 20

    -- Chips (top-left)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.setFont(smallFont())
    love.graphics.print("CHIPS", 24, topY)
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.setFont(bigFont())
    love.graphics.print(tostring(engine.chipStack), 24, topY + 12)

    -- Watch / hand (top-right)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(labelFont())
    local watchId = engine:watchIdentity()
    local watchLabel = "WATCH " .. engine.run.currentAct .. " — " .. (watchId.name or "")
    love.graphics.print(watchLabel, w - 24 - labelFont():getWidth(watchLabel), topY)

    local handLabel = Run.currentActHandNumber(engine.run) .. " / " .. Run.HandsPerAct
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(smallFont())
    love.graphics.print(handLabel, w - 24 - smallFont():getWidth(handLabel), topY + 16)

    -- Active modifier icons (below chips)
    if #engine.run.activeModifiers > 0 then
        local mx = 24
        local my = topY + 42
        for _, mod in ipairs(engine.run.activeModifiers) do
            local icon = Modifier.Icon[mod.type] or "?"
            love.graphics.setColor(ar, ag, ab, 0.5)
            love.graphics.setFont(labelFont())
            love.graphics.print(icon, mx, my)
            mx = mx + 22
        end
    end

    -- Seeded voyage cards warning
    local seeded = engine:seededVoyageCards()
    if #seeded > 0 then
        love.graphics.setColor(0.8, 0.4, 0.2, 0.5)
        love.graphics.setFont(smallFont())
        love.graphics.print("⚠ " .. #seeded .. " in deck", 24, topY + 62)
    end

    -- Pace indicator bar
    if engine:paceDeficit() then
        local deficit = engine:paceDeficit()
        local fill = deficit == 0 and 1.0 or math.max(0, 1.0 - deficit / 60)
        local barW = 60 * fill
        love.graphics.setColor(1, 1, 1, 0.06)
        love.graphics.rectangle("fill", 24, topY + 78, 60, 3, 1.5, 1.5, 1.5, 1.5)
        if deficit == 0 then
            love.graphics.setColor(ar, ag, ab, 0.7)
        elseif deficit < 20 then
            love.graphics.setColor(ar, ag, ab, 0.45)
        elseif deficit < 40 then
            love.graphics.setColor(1, 1, 1, 0.25)
        else
            love.graphics.setColor(0.75, 0.3, 0.3, 0.7)
        end
        love.graphics.rectangle("fill", 24, topY + 78, barW, 3, 1.5, 1.5, 1.5, 1.5)
    end

    -- Current bet + hand value (during play)
    if engine.phase == Engine.Phase.PLAYER_TURN or engine.phase == Engine.Phase.DEALER_TURN then
        -- Bet (centered, near top of HUD area — above dealer cards)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setFont(smallFont())
        printCentered("BET", smallFont(), 60, w)
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.setFont(headerFont())
        local betStr = tostring(engine:activeBet())
        printCentered(betStr, headerFont(), 72, w)

        -- Hand value panel (centered in the gap between dealer and player cards)
        local pv = engine:playerValue()
        local valStr = tostring(pv.soft)
        -- Panel
        local panelW = 88
        local panelH = 36
        local panelX = (w - panelW) / 2
        local panelY = h * 0.495
        drawPanel(panelX, panelY, panelW, panelH, 8,
            ar * 0.08, ag * 0.08, ab * 0.08, 0.9,
            ar, ag, ab, 0.35)
        -- "YOU" label
        love.graphics.setColor(ar, ag, ab, 0.7)
        love.graphics.setFont(smallFont())
        local youLabel = "YOU"
        local ylw = smallFont():getWidth(youLabel)
        love.graphics.print(youLabel, panelX + (panelW - ylw) / 2, panelY + 4)
        -- Value
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.setFont(bigFont())
        local vw = bigFont():getWidth(valStr)
        love.graphics.print(valStr, panelX + (panelW - vw) / 2, panelY + 14)
    end
end

function UI.GameScreen:drawBetting(w, h, ar, ag, ab)
    local engine = self.engine
    local minBet = engine:effectiveMinimumBet()

    -- Run context block (upper area, fills dead space)
    local watchId = engine:watchIdentity()
    local watchName = watchId.name or ""
    local ctxY = h * 0.18

    -- Watch identity label
    love.graphics.setColor(ar, ag, ab, 0.55)
    love.graphics.setFont(labelFont())
    local watchLabel = "WATCH " .. engine.run.currentAct .. " OF " .. engine:effectiveActCount() .. "  —  " .. watchName:upper()
    printCentered(watchLabel, labelFont(), ctxY, w)

    -- Hand number
    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.setFont(bigFont())
    local handLabel = "Hand " .. Run.currentActHandNumber(engine.run) .. " of " .. Run.HandsPerAct
    printCentered(handLabel, bigFont(), ctxY + 22, w)

    -- Watch description (one-liner)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.setFont(labelFont())
    local watchDesc = watchId.desc or ""
    local descLines = wrapText(watchDesc, labelFont(), w - 72)
    for i, line in ipairs(descLines) do
        if i > 2 then break end
        printCentered(line, labelFont(), ctxY + 52 + (i - 1) * 16, w)
    end

    -- Chips balance (large, centered) — reinforces the HUD top-left
    local balY = ctxY + 52 + math.min(#descLines, 2) * 16 + 18
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(smallFont())
    printCentered("CHIPS", smallFont(), balY, w)
    love.graphics.setColor(ar, ag, ab, 0.85)
    love.graphics.setFont(headerFont())
    printCentered(tostring(engine.chipStack), headerFont(), balY + 12, w)

    -- Threshold reminder (only if getting close to next watch threshold)
    local nextThresh = engine.run.currentAct < engine:effectiveActCount()
        and Run.departureThreshold(engine.run.currentAct + 1) or nil
    if nextThresh and engine.chipStack < nextThresh then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setFont(labelFont())
        local thrLines = wrapText("Need " .. nextThresh .. " to clear next watch", labelFont(), w - 72)
        printCentered(thrLines[1] or "", labelFont(), balY + 38, w)
    end

    -- Divider line between context and bet controls
    local divY = balY + 60
    love.graphics.setColor(ar, ag, ab, 0.18)
    love.graphics.setLineWidth(1)
    local divW = w * 0.5
    love.graphics.line((w - divW) / 2, divY, (w + divW) / 2, divY)

    -- Known waters card display
    if engine.knownWatersCard then
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.setFont(labelFont())
        local rankStr = Card.RankNames[engine.knownWatersCard.rank] or "?"
        local suitStr = engine.knownWatersCard.suit:sub(1,1):upper() .. engine.knownWatersCard.suit:sub(2)
        local label = "Top card: " .. rankStr .. " of " .. suitStr
        printCentered(label, labelFont(), divY + 16, w)
    end

    -- Bet controls (moved up slightly to fill space better)
    local btnY = h - 130
    local btnW = 130
    local btnH = 44
    local spacing = 12
    local totalW = btnW + spacing + btnW
    local startX = (w - totalW) / 2

    -- Bet label and value (panel for clarity)
    local panelY = btnY - 50
    local panelH = 38
    drawPanel(w * 0.3, panelY, w * 0.4, panelH, 8,
        ar * 0.05, ag * 0.05, ab * 0.05, 0.85,
        ar, ag, ab, 0.25)

    love.graphics.setColor(1, 1, 1, 0.45)
    love.graphics.setFont(smallFont())
    local betLabel = "BET  (min " .. minBet .. ")"
    local blw = smallFont():getWidth(betLabel)
    love.graphics.print(betLabel, (w - blw) / 2, panelY + 4)

    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.setFont(bigFont())
    local betStr = tostring(self._betAmount or minBet)
    printCentered(betStr, bigFont(), panelY + 16, w)

    -- Minus / Plus buttons
    drawButton("− 10", startX, btnY, btnW, btnH, ar, ag, ab, false)
    drawButton("+ 10", startX + btnW + spacing, btnY, btnW, btnH, ar, ag, ab, false)

    -- DEAL button
    local dealW = 160
    drawButton("DEAL", (w - dealW) / 2, btnY + btnH + 12, dealW, 48, ar, ag, ab, true)
end

function UI.GameScreen:drawActionsBar(w, h, ar, ag, ab)
    local engine = self.engine
    local btnW = 78
    local btnH = 44
    local spacing = 8
    local buttons = {}

    if engine:canHit() then table.insert(buttons, { label = "HIT", action = "hit" }) end
    table.insert(buttons, { label = "STAND", action = "stand" })
    if engine:canDouble() then table.insert(buttons, { label = "DOUBLE", action = "double" }) end
    if engine:canSplit() then table.insert(buttons, { label = "SPLIT", action = "split" }) end
    if engine:canUseCardShark() then table.insert(buttons, { label = "👁 PEEK", action = "peek" }) end
    if engine:canUseBallast() then table.insert(buttons, { label = "▽ BALLAST", action = "ballast" }) end

    local totalW = #buttons * btnW + (#buttons - 1) * spacing
    local startX = (w - totalW) / 2
    local btnY = h - 60

    for i, btn in ipairs(buttons) do
        drawButton(btn.label, startX + (i - 1) * (btnW + spacing), btnY, btnW, btnH, ar, ag, ab, i == #buttons)
    end
end

function UI.GameScreen:drawHandResult(w, h, ar, ag, ab)
    local outcome = self.engine._pendingOutcome or "push"
    local lastHand = self.engine.run.hands[#self.engine.run.hands]
    local delta = lastHand and (lastHand.chipsAfter - lastHand.chipsBefore) or 0

    local label
    local labelColor
    if outcome == "playerWin" then label = "AFLOAT"; labelColor = {ar, ag, ab}
    elseif outcome == "dealerFust" then label = "DEALER FUST"; labelColor = {ar, ag, ab}
    elseif outcome == "push" then label = "PUSH"; labelColor = {0.6, 0.6, 0.6}
    elseif outcome == "playerFust" then label = "FUST"; labelColor = {0.8, 0.3, 0.3}
    elseif outcome == "dealerWin" then label = "UNDER"; labelColor = {0.7, 0.35, 0.35}
    else label = "—"; labelColor = {0.6, 0.6, 0.6} end

    -- Semi-transparent band
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", 0, h * 0.36, w, h * 0.22)

    -- Outcome label
    love.graphics.setColor(labelColor[1], labelColor[2], labelColor[3], 0.9)
    love.graphics.setFont(titleFont())
    printCentered(label, titleFont(), h * 0.4, w)

    -- Chip delta
    if delta ~= 0 then
        local dStr = (delta > 0 and "+" or "") .. tostring(delta)
        love.graphics.setColor(delta > 0 and ar or 0.8, delta > 0 and ag or 0.3, delta > 0 and ab or 0.3, 0.8)
        love.graphics.setFont(headerFont())
        printCentered(dStr, headerFont(), h * 0.4 + 36, w)
    end
end

function UI.GameScreen:drawTide(w, h, ar, ag, ab)
    local engine = self.engine
    local bet = self._pendingBet or 0

    -- Dark band
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", 0, h * 0.2, w, h * 0.55)

    -- Title
    love.graphics.setColor(1, 1, 1, 0.55)
    love.graphics.setFont(labelFont())
    printCentered("THE TIDE", labelFont(), h * 0.22, w)

    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(smallFont())
    local sub = "Bet: " .. bet .. " — choose your tide"
    printCentered(sub, smallFont(), h * 0.22 + 16, w)

    -- Three tide options as cards
    local cardW = math.min(110, (w - 72) / 3)
    local cardH = 170
    local spacing = 12
    local totalW = 3 * cardW + 2 * spacing
    local startX = (w - totalW) / 2
    local cardY = h * 0.3

    local tides = {
        { key = "rising",  name = "RISING",  desc = "+20% payout",  cost = "Dealer draws\none extra card" },
        { key = "falling", name = "FALLING", desc = "-20% payout",  cost = "See dealer's\nhole card"      },
        { key = "flat",    name = "FLAT",    desc = "No change",    cost = "Safe passage"                 },
    }

    for i, tide in ipairs(tides) do
        local cx = startX + (i - 1) * (cardW + spacing)
        local iconCx = cx + cardW / 2
        local iconCy = cardY + 32

        -- Card panel
        drawPanel(cx, cardY, cardW, cardH, 10,
            ar * 0.08, ag * 0.08, ab * 0.08, 1,
            ar, ag, ab, 0.3)

        -- Drawn vector icon (no font glyphs — guarantees visibility)
        love.graphics.setColor(ar, ag, ab, 0.85)
        love.graphics.setLineWidth(2.5)
        love.graphics.setLineStyle("smooth")
        if tide.key == "rising" then
            -- Up-arrow: vertical line + arrowhead
            love.graphics.line(iconCx, iconCy + 14, iconCx, iconCy - 14)
            love.graphics.polygon("fill",
                iconCx - 9, iconCy - 6,
                iconCx + 9, iconCy - 6,
                iconCx,     iconCy - 16)
        elseif tide.key == "falling" then
            -- Down-arrow: vertical line + arrowhead
            love.graphics.line(iconCx, iconCy - 14, iconCx, iconCy + 14)
            love.graphics.polygon("fill",
                iconCx - 9, iconCy + 6,
                iconCx + 9, iconCy + 6,
                iconCx,     iconCy + 16)
        else
            -- Flat: horizontal line with a calm wave undulation
            love.graphics.line(iconCx - 16, iconCy, iconCx + 16, iconCy)
            -- Gentle wave below the line (small sine-like dashes)
            love.graphics.line(iconCx - 12, iconCy + 8, iconCx - 6, iconCy + 8)
            love.graphics.line(iconCx - 3, iconCy + 8, iconCx + 3, iconCy + 8)
            love.graphics.line(iconCx + 6, iconCy + 8, iconCx + 12, iconCy + 8)
        end
        love.graphics.setLineStyle("rough")
        love.graphics.setLineWidth(1)

        -- Name
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.setFont(bodyFont())
        local nameW = bodyFont():getWidth(tide.name)
        love.graphics.print(tide.name, cx + (cardW - nameW) / 2, cardY + 56)

        -- Description (payout)
        love.graphics.setColor(ar, ag, ab, 0.6)
        love.graphics.setFont(labelFont())
        local descW = labelFont():getWidth(tide.desc)
        love.graphics.print(tide.desc, cx + (cardW - descW) / 2, cardY + 78)

        -- Cost/effect
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.setFont(smallFont())
        local costLines = {}
        for line in tide.cost:gmatch("[^\n]+") do table.insert(costLines, line) end
        for j, line in ipairs(costLines) do
            local lineW = smallFont():getWidth(line)
            love.graphics.print(line, cx + (cardW - lineW) / 2, cardY + 108 + (j - 1) * 12)
        end

        -- Number key hint at bottom
        love.graphics.setColor(ar, ag, ab, 0.4)
        love.graphics.setFont(smallFont())
        local keyHint = tostring(i)
        local keyW = smallFont():getWidth(keyHint)
        love.graphics.print(keyHint, cx + (cardW - keyW) / 2, cardY + cardH - 18)
    end
end

function UI.GameScreen:drawSalvage(w, h, ar, ag, ab)
    local engine = self.engine
    local candidates = engine.draftCandidates
    if #candidates == 0 then return end

    -- Fully opaque overlay — cards from the previous hand must not bleed through
    love.graphics.setColor(0.03, 0.03, 0.04, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Title
    love.graphics.setColor(1, 1, 1, 0.55)
    love.graphics.setFont(labelFont())
    printCentered("SALVAGE", labelFont(), h * 0.06, w)

    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(smallFont())
    local subLines = wrapText("Take the flotsam, or seed the reef for chips", smallFont(), w - 48)
    printCentered(subLines[1] or "", smallFont(), h * 0.06 + 16, w)

    -- Artefact found display
    if engine.lastArtefactFound then
        local a = engine.lastArtefactFound
        local aY = h * 0.12

        drawPanel(w * 0.08, aY, w * 0.84, 76, 10,
            ar * 0.08, ag * 0.08, ab * 0.08, 1,
            ar, ag, ab, 0.4)

        love.graphics.setColor(ar, ag, ab, 0.75)
        love.graphics.setFont(bodyFont())
        local aTitle = "✦ " .. a.title:upper()
        printCentered(aTitle, bodyFont(), aY + 8, w)

        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setFont(smallFont())
        local aLines = wrapText(a.text, smallFont(), w * 0.72)
        for i, line in ipairs(aLines) do
            if i <= 3 then
                printCentered(line, smallFont(), aY + 28 + (i - 1) * 12, w)
            end
        end

        love.graphics.setColor(ar, ag, ab, 0.4)
        love.graphics.setFont(smallFont())
        printCentered("New entry in your journal", smallFont(), aY + 62, w)
    end

    -- Two choices
    local cardW = math.min(155, (w - 72) / 2)
    local cardH = 84
    local leftX = (w / 2) - cardW - 8
    local rightX = (w / 2) + 8
    local cardY = h * 0.28

    -- Flotsam (left)
    drawPanel(leftX, cardY, cardW, cardH, 10,
        ar * 0.08, ag * 0.08, ab * 0.08, 1,
        ar, ag, ab, 0.35)

    love.graphics.setColor(ar, ag, ab, 0.85)
    love.graphics.setFont(bodyFont())
    local fName = "FLOTSAM"
    love.graphics.print(fName, leftX + (cardW - bodyFont():getWidth(fName)) / 2, cardY + 10)

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(smallFont())
    local fLines = wrapText("+1 Flotsam — keep deck clean", smallFont(), cardW - 16)
    for j, line in ipairs(fLines) do
        love.graphics.print(line, leftX + (cardW - smallFont():getWidth(line)) / 2, cardY + 32 + (j - 1) * 12)
    end

    -- Key hint
    love.graphics.setColor(ar, ag, ab, 0.4)
    love.graphics.setFont(smallFont())
    local fHint = "F"
    love.graphics.print(fHint, leftX + 8, cardY + cardH - 16)

    -- Seed the Reef (right)
    drawPanel(rightX, cardY, cardW, cardH, 10,
        ar * 0.08, ag * 0.08, ab * 0.08, 1,
        ar, ag, ab, 0.35)

    love.graphics.setColor(ar, ag, ab, 0.85)
    love.graphics.setFont(bodyFont())
    local rName = "SEED THE REEF"
    love.graphics.print(rName, rightX + (cardW - bodyFont():getWidth(rName)) / 2, cardY + 10)

    local handsLeft = Run.HandsPerAct - Run.currentActHandNumber(engine.run)
    local bonus = math.max(0, handsLeft) * 2
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(smallFont())
    local rLines = wrapText("+" .. bonus .. " chips — poison the deck", smallFont(), cardW - 16)
    for j, line in ipairs(rLines) do
        love.graphics.print(line, rightX + (cardW - smallFont():getWidth(line)) / 2, cardY + 32 + (j - 1) * 12)
    end

    -- Key hint
    love.graphics.setColor(ar, ag, ab, 0.4)
    love.graphics.setFont(smallFont())
    love.graphics.print("1-3", rightX + 8, cardY + cardH - 16)

    -- Voyage card choices (below)
    local vCardW = Renderer.CARD_W * 1.1
    local vCardH = Renderer.CARD_H * 1.1
    local vSpacing = 14
    local vTotalW = 3 * vCardW + 2 * vSpacing
    local vStartX = (w - vTotalW) / 2
    local vCardY = h * 0.5

    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(smallFont())
    printCentered("PICK A CARD TO SEED", smallFont(), vCardY - 22, w)

    for i, vtype in ipairs(candidates) do
        local cx = vStartX + (i - 1) * (vCardW + vSpacing)
        local fakeCard = { voyageEffect = vtype, fogRevealed = false, fogValue = nil, isFaceDown = false }
        if vtype == "fogBank" then fakeCard.fogValue = math.random(4, 9) end
        Renderer.drawVoyageCardFace(fakeCard, cx, vCardY, vCardW, vCardH, engine.run.accentColor)

        -- Display name (drawn once below the card, no duplicate inside card)
        love.graphics.setColor(1, 1, 1, 0.55)
        love.graphics.setFont(labelFont())
        local name = VoyageCard.DisplayName[vtype] or ""
        local nameW = labelFont():getWidth(name)
        love.graphics.print(name, cx + (vCardW - nameW) / 2, vCardY + vCardH + 4)

        -- Effect description (wrapped, max 2 lines)
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.setFont(smallFont())
        local desc = VoyageCard.Description[vtype] or ""
        local descLines = wrapText(desc, smallFont(), vCardW + 10)
        for j, line in ipairs(descLines) do
            if j > 2 then break end
            local descW = smallFont():getWidth(line)
            love.graphics.print(line, cx + (vCardW - descW) / 2, vCardY + vCardH + 20 + (j - 1) * 11)
        end

        -- Key hint
        love.graphics.setColor(ar, ag, ab, 0.4)
        love.graphics.setFont(smallFont())
        love.graphics.print(tostring(i), cx + (vCardW - smallFont():getWidth(tostring(i))) / 2, vCardY + vCardH + 46)
    end
end

function UI.GameScreen:drawShop(w, h, ar, ag, ab)
    local engine = self.engine
    local meta = self.meta

    -- Background (slightly different from felt — darker, less textured)
    love.graphics.setColor(0.05, 0.05, 0.06, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Subtle accent wash at top
    love.graphics.setColor(ar, ag, ab, 0.03)
    love.graphics.rectangle("fill", 0, 0, w, 180)

    -- Title
    love.graphics.setColor(1, 1, 1, 0.45)
    love.graphics.setFont(labelFont())
    printCentered("THE WHARF", labelFont(), 36, w)

    -- Watch label
    love.graphics.setColor(1, 1, 1, 0.55)
    love.graphics.setFont(bodyFont())
    local watchId = engine:watchIdentity()
    local watchLabel = "Watch " .. engine.run.currentAct .. " of " .. engine:effectiveActCount() .. " — " .. (watchId.name or "")
    printCentered(watchLabel, bodyFont(), 54, w)

    -- Ambient text (wrapped, indented so it doesn't clip the journal button)
    love.graphics.setColor(1, 1, 1, 0.25)
    love.graphics.setFont(smallFont())
    local ambient = Dialogue.wharfAmbient(engine.run.currentAct)
    local ambientMaxW = math.min(w - 48, 300)
    local ambLines = wrapText(ambient, smallFont(), ambientMaxW)
    -- Render centered horizontally to avoid the right-side journal button clipping
    local ambBlockW = 0
    for _, line in ipairs(ambLines) do
        local lw = smallFont():getWidth(line)
        if lw > ambBlockW then ambBlockW = lw end
    end
    local ambStartX = math.max(24, (w - ambBlockW) / 2)
    for i, line in ipairs(ambLines) do
        love.graphics.print(line, ambStartX, 78 + (i - 1) * 12)
    end

    local ambH = #ambLines * 12

    -- Journal button (top right)
    if meta:artefactCount() > 0 then
        local jLabel = "JOURNAL  " .. meta:artefactCount()
        if meta.journalNewCount > 0 then
            jLabel = jLabel .. " (" .. meta.journalNewCount .. " new)"
        end
        love.graphics.setColor(ar, ag, ab, 0.55)
        love.graphics.setFont(labelFont())
        local jw = labelFont():getWidth(jLabel)
        love.graphics.print(jLabel, w - jw - 20, 36)
    end

    -- Chip count (reasonable size, not gigantic)
    local chipY = 78 + ambH + 12
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(smallFont())
    printCentered("CHIPS", smallFont(), chipY, w)
    love.graphics.setColor(ar, ag, ab, 0.85)
    love.graphics.setFont(headerFont())
    printCentered(tostring(engine.chipStack), headerFont(), chipY + 12, w)

    -- NPC speaker
    local speaker = Dialogue.randomWharfSpeaker(engine.run.currentAct, meta:unlockedSet())
    if speaker then
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.setFont(labelFont())
        local spLabel = speaker.name .. " is here"
        printCentered(spLabel, labelFont(), chipY + 40, w)
    end

    -- Shop offer cards
    local offer = engine:getShopOffer()
    if #offer > 0 then
        local cardW = math.min(105, (w - 72) / 3)
        local cardH = 158
        local spacing = 12
        local totalW = #offer * cardW + (#offer - 1) * spacing
        local startX = (w - totalW) / 2
        local cardY = chipY + 66

        for i, modType in ipairs(offer) do
            local cx = startX + (i - 1) * (cardW + spacing)
            local price = engine:shopPrice(modType)
            local canAfford = engine.chipStack >= price
            local isOwned = Run.hasModifier(engine.run, modType)

            -- Card panel
            if canAfford and not isOwned then
                drawPanel(cx, cardY, cardW, cardH, 10,
                    ar * 0.08, ag * 0.08, ab * 0.08, 1,
                    ar, ag, ab, 0.35)
            else
                drawPanel(cx, cardY, cardW, cardH, 10,
                    0.06, 0.06, 0.06, 0.6,
                    0.3, 0.3, 0.3, 0.2)
            end

            -- Type label (small, top-of-card)
            love.graphics.setColor(canAfford and (ar * 0.7) or 0.3, canAfford and (ag * 0.7) or 0.3, canAfford and (ab * 0.7) or 0.3, 0.7)
            love.graphics.setFont(smallFont())
            local category = UI._modifierCategory(modType)
            local catW = smallFont():getWidth(category)
            love.graphics.print(category, cx + (cardW - catW) / 2, cardY + 6)

            -- Name (wrapped)
            love.graphics.setColor(1, 1, 1, canAfford and 0.85 or 0.4)
            love.graphics.setFont(labelFont())
            local name = Modifier.DisplayName[modType]
            local nameLines = wrapText(name, labelFont(), cardW - 12)
            for j, line in ipairs(nameLines) do
                if j > 2 then break end
                local lineW = labelFont():getWidth(line)
                love.graphics.print(line, cx + (cardW - lineW) / 2, cardY + 26 + (j - 1) * 14)
            end

            -- Description (wrapped, up to 5 lines)
            love.graphics.setColor(1, 1, 1, canAfford and 0.5 or 0.25)
            love.graphics.setFont(smallFont())
            local descLines = wrapText(Modifier.Description[modType], smallFont(), cardW - 12)
            local descStartY = cardY + 60
            local descLineH = 11
            local maxDescLines = math.floor((cardY + cardH - 32 - descStartY) / descLineH)
            maxDescLines = math.max(3, maxDescLines)  -- ensure at least 3 lines
            for j = 1, math.min(maxDescLines, #descLines) do
                local line = descLines[j]
                local lineW = smallFont():getWidth(line)
                love.graphics.print(line, cx + (cardW - lineW) / 2, descStartY + (j - 1) * descLineH)
            end

            -- Price / status line
            if isOwned then
                love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
                love.graphics.setFont(bodyFont())
                local statusStr = "OWNED"
                local sw = bodyFont():getWidth(statusStr)
                love.graphics.print(statusStr, cx + (cardW - sw) / 2, cardY + cardH - 24)
            else
                love.graphics.setColor(canAfford and ar or 0.5, canAfford and ag or 0.4, canAfford and ab or 0.4, canAfford and 0.95 or 0.55)
                love.graphics.setFont(bodyFont())
                local priceStr = tostring(price)
                local pw = bodyFont():getWidth(priceStr)
                love.graphics.print(priceStr, cx + (cardW - pw) / 2, cardY + cardH - 24)

                -- Strikethrough on unaffordable price
                if not canAfford then
                    love.graphics.setColor(0.5, 0.4, 0.4, 0.6)
                    love.graphics.setLineWidth(1.4)
                    love.graphics.line(cx + (cardW - pw) / 2 - 2, cardY + cardH - 16,
                        cx + (cardW - pw) / 2 + pw + 2, cardY + cardH - 16)
                end
            end
        end
    end

    -- Float a loan button
    if not engine.run.loanUsedThisAct then
        drawButton("Float a Loan  +" .. Run.LoanAmount, 24, h - 120, w - 48, 42, ar, ag, ab, false)
    end

    -- Depart button
    drawButton("DEPART", 24, h - 68, w - 48, 44, ar, ag, ab, true)
end

function UI.GameScreen:drawGameOver(w, h, ar, ag, ab)
    local engine = self.engine
    local outcome = engine.run.outcome
    local meta = self.meta

    -- Dark background
    love.graphics.setColor(0.04, 0.04, 0.05, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Subtle accent wash
    love.graphics.setColor(ar, ag, ab, 0.03)
    love.graphics.rectangle("fill", 0, 0, w, 200)

    -- Title
    local title
    local titleColor
    if outcome == "won" then
        title = "AFLOAT"
        titleColor = {ar, ag, ab}
    else
        title = "FOUNDERED"
        titleColor = {0.75, 0.3, 0.3}
    end

    love.graphics.setColor(titleColor[1], titleColor[2], titleColor[3], 0.9)
    love.graphics.setFont(titleFont())
    printCentered(title, titleFont(), h * 0.12, w)

    -- Flotsam earned
    love.graphics.setColor(1, 1, 1, 0.55)
    love.graphics.setFont(bodyFont())
    local flotsamStr = "+" .. engine.run.flotsamEarned .. " Flotsam"
    printCentered(flotsamStr, bodyFont(), h * 0.12 + 38, w)

    -- Character reactions
    local actsCompleted = engine.run.currentAct - 1
    if outcome == "won" then actsCompleted = actsCompleted + 1 end

    local y = h * 0.24
    for _, charKey in ipairs(Dialogue.Characters) do
        local requiredNode = Dialogue.CharacterRequiredNode[charKey]
        if not requiredNode or meta:hasUnlock(requiredNode) then
            local line = Dialogue.hubLine(charKey, actsCompleted, outcome)

            -- Character name
            love.graphics.setColor(ar, ag, ab, 0.5)
            love.graphics.setFont(labelFont())
            love.graphics.print(Dialogue.CharacterDisplayName[charKey]:upper(), 28, y)

            -- Dialogue line
            love.graphics.setColor(1, 1, 1, 0.65)
            love.graphics.setFont(smallBodyFont())
            local lines = wrapText(line, smallBodyFont(), w - 56)
            for i, l in ipairs(lines) do
                love.graphics.print(l, 28, y + 16 + (i - 1) * 18)
            end
            y = y + 16 + #lines * 18 + 18
        end
    end

    -- New voyage button
    drawButton("NEW VOYAGE", (w - 220) / 2, h - 80, 220, 48, ar, ag, ab, true)
end

function UI.GameScreen:drawJournal(w, h, ar, ag, ab)
    local meta = self.meta

    -- Full overlay
    love.graphics.setColor(0.03, 0.03, 0.04, 0.97)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Title
    love.graphics.setColor(ar, ag, ab, 0.65)
    love.graphics.setFont(headerFont())
    love.graphics.print("FLOTSAM JOURNAL", 24, 24)

    -- Count
    love.graphics.setColor(1, 1, 1, 0.35)
    love.graphics.setFont(labelFont())
    local count = meta:artefactCount()
    local total = Artefacts.getCount()
    love.graphics.print(count .. " of " .. total .. " found", 24, 46)

    -- Close button
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(headerFont())
    love.graphics.print("×", w - 36, 22)

    -- Artefact entries
    local y = 78 - self.journalScrollY
    for _, id in ipairs(meta.collectedArtefacts) do
        local a = Artefacts.ById[id]
        if not a then goto continue end

        if y > h - 20 then goto continue end
        if y >= 60 then
            -- Title
            love.graphics.setColor(ar, ag, ab, 0.75)
            love.graphics.setFont(bodyFont())
            love.graphics.print("✦ " .. a.title, 24, y)

            -- Text
            love.graphics.setColor(1, 1, 1, 0.55)
            love.graphics.setFont(smallBodyFont())
            local lines = wrapText(a.text, smallBodyFont(), w - 48)
            for i, line in ipairs(lines) do
                love.graphics.print(line, 24, y + 20 + (i - 1) * 16)
            end
        end

        y = y + 20 + #wrapText(a.text, smallBodyFont(), w - 48) * 16 + 18

        ::continue::
    end

    -- Empty state
    if count == 0 then
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.setFont(bodyFont())
        printCentered("No artefacts found yet.", bodyFont(), h * 0.4, w)
        love.graphics.setFont(labelFont())
        printCentered("Take flotsam during salvage to find artefacts.", labelFont(), h * 0.4 + 24, w)
    end

    -- Scroll hint
    if y > h then
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.setFont(smallFont())
        love.graphics.print("scroll: ↑↓ keys", w - 100, h - 20)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function UI.GameScreen:drawLuckyStart(w, h, ar, ag, ab)
    local engine = self.engine
    local offer = engine.luckyStartOffer
    if #offer == 0 then return end

    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(labelFont())
    printCentered("LUCKY START — FREE MODIFIER", labelFont(), h * 0.18, w)

    local cardW = math.min(105, (w - 72) / 3)
    local cardH = 130
    local spacing = 12
    local totalW = #offer * cardW + (#offer - 1) * spacing
    local startX = (w - totalW) / 2
    local cardY = h * 0.26

    for i, modType in ipairs(offer) do
        local cx = startX + (i - 1) * (cardW + spacing)

        drawPanel(cx, cardY, cardW, cardH, 10,
            ar * 0.08, ag * 0.08, ab * 0.08, 1,
            ar, ag, ab, 0.35)

        -- Icon
        love.graphics.setColor(ar, ag, ab, 0.85)
        love.graphics.setFont(headerFont())
        local icon = Modifier.Icon[modType] or "?"
        local iconW = headerFont():getWidth(icon)
        love.graphics.print(icon, cx + (cardW - iconW) / 2, cardY + 14)

        -- Name
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.setFont(labelFont())
        local name = Modifier.DisplayName[modType]
        local nameLines = wrapText(name, labelFont(), cardW - 10)
        for j, line in ipairs(nameLines) do
            local lineW = labelFont():getWidth(line)
            love.graphics.print(line, cx + (cardW - lineW) / 2, cardY + 46 + (j - 1) * 14)
        end

        -- Desc
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.setFont(smallFont())
        local descLines = wrapText(Modifier.Description[modType], smallFont(), cardW - 12)
        for j = 1, math.min(3, #descLines) do
            local line = descLines[j]
            local lineW = smallFont():getWidth(line)
            love.graphics.print(line, cx + (cardW - lineW) / 2, cardY + 80 + (j - 1) * 12)
        end
    end

    -- Skip button
    drawButton("SKIP", (w - 120) / 2, h * 0.55, 120, 42, ar, ag, ab, false)
end

-- ===========================================================================
-- Input handling (must match draw coordinates exactly)
-- ===========================================================================

function UI.GameScreen:mousepressed(mx, my, button)
    local w, h = love.graphics.getDimensions()
    local engine = self.engine
    local ar, ag, ab = accent(engine.run.accentColor)

    -- Journal overlay takes priority
    if self.showJournal then
        if inRect(mx, my, w - 48, 20, 32, 32) then
            self.showJournal = false
            self.meta:clearJournalNewCount()
            return
        end
        return
    end

    -- Journal button in shop
    if engine.phase == Engine.Phase.SHOP and self.meta:artefactCount() > 0 then
        local jLabel = "📖 " .. self.meta:artefactCount()
        if self.meta.journalNewCount > 0 then
            jLabel = jLabel .. " (" .. self.meta.journalNewCount .. " new)"
        end
        local f = labelFont()
        local jw = f:getWidth(jLabel)
        if inRect(mx, my, w - jw - 28, 28, jw + 16, 24) then
            self.showJournal = true
            self.journalScrollY = 0
            return
        end
    end

    if engine.phase == Engine.Phase.BETTING then
        if #engine.luckyStartOffer > 0 then
            local offer = engine.luckyStartOffer
            local cardW = math.min(105, (w - 72) / 3)
            local cardH = 130
            local spacing = 12
            local totalW = #offer * cardW + (#offer - 1) * spacing
            local startX = (w - totalW) / 2
            local cardY = h * 0.26
            for i, _ in ipairs(offer) do
                local cx = startX + (i - 1) * (cardW + spacing)
                if inRect(mx, my, cx, cardY, cardW, cardH) then
                    engine:acceptLuckyStartOffer(offer[i])
                    return
                end
            end
            if inRect(mx, my, (w - 120) / 2, h * 0.55, 120, 42) then
                engine:skipLuckyStart()
                return
            end
        else
            local minBet = engine:effectiveMinimumBet()
            local btnW = 130
            local btnH = 44
            local spacing = 12
            local totalW = btnW + spacing + btnW
            local startX = (w - totalW) / 2
            local btnY = h - 130

            if inRect(mx, my, startX, btnY, btnW, btnH) then
                self._betAmount = math.max(minBet, (self._betAmount or minBet) - 10)
                return
            end
            if inRect(mx, my, startX + btnW + spacing, btnY, btnW, btnH) then
                self._betAmount = math.min(engine.chipStack, (self._betAmount or minBet) + 10)
                return
            end
            local dealW = 160
            if inRect(mx, my, (w - dealW) / 2, btnY + btnH + 12, dealW, 48) then
                engine:placeBet(self._betAmount or minBet)
                self._betAmount = nil
                return
            end
        end

    elseif engine.phase == Engine.Phase.TIDE then
        local cardW = math.min(110, (w - 72) / 3)
        local cardH = 170
        local spacing = 12
        local totalW = 3 * cardW + 2 * spacing
        local startX = (w - totalW) / 2
        local cardY = h * 0.3
        local tides = { "rising", "falling", "flat" }
        for i, tide in ipairs(tides) do
            local cx = startX + (i - 1) * (cardW + spacing)
            if inRect(mx, my, cx, cardY, cardW, cardH) then
                engine:chooseTide(tide)
                return
            end
        end

    elseif engine.phase == Engine.Phase.PLAYER_TURN then
        local btnW = 78
        local btnH = 44
        local spacing = 8
        local buttons = {}
        if engine:canHit() then table.insert(buttons, "hit") end
        table.insert(buttons, "stand")
        if engine:canDouble() then table.insert(buttons, "double") end
        if engine:canSplit() then table.insert(buttons, "split") end
        if engine:canUseCardShark() then table.insert(buttons, "peek") end
        if engine:canUseBallast() then table.insert(buttons, "ballast") end

        local totalW = #buttons * btnW + (#buttons - 1) * spacing
        local startX = (w - totalW) / 2
        local btnY = h - 60
        for i, action in ipairs(buttons) do
            local bx = startX + (i - 1) * (btnW + spacing)
            if inRect(mx, my, bx, btnY, btnW, btnH) then
                if action == "hit" then engine:hit()
                elseif action == "stand" then engine:stand()
                elseif action == "double" then engine:doubleDown()
                elseif action == "split" then engine:split()
                elseif action == "peek" then engine:revealHoleCard()
                elseif action == "ballast" then engine:useBallast() end
                return
            end
        end

    elseif engine.phase == Engine.Phase.SALVAGE then
        local candidates = engine.draftCandidates
        local cardW = math.min(155, (w - 72) / 2)
        local cardH = 84
        local leftX = (w / 2) - cardW - 8
        local rightX = (w / 2) + 8
        local cardY = h * 0.28

        if inRect(mx, my, leftX, cardY, cardW, cardH) then
            engine:chooseSalvage("flotsam")
            return
        end

        if #candidates > 0 then
            local vCardW = Renderer.CARD_W * 1.1
            local vCardH = Renderer.CARD_H * 1.1
            local vSpacing = 14
            local vTotalW = 3 * vCardW + 2 * vSpacing
            local vStartX = (w - vTotalW) / 2
            local vCardY = h * 0.5
            for i, vtype in ipairs(candidates) do
                local cx = vStartX + (i - 1) * (vCardW + vSpacing)
                if inRect(mx, my, cx, vCardY, vCardW, vCardH) then
                    engine:chooseSalvage("reef", vtype)
                    return
                end
            end
        end

    elseif engine.phase == Engine.Phase.SHOP then
        local offer = engine:getShopOffer()
        if #offer > 0 then
            local cardW = math.min(105, (w - 72) / 3)
            local cardH = 150
            local spacing = 12
            local totalW = #offer * cardW + (#offer - 1) * spacing
            local startX = (w - totalW) / 2
            -- cardY computed dynamically — must match draw
            local ambH = #wrapText(Dialogue.wharfAmbient(engine.run.currentAct), smallFont(), w - 48) * 12
            local chipY = 78 + ambH + 12
            local cardY = chipY + 66
            for i, modType in ipairs(offer) do
                local cx = startX + (i - 1) * (cardW + spacing)
                if inRect(mx, my, cx, cardY, cardW, cardH) then
                    engine:purchaseModifier(modType)
                    return
                end
            end
        end
        if not engine.run.loanUsedThisAct then
            if inRect(mx, my, 24, h - 120, w - 48, 42) then
                engine:takeLoan()
                return
            end
        end
        if inRect(mx, my, 24, h - 68, w - 48, 44) then
            engine:leaveShop()
            return
        end

    elseif engine.phase == Engine.Phase.GAME_OVER then
        if inRect(mx, my, (w - 220) / 2, h - 80, 220, 48) then
            if self.onNewRun then self.onNewRun() end
            return
        end
    end
end

function UI.GameScreen:keypressed(key)
    local engine = self.engine

    -- Journal navigation
    if self.showJournal then
        if key == "escape" then
            self.showJournal = false
            self.meta:clearJournalNewCount()
        elseif key == "up" then
            self.journalScrollY = math.max(0, self.journalScrollY - 40)
        elseif key == "down" then
            self.journalScrollY = self.journalScrollY + 40
        elseif key == "j" then
            self.showJournal = false
            self.meta:clearJournalNewCount()
        end
        return
    end

    -- Toggle journal with J in shop
    if key == "j" and engine.phase == Engine.Phase.SHOP and self.meta:artefactCount() > 0 then
        self.showJournal = true
        self.journalScrollY = 0
        return
    end

    if key == "escape" then
        return
    end

    if engine.phase == Engine.Phase.PLAYER_TURN then
        if key == "h" then engine:hit()
        elseif key == "s" then engine:stand()
        elseif key == "d" then engine:doubleDown()
        elseif key == "p" then engine:split() end
    elseif engine.phase == Engine.Phase.BETTING and #engine.luckyStartOffer == 0 then
        if key == "return" or key == "space" then
            local minBet = engine:effectiveMinimumBet()
            engine:placeBet(self._betAmount or minBet)
            self._betAmount = nil
        end
    elseif engine.phase == Engine.Phase.TIDE then
        if key == "1" then engine:chooseTide("rising")
        elseif key == "2" then engine:chooseTide("falling")
        elseif key == "3" then engine:chooseTide("flat") end
    elseif engine.phase == Engine.Phase.SALVAGE then
        if key == "f" then engine:chooseSalvage("flotsam")
        elseif key == "1" then engine:chooseSalvage("reef", engine.draftCandidates[1])
        elseif key == "2" then engine:chooseSalvage("reef", engine.draftCandidates[2])
        elseif key == "3" then engine:chooseSalvage("reef", engine.draftCandidates[3]) end
    elseif engine.phase == Engine.Phase.GAME_OVER then
        if key == "return" or key == "space" then
            if self.onNewRun then self.onNewRun() end
        end
    end
end

return UI