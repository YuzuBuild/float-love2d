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
    return {
        higgsLine = higgsLine,
        condition = condition,
        accentColor = accentColor,
        onDepart = onDepart,
        onTutorial = onTutorial,
    }
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

    -- Auto-advance result after delay
    if self.engine.phase == Engine.Phase.HAND_RESULT then
        self.resultTimer = self.resultTimer + dt
        if self.resultTimer > 1.8 then
            self.resultTimer = 0
            self.engine:acknowledgeResult()
        end
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
    elseif engine.phase == Engine.Phase.PLAYER_TURN then
        self:drawActionsBar(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.DEALER_TURN then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setFont(love.graphics.newFont(11))
        local label = "dealer"
        love.graphics.print(label, centerX(label, love.graphics.getFont(), w), h - 70)
    elseif engine.phase == Engine.Phase.HAND_RESULT then
        self:drawHandResult(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.CARD_DRAFT then
        self:drawCardDraft(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.SHOP then
        self:drawShop(w, h, ar, ag, ab)
    elseif engine.phase == Engine.Phase.GAME_OVER then
        self:drawGameOver(w, h, ar, ag, ab)
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
        local dx = cx + (i - (dTotal + 1) / 2) * Renderer.CARD_SPACING
        local dy = cy - Renderer.DEALER_Y - Renderer.CARD_H / 2
        Renderer.drawCard(card, dx, dy, Renderer.CARD_W, Renderer.CARD_H, accentName)
    end

    -- Player hands
    local ph = engine.playerHands
    local handCount = #ph
    for hIdx, hand in ipairs(ph) do
        local handOffset = 0
        if handCount == 2 then
            handOffset = hIdx == 1 and -120 or 120
        end
        local total = #hand
        for i, card in ipairs(hand) do
            local dx = cx + handOffset + (i - (total + 1) / 2) * Renderer.CARD_SPACING
            local dy = cy + Renderer.PLAYER_Y - Renderer.CARD_H / 2
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
    local watchLabel = "WATCH " .. engine.run.currentAct
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

function UI.GameScreen:drawCardDraft(w, h, ar, ag, ab)
    local engine = self.engine
    local candidates = engine.draftCandidates
    if #candidates == 0 then return end

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Title
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(love.graphics.newFont(11))
    local title = "SEED THE DECK"
    love.graphics.print(title, centerX(title, love.graphics.getFont(), w), h * 0.15)

    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setFont(love.graphics.newFont(10))
    local sub = "Choose a card to add to the shared deck"
    love.graphics.print(sub, centerX(sub, love.graphics.getFont(), w), h * 0.15 + 18)

    -- Card options
    local cardW = Renderer.CARD_W * 1.3
    local cardH = Renderer.CARD_H * 1.3
    local spacing = 16
    local totalW = 3 * cardW + 2 * spacing
    local startX = (w - totalW) / 2
    local cardY = h * 0.35

    for i, vtype in ipairs(candidates) do
        local cx = startX + (i - 1) * (cardW + spacing)
        -- Draw a fake voyage card for display
        local fakeCard = { voyageEffect = vtype, fogRevealed = false, fogValue = nil, isFaceDown = false }
        if vtype == "fogBank" then fakeCard.fogValue = math.random(4, 9) end
        Renderer.drawVoyageCardFace(fakeCard, cx, cardY, cardW, cardH, engine.run.accentColor)

        -- Name below
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setFont(love.graphics.newFont(12))
        local name = VoyageCard.DisplayName[vtype]
        love.graphics.print(name, cx + (cardW - love.graphics.getFont():getWidth(name)) / 2, cardY + cardH + 8)

        -- Description
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setFont(love.graphics.newFont(10))
        local descLines = wrapText(VoyageCard.Description[vtype], love.graphics.getFont(), cardW + 20)
        for j, line in ipairs(descLines) do
            love.graphics.print(line, cx + (cardW - love.graphics.getFont():getWidth(line)) / 2, cardY + cardH + 26 + (j - 1) * 14)
        end
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
    local watchLabel = "Watch " .. engine.run.currentAct .. " of " .. engine:effectiveActCount()
    love.graphics.print(watchLabel, centerX(watchLabel, love.graphics.getFont(), w), 74)

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

    elseif engine.phase == Engine.Phase.CARD_DRAFT then
        local candidates = engine.draftCandidates
        if #candidates == 0 then return end
        local cardW = Renderer.CARD_W * 1.3
        local cardH = Renderer.CARD_H * 1.3
        local spacing = 16
        local totalW = 3 * cardW + 2 * spacing
        local startX = (w - totalW) / 2
        local cardY = h * 0.35
        for i, _ in ipairs(candidates) do
            local cx = startX + (i - 1) * (cardW + spacing)
            if inRect(mx, my, cx, cardY, cardW, cardH) then
                engine:selectDraftCard(candidates[i])
                return
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
    elseif engine.phase == Engine.Phase.GAME_OVER then
        if key == "return" or key == "space" then
            if self.onNewRun then self.onNewRun() end
        end
    end
end

return UI