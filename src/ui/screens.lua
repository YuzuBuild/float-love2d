-- UI: All game screens. Replaces SwiftUI views.
-- Each screen is a table with enter/update/draw/mousepressed/keypressed

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

-- Helper: get centered x for text
local function centerX(text, font, width)
    return (width - font:getWidth(text)) / 2
end

-- Helper: draw a button
local function drawButton(label, x, y, w, h, accentR, accentG, accentB, isPrimary)
    local r, g, b = accentR, accentG, accentB
    if isPrimary then
        love.graphics.setColor(r, g, b, 1)
    else
        love.graphics.setColor(r * 0.15, g * 0.15, b * 0.15, 1)
    end
    love.graphics.rectangle("fill", x, y, w, h, 12, 12, 12, 12)

    if not isPrimary then
        love.graphics.setColor(r, g, b, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", x, y, w, h, 12, 12, 12, 12)
    end

    love.graphics.setColor(isPrimary and 0 or 1, isPrimary and 0 or 1, isPrimary and 0 or 1, 0.9)
    local font = love.graphics.newFont(13)
    love.graphics.setFont(font)
    local tw = font:getWidth(label)
    love.graphics.print(label, x + (w - tw) / 2, y + (h - 13) / 2)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Helper: check if point is in rect
local function inRect(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

-- Helper: wrap text to width
local function wrapText(text, font, maxWidth)
    local lines = {}
    local words = {}
    for word in text:gmatch("%S+") do table.insert(words, word) end
    local line = ""
    for _, word in ipairs(words) do
        local test = line == "" and word or line .. " " .. word
        if font:getWidth(test) <= maxWidth then
            line = test
        else
            table.insert(lines, line)
            line = word
        end
    end
    if line ~= "" then table.insert(lines, line) end
    return lines
end

-- Helper: get accent color values
local function accent(name)
    local c = Renderer.AccentColor[name] or Renderer.AccentColor.dustyGreen
    return c.r, c.g, c.b
end

-------------------------------------------------------------------------------
-- Departure Screen
-------------------------------------------------------------------------------

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

    -- Background
    love.graphics.setColor(0.07, 0.07, 0.07, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- HIGGS label
    love.graphics.setColor(1, 1, 1, 0.28)
    local font = love.graphics.newFont(10)
    love.graphics.setFont(font)
    local label = "HIGGS"
    love.graphics.print(label, centerX(label, font, w), h * 0.35)

    -- Higgs line
    love.graphics.setColor(1, 1, 1, 0.72)
    font = love.graphics.newFont(16)
    love.graphics.setFont(font)
    local lines = wrapText(self.higgsLine, font, w - 104)
    for i, line in ipairs(lines) do
        love.graphics.print(line, centerX(line, font, w), h * 0.35 + 24 + (i - 1) * 22)
    end

    -- Condition (if present)
    if self.condition then
        local cond = Run.ConditionDisplayName[self.condition]
        local higgsCondLine = Run.ConditionHiggsLine[self.condition]
        local effectSummary = Run.ConditionEffectSummary[self.condition]

        -- Decorative wave line
        love.graphics.setColor(ar, ag, ab, 0.2)
        font = love.graphics.newFont(9)
        love.graphics.setFont(font)
        local wave = ""
        for i = 1, 20 do wave = wave .. (i % 2 == 0 and "~" or " ") end
        love.graphics.print(wave, centerX(wave, font, w), h * 0.45)

        -- Condition higgs line (quoted)
        love.graphics.setColor(1, 1, 1, 0.55)
        font = love.graphics.newFont(14)
        love.graphics.setFont(font)
        local condLines = wrapText('"' .. higgsCondLine .. '"', font, w - 104)
        for i, line in ipairs(condLines) do
            love.graphics.print(line, centerX(line, font, w), h * 0.45 + 16 + (i - 1) * 20)
        end

        -- Condition name
        love.graphics.setColor(ar, ag, ab, 0.6)
        font = love.graphics.newFont(9)
        love.graphics.setFont(font)
        love.graphics.print(cond:upper(), centerX(cond:upper(), font, w), h * 0.55)

        -- Effect summary
        love.graphics.setColor(1, 1, 1, 0.28)
        font = love.graphics.newFont(11)
        love.graphics.setFont(font)
        local sumLines = wrapText(effectSummary, font, w - 80)
        for i, line in ipairs(sumLines) do
            love.graphics.print(line, centerX(line, font, w), h * 0.55 + 16 + (i - 1) * 16)
        end
    end

    -- DEPART button
    local btnW = math.min(w - 64, 300)
    local btnX = (w - btnW) / 2
    local btnY = h - 100
    drawButton("DEPART", btnX, btnY, btnW, 52, ar, ag, ab, true)

    -- Tutorial ? button (top right)
    if self.onTutorial then
        love.graphics.setColor(1, 1, 1, 0.22)
        font = love.graphics.newFont(13)
        love.graphics.setFont(font)
        love.graphics.print("?", w - 36, 56)
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
    -- Tutorial button
    if self.onTutorial and inRect(mx, my, w - 48, 48, 32, 32) then
        self.onTutorial()
        return
    end
end

function UI.DepartureScreen:keypressed(key)
    if key == "return" or key == "space" then
        if self.onDepart then self.onDepart() end
    end
end

-------------------------------------------------------------------------------
-- Game Screen (hosts the card table + HUD + phase overlays)
-------------------------------------------------------------------------------

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
    self.showJournal = false   -- NEW: journal overlay toggle
    self.journalScrollY = 0
    self.anim = Animation.new()  -- NEW: card animation system
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
    -- Fust flash decay
    if self.fustFlash > 0 then
        self.fustFlash = math.max(0, self.fustFlash - dt * 2.5)
    end

    -- NEW: Tick card animations
    local w, h = love.graphics.getDimensions()
    self.anim:setDeckSource(w + 80, h / 2)
    self.anim:update(dt)

    -- Detect new cards and register them with animation
    local engine = self.engine
    local cx, cy = w / 2, h / 2

    -- Dealer cards
    for i, card in ipairs(engine.dealerCards) do
        local dx = cx + (i - (#engine.dealerCards + 1) / 2) * Renderer.CARD_SPACING
        local dy = cy - Renderer.DEALER_Y - Renderer.CARD_H / 2
        self.anim:setTarget(card.id, dx, dy, card.isFaceDown)

        -- Detect hole card reveal (face-down → face-up transition)
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

    -- Detect fust for flash
    if engine.phase == Engine.Phase.HAND_RESULT then
        local outcome = engine._pendingOutcome
        if outcome == "playerFust" and not self.fustFlashTriggered then
            self.fustFlash = 1.0
            self.fustFlashTriggered = true
        end
    elseif engine.phase ~= Engine.Phase.HAND_RESULT then
        self.fustFlashTriggered = false
    end

    -- Auto-advance result after delay
    if engine.phase == Engine.Phase.HAND_RESULT then
        self.resultTimer = self.resultTimer + dt
        if self.resultTimer > 1.8 then
            self.resultTimer = 0
            engine:acknowledgeResult()
        end
    else
        self.resultTimer = 0
    end

    -- Clear animation when table clears
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
    Renderer.drawFelt(accentName, self.meta:feltTinted(), w, h)

    -- Draw cards
    self:drawCards(w, h)

    -- HUD
    self:drawHUD(w, h, ar, ag, ab)

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
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setFont(love.graphics.newFont(11))
        local label = "dealer"
        love.graphics.print(label, centerX(label, love.graphics.getFont(), w), h - 70)
    elseif engine.phase == Engine.Phase.HAND_RESULT then
        self:drawHandResult(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.SALVAGE then
        self:drawSalvage(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.SHOP then
        self:drawShop(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.GAME_OVER then
        self:drawGameOver(w, h, ar, ag, ab)
    end

    -- NEW: Journal overlay
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

    -- Dealer cards — use animated positions
    local dc = engine.dealerCards
    local dTotal = #dc
    for i, card in ipairs(dc) do
        local targetDx = cx + (i - (dTotal + 1) / 2) * Renderer.CARD_SPACING
        local targetDy = cy - Renderer.DEALER_Y - Renderer.CARD_H / 2

        -- Use animated position if available
        local animState = self.anim:getState(card.id)
        local dx, dy = targetDx, targetDy
        local scaleX = 1
        if animState then
            dx, dy = animState.x, animState.y
            scaleX = self.anim:getScaleX(card.id)
            -- Use animated face-down state during flip
            if animState.flipping then
                card = { suit = card.suit, rank = card.rank, isFaceDown = animState.faceDown,
                         voyageEffect = card.voyageEffect, fogValue = card.fogValue, fogRevealed = card.fogRevealed }
            end
        end

        -- Apply scaleX for flip
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

    -- Player hands — use animated positions
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

    -- Chip count (top-left)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.print(tostring(engine.chipStack), 20, 56)

    love.graphics.setColor(ar, ag, ab, 0.5)
    love.graphics.setFont(love.graphics.newFont(9))
    love.graphics.print("CHIPS", 20, 52 - 14)

    -- Watch / hand (top-right)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.setFont(love.graphics.newFont(11))
    local watchId = engine:watchIdentity()
    local watchLabel = "WATCH " .. engine.run.currentAct .. " — " .. (watchId.name or "")
    love.graphics.print(watchLabel, w - 20 - love.graphics.getFont():getWidth(watchLabel), 56)

    local handLabel = Run.currentActHandNumber(engine.run) .. " / " .. Run.HandsPerAct
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(love.graphics.newFont(11))
    love.graphics.print(handLabel, w - 20 - love.graphics.getFont():getWidth(handLabel), 72)

    -- Active modifiers (small icons)
    if #engine.run.activeModifiers > 0 then
        local mx = 20
        local my = 90
        for _, mod in ipairs(engine.run.activeModifiers) do
            local icon = Modifier.Icon[mod.type] or "?"
            love.graphics.setColor(ar, ag, ab, 0.4)
            love.graphics.setFont(love.graphics.newFont(11))
            love.graphics.print(icon, mx, my)
            mx = mx + 20
        end
    end

    -- Seeded voyage cards indicator
    local seeded = engine:seededVoyageCards()
    if #seeded > 0 then
        love.graphics.setColor(ar, ag, ab, 0.3)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.print("⚠ " .. #seeded .. " in deck", 20, 110)
    end

    -- Pace indicator (tide mark)
    if engine:paceDeficit() then
        local deficit = engine:paceDeficit()
        local fill = deficit == 0 and 1.0 or math.max(0, 1.0 - deficit / 60)
        local barW = 56 * fill
        love.graphics.setColor(1, 1, 1, 0.06)
        love.graphics.rectangle("fill", 20, 128, 56, 3, 1.5, 1.5, 1.5, 1.5)
        if deficit == 0 then
            love.graphics.setColor(ar, ag, ab, 0.7)
        elseif deficit < 20 then
            love.graphics.setColor(ar, ag, ab, 0.45)
        elseif deficit < 40 then
            love.graphics.setColor(1, 1, 1, 0.25)
        else
            love.graphics.setColor(0.75, 0.3, 0.3, 0.7)
        end
        love.graphics.rectangle("fill", 20, 128, barW, 3, 1.5, 1.5, 1.5, 1.5)
    end

    -- Current bet (during play)
    if engine.phase == Engine.Phase.PLAYER_TURN or engine.phase == Engine.Phase.DEALER_TURN then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setFont(love.graphics.newFont(9))
        love.graphics.print("BET", centerX("BET", love.graphics.getFont(), w), 100)
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.setFont(love.graphics.newFont(22))
        local betStr = tostring(engine:activeBet())
        love.graphics.print(betStr, centerX(betStr, love.graphics.getFont(), w), 114)
    end

    -- Hand value (during play)
    if engine.phase == Engine.Phase.PLAYER_TURN or engine.phase == Engine.Phase.DEALER_TURN then
        local pv = engine:playerValue()
        local valStr = tostring(pv.soft)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print(valStr, centerX(valStr, love.graphics.getFont(), w), h * 0.65)
    end
end

function UI.GameScreen:drawBetting(w, h, ar, ag, ab)
    local engine = self.engine
    local minBet = engine:effectiveMinimumBet()
    local btnW = 120
    local btnH = 44
    local spacing = 12
    local totalW = btnW * 2 + spacing
    local startX = (w - totalW) / 2
    local btnY = h - 80

    -- Known waters card display
    if engine.knownWatersCard then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setFont(love.graphics.newFont(11))
        local cardStr = Card.RankNames[engine.knownWatersCard.rank] .. Card.SuitSymbol[engine.knownWatersCard.suit]
        local label = "Top card: " .. cardStr
        love.graphics.print(label, centerX(label, love.graphics.getFont(), w), h - 120)
    end

    -- Bet buttons: -10 / +10 / DEAL
    local font = love.graphics.newFont(13)
    love.graphics.setFont(font)

    -- Minus button
    drawButton("- 10", startX, btnY, btnW / 2 - 4, btnH, ar, ag, ab, false)
    -- Plus button
    drawButton("+ 10", startX + btnW / 2 + 4, btnY, btnW / 2 - 4, btnH, ar, ag, ab, false)
    -- Current bet display
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setFont(love.graphics.newFont(18))
    local betStr = tostring(self._betAmount or minBet)
    love.graphics.print(betStr, centerX(betStr, love.graphics.getFont(), w), btnY - 30)
    love.graphics.setFont(love.graphics.newFont(9))
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.print("BET (min " .. minBet .. ")", centerX("BET (min " .. minBet .. ")", love.graphics.getFont(), w), btnY - 46)

    -- DEAL button
    local dealW = 140
    drawButton("DEAL", (w - dealW) / 2, btnY + btnH + 10, dealW, 44, ar, ag, ab, true)
end

function UI.GameScreen:drawActionsBar(w, h, ar, ag, ab)
    local engine = self.engine
    local btnW = 80
    local btnH = 44
    local spacing = 10
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
    if outcome == "playerWin" then label = "AFLOAT"
    elseif outcome == "dealerFust" then label = "DEALER FUST"
    elseif outcome == "push" then label = "PUSH"
    elseif outcome == "playerFust" then label = "FUST"
    elseif outcome == "dealerWin" then label = "UNDER"
    else label = "—" end

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, h * 0.35, w, h * 0.3)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.print(label, centerX(label, love.graphics.getFont(), w), h * 0.4)

    if delta ~= 0 then
        local dStr = (delta > 0 and "+" or "") .. tostring(delta)
        love.graphics.setColor(delta > 0 and {ar, ag, ab} or {0.8, 0.3, 0.3})
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.print(dStr, centerX(dStr, love.graphics.getFont(), w), h * 0.4 + 36)
    end
end

function UI.GameScreen:drawTide(w, h, ar, ag, ab)
    local engine = self.engine
    local bet = self._pendingBet or 0

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, h * 0.25, w, h * 0.5)

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(love.graphics.newFont(11))
    local title = "THE TIDE"
    love.graphics.print(title, centerX(title, love.graphics.getFont(), w), h * 0.27)

    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(love.graphics.newFont(10))
    local sub = "Bet: " .. bet .. " — choose your tide"
    love.graphics.print(sub, centerX(sub, love.graphics.getFont(), w), h * 0.27 + 18)

    -- Three tide options
    local cardW = math.min(120, (w - 60) / 3)
    local cardH = 160
    local spacing = 12
    local totalW = 3 * cardW + 2 * spacing
    local startX = (w - totalW) / 2
    local cardY = h * 0.35

    local tides = {
        { key = "rising",  name = "RISING",  desc = "+20% payout\nDealer draws\none extra card" },
        { key = "falling", name = "FALLING", desc = "-20% payout\nSee dealer's\nhole card" },
        { key = "flat",    name = "FLAT",    desc = "No modification\nSafe passage" },
    }

    for i, tide in ipairs(tides) do
        local cx = startX + (i - 1) * (cardW + spacing)
        love.graphics.setColor(ar * 0.1, ag * 0.1, ab * 0.1, 1)
        love.graphics.rectangle("fill", cx, cardY, cardW, cardH, 10, 10, 10, 10)
        love.graphics.setColor(ar, ag, ab, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", cx, cardY, cardW, cardH, 10, 10, 10, 10)

        -- Name
        love.graphics.setColor(ar, ag, ab, 0.8)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print(tide.name, cx + (cardW - love.graphics.getFont():getWidth(tide.name)) / 2, cardY + 12)

        -- Description
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.setFont(love.graphics.newFont(10))
        local descLines = {}
        for line in tide.desc:gmatch("[^\n]+") do table.insert(descLines, line) end
        for j, line in ipairs(descLines) do
            love.graphics.print(line, cx + (cardW - love.graphics.getFont():getWidth(line)) / 2, cardY + 44 + (j - 1) * 14)
        end
    end
end

function UI.GameScreen:drawSalvage(w, h, ar, ag, ab)
    local engine = self.engine
    local candidates = engine.draftCandidates
    if #candidates == 0 then return end

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(love.graphics.newFont(11))
    local title = "SALVAGE"
    love.graphics.print(title, centerX(title, love.graphics.getFont(), w), h * 0.08)

    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(love.graphics.newFont(10))
    local sub = "Take the flotsam, or seed the reef for chips"
    love.graphics.print(sub, centerX(sub, love.graphics.getFont(), w), h * 0.08 + 18)

    -- NEW: If an artefact was found, display it prominently
    if engine.lastArtefactFound then
        local a = engine.lastArtefactFound
        love.graphics.setColor(ar, ag, ab, 0.15)
        love.graphics.rectangle("fill", w * 0.1, h * 0.13, w * 0.8, 80, 10, 10, 10, 10)
        love.graphics.setColor(ar, ag, ab, 0.6)
        love.graphics.setFont(love.graphics.newFont(13))
        local aTitle = "✦ " .. a.title:upper()
        love.graphics.print(aTitle, centerX(aTitle, love.graphics.getFont(), w), h * 0.14)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setFont(love.graphics.newFont(10))
        local aLines = wrapText(a.text, love.graphics.getFont(), w * 0.7)
        for i, line in ipairs(aLines) do
            if i <= 3 then  -- max 3 lines in the small display
                love.graphics.print(line, centerX(line, love.graphics.getFont(), w), h * 0.14 + 22 + (i - 1) * 14)
            end
        end
        love.graphics.setColor(ar, ag, ab, 0.4)
        love.graphics.setFont(love.graphics.newFont(9))
        local note = "New entry in your journal"
        love.graphics.print(note, centerX(note, love.graphics.getFont(), w), h * 0.14 + 66)
    end

    -- Left option: Take Flotsam
    local cardW = math.min(140, (w - 60) / 2)
    local cardH = 100
    local leftX = (w / 2) - cardW - 8
    local rightX = (w / 2) + 8
    local cardY = h * 0.18

    love.graphics.setColor(ar * 0.1, ag * 0.1, ab * 0.1, 1)
    love.graphics.rectangle("fill", leftX, cardY, cardW, cardH, 10, 10, 10, 10)
    love.graphics.setColor(ar, ag, ab, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", leftX, cardY, cardW, cardH, 10, 10, 10, 10)

    love.graphics.setColor(ar, ag, ab, 0.8)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("FLOTSAM", leftX + (cardW - love.graphics.getFont():getWidth("FLOTSAM")) / 2, cardY + 12)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.setFont(love.graphics.newFont(10))
    local fLines = wrapText("+1 Flotsam — bank it, keep the deck clean", love.graphics.getFont(), cardW - 12)
    for j, line in ipairs(fLines) do
        love.graphics.print(line, leftX + (cardW - love.graphics.getFont():getWidth(line)) / 2, cardY + 36 + (j - 1) * 14)
    end

    -- Right option: Seed the Reef (pick one of 3 voyage cards)
    love.graphics.setColor(ar * 0.1, ag * 0.1, ab * 0.1, 1)
    love.graphics.rectangle("fill", rightX, cardY, cardW, cardH, 10, 10, 10, 10)
    love.graphics.setColor(ar, ag, ab, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", rightX, cardY, cardW, cardH, 10, 10, 10, 10)

    love.graphics.setColor(ar, ag, ab, 0.8)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("SEED THE REEF", rightX + (cardW - love.graphics.getFont():getWidth("SEED THE REEF")) / 2, cardY + 12)

    local handsLeft = Run.HandsPerAct - Run.currentActHandNumber(engine.run)
    local bonus = math.max(0, handsLeft) * 2
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.setFont(love.graphics.newFont(10))
    local rLines = wrapText("+" .. bonus .. " chips now — but poison the deck", love.graphics.getFont(), cardW - 12)
    for j, line in ipairs(rLines) do
        love.graphics.print(line, rightX + (cardW - love.graphics.getFont():getWidth(line)) / 2, cardY + 36 + (j - 1) * 14)
    end

    -- Voyage card choices (only if reef is selected — show 3 cards below)
    local vCardW = Renderer.CARD_W * 1.1
    local vCardH = Renderer.CARD_H * 1.1
    local vSpacing = 12
    local vTotalW = 3 * vCardW + 2 * vSpacing
    local vStartX = (w - vTotalW) / 2
    local vCardY = h * 0.38

    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(love.graphics.newFont(9))
    local reefTitle = "PICK A CARD TO SEED:"
    love.graphics.print(reefTitle, centerX(reefTitle, love.graphics.getFont(), w), vCardY - 18)

    for i, vtype in ipairs(candidates) do
        local cx = vStartX + (i - 1) * (vCardW + vSpacing)
        local fakeCard = { voyageEffect = vtype, fogRevealed = false, fogValue = nil, isFaceDown = false }
        if vtype == "fogBank" then fakeCard.fogValue = math.random(4, 9) end
        Renderer.drawVoyageCardFace(fakeCard, cx, vCardY, vCardW, vCardH, engine.run.accentColor)

        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.setFont(love.graphics.newFont(9))
        local name = VoyageCard.DisplayName[vtype]
        love.graphics.print(name, cx + (vCardW - love.graphics.getFont():getWidth(name)) / 2, vCardY + vCardH + 4)
    end
end

function UI.GameScreen:drawShop(w, h, ar, ag, ab)
    local engine = self.engine
    local meta = self.meta

    -- Background
    love.graphics.setColor(0.07, 0.07, 0.07, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Title
    love.graphics.setColor(1, 1, 1, 0.35)
    love.graphics.setFont(love.graphics.newFont(11))
    local title = "THE WHARF"
    love.graphics.print(title, centerX(title, love.graphics.getFont(), w), 56)

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(love.graphics.newFont(13))
    local watchId = engine:watchIdentity()
    local watchLabel = "Watch " .. engine.run.currentAct .. " of " .. engine:effectiveActCount() .. " — " .. (watchId.name or "")
    love.graphics.print(watchLabel, centerX(watchLabel, love.graphics.getFont(), w), 74)

    -- NEW: Wharf ambient text (watch-based transformation)
    love.graphics.setColor(1, 1, 1, 0.25)
    love.graphics.setFont(love.graphics.newFont(10))
    local ambient = Dialogue.wharfAmbient(engine.run.currentAct)
    local ambLines = wrapText(ambient, love.graphics.getFont(), w - 48)
    for i, line in ipairs(ambLines) do
        love.graphics.print(line, 24, 94 + (i - 1) * 12)
    end

    -- NEW: Journal button (top right) if any artefacts collected
    if meta:artefactCount() > 0 then
        local jLabel = "📖 " .. meta:artefactCount()
        if meta.journalNewCount > 0 then
            jLabel = jLabel .. " (" .. meta.journalNewCount .. " new)"
        end
        love.graphics.setColor(ar, ag, ab, 0.6)
        love.graphics.setFont(love.graphics.newFont(11))
        local jw = love.graphics.getFont():getWidth(jLabel)
        love.graphics.print(jLabel, w - jw - 20, 56)
    end

    -- Chip count
    love.graphics.setColor(ar, ag, ab, 0.8)
    love.graphics.setFont(love.graphics.newFont(22))
    local chipStr = tostring(engine.chipStack)
    love.graphics.print(chipStr, centerX(chipStr, love.graphics.getFont(), w), 96)

    -- NPC speaker
    local speaker = Dialogue.randomWharfSpeaker(engine.run.currentAct, meta:unlockedSet())
    if speaker then
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.setFont(love.graphics.newFont(12))
        local spLabel = speaker.name .. " is here"
        love.graphics.print(spLabel, centerX(spLabel, love.graphics.getFont(), w), 140)
    end

    -- Shop offer cards
    local offer = engine:getShopOffer()
    if #offer > 0 then
        local cardW = math.min(100, (w - 60) / 3)
        local cardH = 140
        local spacing = 12
        local totalW = #offer * cardW + (#offer - 1) * spacing
        local startX = (w - totalW) / 2
        local cardY = 200

        for i, modType in ipairs(offer) do
            local cx = startX + (i - 1) * (cardW + spacing)
            local price = engine:shopPrice(modType)
            local canAfford = engine.chipStack >= price
            local isOwned = Run.hasModifier(engine.run, modType)

            -- Card background
            if canAfford and not isOwned then
                love.graphics.setColor(ar * 0.1, ag * 0.1, ab * 0.1, 1)
            else
                love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
            end
            love.graphics.rectangle("fill", cx, cardY, cardW, cardH, 10, 10, 10, 10)

            if canAfford and not isOwned then
                love.graphics.setColor(ar, ag, ab, 0.3)
                love.graphics.setLineWidth(1)
                love.graphics.rectangle("line", cx, cardY, cardW, cardH, 10, 10, 10, 10)
            end

            -- Icon
            love.graphics.setColor(ar, ag, ab, 0.8)
            love.graphics.setFont(love.graphics.newFont(20))
            local icon = Modifier.Icon[modType] or "?"
            love.graphics.print(icon, cx + (cardW - love.graphics.getFont():getWidth(icon)) / 2, cardY + 12)

            -- Name
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.setFont(love.graphics.newFont(11))
            local name = Modifier.DisplayName[modType]
            local nameLines = wrapText(name, love.graphics.getFont(), cardW - 12)
            for j, line in ipairs(nameLines) do
                love.graphics.print(line, cx + (cardW - love.graphics.getFont():getWidth(line)) / 2, cardY + 40 + (j - 1) * 14)
            end

            -- Description (truncated)
            love.graphics.setColor(1, 1, 1, 0.35)
            love.graphics.setFont(love.graphics.newFont(9))
            local descLines = wrapText(Modifier.Description[modType], love.graphics.getFont(), cardW - 12)
            for j, line in ipairs(math.min(#descLines, 4) > 0 and {descLines[1], descLines[2], descLines[3], descLines[4]} or {}) do
                if line then
                    love.graphics.print(line, cx + (cardW - love.graphics.getFont():getWidth(line)) / 2, cardY + 70 + (j - 1) * 12)
                end
            end

            -- Price
            love.graphics.setColor(canAfford and {ar, ag, ab} or {0.4, 0.4, 0.4})
            love.graphics.setFont(love.graphics.newFont(16))
            local priceStr = tostring(price)
            love.graphics.print(priceStr, cx + (cardW - love.graphics.getFont():getWidth(priceStr)) / 2, cardY + cardH - 22)
        end
    end

    -- Float a loan button
    if not engine.run.loanUsedThisAct then
        drawButton("Float a Loan  +" .. Run.LoanAmount, 24, h - 120, w - 48, 44, ar, ag, ab, false)
    end

    -- Depart button
    drawButton("DEPART", 24, h - 68, w - 48, 44, ar, ag, ab, true)
end

function UI.GameScreen:drawGameOver(w, h, ar, ag, ab)
    local engine = self.engine
    local outcome = engine.run.outcome
    local meta = self.meta

    love.graphics.setColor(0.07, 0.07, 0.07, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)

    local title
    if outcome == "won" then title = "AFLOAT"
    else title = "FOUNDERED" end

    love.graphics.setColor(outcome == "won" and {ar, ag, ab} or {0.8, 0.3, 0.3})
    love.graphics.setFont(love.graphics.newFont(36))
    love.graphics.print(title, centerX(title, love.graphics.getFont(), w), h * 0.2)

    -- Flotsam earned
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.setFont(love.graphics.newFont(16))
    local flotsamStr = "+" .. engine.run.flotsamEarned .. " Flotsam"
    love.graphics.print(flotsamStr, centerX(flotsamStr, love.graphics.getFont(), w), h * 0.3)

    -- Character reactions
    local actsCompleted = engine.run.currentAct - 1
    if outcome == "won" then actsCompleted = actsCompleted + 1 end

    local y = h * 0.4
    for _, charKey in ipairs(Dialogue.Characters) do
        local requiredNode = Dialogue.CharacterRequiredNode[charKey]
        if not requiredNode or meta:hasUnlock(requiredNode) then
            local line = Dialogue.hubLine(charKey, actsCompleted, outcome)
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.setFont(love.graphics.newFont(10))
            love.graphics.print(Dialogue.CharacterDisplayName[charKey]:upper(), 40, y)
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.setFont(love.graphics.newFont(13))
            local lines = wrapText(line, love.graphics.getFont(), w - 80)
            for i, l in ipairs(lines) do
                love.graphics.print(l, 40, y + 16 + (i - 1) * 18)
            end
            y = y + 16 + #lines * 18 + 20
        end
    end

    -- New run button
    drawButton("NEW VOYAGE", (w - 200) / 2, h - 80, 200, 48, ar, ag, ab, true)
end

-------------------------------------------------------------------------------
-- NEW: Journal screen
-------------------------------------------------------------------------------

function UI.GameScreen:drawJournal(w, h, ar, ag, ab)
    local meta = self.meta

    -- Full overlay
    love.graphics.setColor(0.04, 0.04, 0.04, 0.97)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Title
    love.graphics.setColor(ar, ag, ab, 0.6)
    love.graphics.setFont(love.graphics.newFont(14))
    local title = "FLOTSAM JOURNAL"
    love.graphics.print(title, 24, 24)

    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(love.graphics.newFont(10))
    local count = meta:artefactCount()
    local total = Artefacts.getCount()
    local countStr = count .. " of " .. total .. " found"
    love.graphics.print(countStr, 24, 44)

    -- Close button (top right)
    love.graphics.setColor(1, 1, 1, 0.4)
    love.graphics.setFont(love.graphics.newFont(13))
    love.graphics.print("×", w - 36, 24)

    -- Artefact entries (scrollable)
    local y = 72 - self.journalScrollY
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setFont(love.graphics.newFont(12))

    for _, id in ipairs(meta.collectedArtefacts) do
        local a = Artefacts.ById[id]
        if not a then goto continue end

        -- Skip if off-screen
        if y > h - 20 then goto continue end
        if y < 60 then goto next_entry end

        -- Title
        love.graphics.setColor(ar, ag, ab, 0.7)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.print("✦ " .. a.title, 24, y)

        -- Text
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setFont(love.graphics.newFont(10))
        local lines = wrapText(a.text, love.graphics.getFont(), w - 48)
        for i, line in ipairs(lines) do
            love.graphics.print(line, 24, y + 18 + (i - 1) * 14)
        end

        y = y + 18 + #lines * 14 + 16

        ::next_entry::
        ::continue::
    end

    -- Empty state
    if count == 0 then
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.setFont(love.graphics.newFont(13))
        local empty = "No artefacts found yet."
        love.graphics.print(empty, centerX(empty, love.graphics.getFont(), w), h * 0.4)
        love.graphics.setFont(love.graphics.newFont(10))
        local empty2 = "Take flotsam during salvage to find artefacts."
        love.graphics.print(empty2, centerX(empty2, love.graphics.getFont(), w), h * 0.4 + 20)
    end

    -- Scroll hint
    if y > h then
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.setFont(love.graphics.newFont(9))
        love.graphics.print("scroll: ↑↓ keys", w - 100, h - 20)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function UI.GameScreen:drawLuckyStart(w, h, ar, ag, ab)
    local engine = self.engine
    local offer = engine.luckyStartOffer
    if #offer == 0 then return end

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(love.graphics.newFont(11))
    local title = "LUCKY START — FREE MODIFIER"
    love.graphics.print(title, centerX(title, love.graphics.getFont(), w), h * 0.2)

    local cardW = math.min(100, (w - 60) / 3)
    local cardH = 120
    local spacing = 12
    local totalW = #offer * cardW + (#offer - 1) * spacing
    local startX = (w - totalW) / 2
    local cardY = h * 0.3

    for i, modType in ipairs(offer) do
        local cx = startX + (i - 1) * (cardW + spacing)
        love.graphics.setColor(ar * 0.1, ag * 0.1, ab * 0.1, 1)
        love.graphics.rectangle("fill", cx, cardY, cardW, cardH, 10, 10, 10, 10)
        love.graphics.setColor(ar, ag, ab, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", cx, cardY, cardW, cardH, 10, 10, 10, 10)

        love.graphics.setColor(ar, ag, ab, 0.8)
        love.graphics.setFont(love.graphics.newFont(18))
        local icon = Modifier.Icon[modType] or "?"
        love.graphics.print(icon, cx + (cardW - love.graphics.getFont():getWidth(icon)) / 2, cardY + 10)

        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.setFont(love.graphics.newFont(10))
        local name = Modifier.DisplayName[modType]
        local nameLines = wrapText(name, love.graphics.getFont(), cardW - 8)
        for j, line in ipairs(nameLines) do
            love.graphics.print(line, cx + (cardW - love.graphics.getFont():getWidth(line)) / 2, cardY + 36 + (j - 1) * 12)
        end
    end

    -- Skip button
    drawButton("SKIP", (w - 100) / 2, h * 0.6, 100, 40, ar, ag, ab, false)
end

-------------------------------------------------------------------------------
-- Input handling
-------------------------------------------------------------------------------

function UI.GameScreen:mousepressed(mx, my, button)
    local w, h = love.graphics.getDimensions()
    local engine = self.engine
    local ar, ag, ab = accent(engine.run.accentColor)

    -- NEW: Journal overlay takes priority
    if self.showJournal then
        -- Close button (×)
        if inRect(mx, my, w - 48, 20, 32, 32) then
            self.showJournal = false
            self.meta:clearJournalNewCount()
            return
        end
        -- Click anywhere else in journal = stay (scroll handled by keys)
        return
    end

    -- NEW: Journal button in shop
    if engine.phase == Engine.Phase.SHOP and self.meta:artefactCount() > 0 then
        local jLabel = "📖 " .. self.meta:artefactCount()
        if self.meta.journalNewCount > 0 then
            jLabel = jLabel .. " (" .. self.meta.journalNewCount .. " new)"
        end
        local font = love.graphics.newFont(11)
        local jw = font:getWidth(jLabel)
        if inRect(mx, my, w - jw - 28, 48, jw + 16, 24) then
            self.showJournal = true
            self.journalScrollY = 0
            return
        end
    end

    if engine.phase == Engine.Phase.BETTING then
        if #engine.luckyStartOffer > 0 then
            -- Lucky start cards
            local offer = engine.luckyStartOffer
            local cardW = math.min(100, (w - 60) / 3)
            local cardH = 120
            local spacing = 12
            local totalW = #offer * cardW + (#offer - 1) * spacing
            local startX = (w - totalW) / 2
            local cardY = h * 0.3
            for i, _ in ipairs(offer) do
                local cx = startX + (i - 1) * (cardW + spacing)
                if inRect(mx, my, cx, cardY, cardW, cardH) then
                    engine:acceptLuckyStartOffer(offer[i])
                    return
                end
            end
            -- Skip
            if inRect(mx, my, (w - 100) / 2, h * 0.6, 100, 40) then
                engine:skipLuckyStart()
                return
            end
        else
            -- Betting controls
            local minBet = engine:effectiveMinimumBet()
            local btnW = 120
            local btnH = 44
            local btnY = h - 80
            local startX = (w - btnW) / 2

            -- Minus
            if inRect(mx, my, startX, btnY, btnW / 2 - 4, btnH) then
                self._betAmount = math.max(minBet, (self._betAmount or minBet) - 10)
                return
            end
            -- Plus
            if inRect(mx, my, startX + btnW / 2 + 4, btnY, btnW / 2 - 4, btnH) then
                self._betAmount = math.min(engine.chipStack, (self._betAmount or minBet) + 10)
                return
            end
            -- Deal
            local dealW = 140
            if inRect(mx, my, (w - dealW) / 2, btnY + btnH + 10, dealW, 44) then
                engine:placeBet(self._betAmount or minBet)
                self._betAmount = nil
                return
            end
        end

    elseif engine.phase == Engine.Phase.TIDE then
        -- Three tide choices
        local cardW = math.min(120, (w - 60) / 3)
        local cardH = 160
        local spacing = 12
        local totalW = 3 * cardW + 2 * spacing
        local startX = (w - totalW) / 2
        local cardY = h * 0.35

        local tides = { "rising", "falling", "flat" }
        for i, tide in ipairs(tides) do
            local cx = startX + (i - 1) * (cardW + spacing)
            if inRect(mx, my, cx, cardY, cardW, cardH) then
                engine:chooseTide(tide)
                return
            end
        end

    elseif engine.phase == Engine.Phase.PLAYER_TURN then
        local btnW = 80
        local btnH = 44
        local spacing = 10
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
        local cardW = math.min(140, (w - 60) / 2)
        local cardH = 100
        local leftX = (w / 2) - cardW - 8
        local rightX = (w / 2) + 8
        local cardY = h * 0.18

        -- Flotsam (left)
        if inRect(mx, my, leftX, cardY, cardW, cardH) then
            engine:chooseSalvage("flotsam")
            return
        end

        -- Reef cards (below)
        if #candidates > 0 then
            local vCardW = Renderer.CARD_W * 1.1
            local vCardH = Renderer.CARD_H * 1.1
            local vSpacing = 12
            local vTotalW = 3 * vCardW + 2 * vSpacing
            local vStartX = (w - vTotalW) / 2
            local vCardY = h * 0.38
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
            local cardW = math.min(100, (w - 60) / 3)
            local cardH = 140
            local spacing = 12
            local totalW = #offer * cardW + (#offer - 1) * spacing
            local startX = (w - totalW) / 2
            local cardY = 200
            for i, modType in ipairs(offer) do
                local cx = startX + (i - 1) * (cardW + spacing)
                if inRect(mx, my, cx, cardY, cardW, cardH) then
                    engine:purchaseModifier(modType)
                    return
                end
            end
        end
        -- Float a loan
        if not engine.run.loanUsedThisAct then
            if inRect(mx, my, 24, h - 120, w - 48, 44) then
                engine:takeLoan()
                return
            end
        end
        -- Depart
        if inRect(mx, my, 24, h - 68, w - 48, 44) then
            engine:leaveShop()
            return
        end

    elseif engine.phase == Engine.Phase.GAME_OVER then
        if inRect(mx, my, (w - 200) / 2, h - 80, 200, 48) then
            if self.onNewRun then self.onNewRun() end
            return
        end
    end
end

function UI.GameScreen:keypressed(key)
    local engine = self.engine

    -- NEW: Journal navigation
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

    -- NEW: Toggle journal with J in shop
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
        elseif key == "p" then engine:split()
        end
    elseif engine.phase == Engine.Phase.BETTING and #engine.luckyStartOffer == 0 then
        if key == "return" or key == "space" then
            local minBet = engine:effectiveMinimumBet()
            engine:placeBet(self._betAmount or minBet)
            self._betAmount = nil
        end
    elseif engine.phase == Engine.Phase.TIDE then
        if key == "1" then engine:chooseTide("rising")
        elseif key == "2" then engine:chooseTide("falling")
        elseif key == "3" then engine:chooseTide("flat")
        end
    elseif engine.phase == Engine.Phase.SALVAGE then
        if key == "f" then engine:chooseSalvage("flotsam")
        elseif key == "1" then engine:chooseSalvage("reef", engine.draftCandidates[1])
        elseif key == "2" then engine:chooseSalvage("reef", engine.draftCandidates[2])
        elseif key == "3" then engine:chooseSalvage("reef", engine.draftCandidates[3])
        end
    elseif engine.phase == Engine.Phase.GAME_OVER then
        if key == "return" or key == "space" then
            if self.onNewRun then self.onNewRun() end
        end
    end
end

return UI