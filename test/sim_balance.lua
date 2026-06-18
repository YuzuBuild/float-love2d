-- Balance simulation: plays N runs with basic strategy, reports win rate
-- Run with: love . --sim 1000

local Card = require("src.models.card")
local Run = require("src.models.run")
local Engine = require("src.engine.engine")
local Meta = require("src.models.meta")
local Modifier = require("src.models.modifiers")

local Sim = {}

-- Basic strategy: should the player hit?
-- Hit on 16 or lower. Stand on hard 17+. Hit soft 17 in watch 2+.
local function basicStrategyHit(engine)
    local pv = engine:playerValue()
    if pv.isBust then return false end
    if pv.soft <= 16 then return true end
    if pv.soft == 17 then
        -- Hit soft 17 in watch 2+, stand on hard 17
        if pv.hard ~= pv.soft and engine.run.currentAct >= 2 then
            return true
        end
        return false
    end
    return false
end

-- Decide bet amount: bet more when behind on pace
local function decideBet(engine)
    local stack = engine.chipStack
    local minBet = engine:effectiveMinimumBet()
    local threshold = Run.departureThreshold(engine.run.currentAct)
    local needed = threshold - stack
    local handsLeft = Run.HandsPerAct - Run.currentActHandNumber(engine.run) + 1
    local perHand = needed / handsLeft

    -- Base bet: 25% of stack
    local bet = math.floor(stack * 0.25)
    -- If behind on pace, bet more (up to 40%)
    if needed > 0 and perHand > stack * 0.15 then
        bet = math.floor(stack * 0.35)
    end
    -- Clamp
    bet = math.max(minBet, math.min(stack, bet))
    -- Round to nearest 10
    bet = math.floor(bet / 10) * 10
    if bet < minBet then bet = minBet end
    if bet > stack then bet = stack end
    return bet
end

-- Play a single run to completion
local function playRun(meta)
    local run = Run.new({ startingChips = meta:startingChips() })
    run.runCondition = Run.Condition[math.random(#Run.Condition)]
    local engine = Engine.new(run, meta)

    local maxHands = 25  -- safety limit
    local handsPlayed = 0

    while engine.phase ~= Engine.Phase.GAME_OVER and handsPlayed < maxHands do
        handsPlayed = handsPlayed + 1

        -- Betting
        if engine.phase == Engine.Phase.BETTING then
            if #engine.luckyStartOffer > 0 then
                engine:skipLuckyStart()
            end
            local bet = decideBet(engine)
            if bet < engine:effectiveMinimumBet() then
                -- Can't afford min bet — should foundered
                break
            end
            engine:placeBet(bet)
        end

        -- Tide: choose rising when ahead, flat when behind
        if engine.phase == Engine.Phase.TIDE then
            local stack = engine.chipStack
            local threshold = Run.departureThreshold(engine.run.currentAct)
            local needed = threshold - stack
            local handsLeft = Run.HandsPerAct - Run.currentActHandNumber(engine.run) + 1
            if needed > 0 and needed / handsLeft > 40 then
                engine:chooseTide("rising")  -- push for more
            else
                engine:chooseTide("flat")
            end
        end

        -- Player turn: basic strategy with double down
        if engine.phase == Engine.Phase.PLAYER_TURN then
            -- Check for double down opportunity (10 or 11, first action)
            if engine:canDouble() then
                local pv = engine:playerValue()
                local dv = engine:dealerValue()
                -- Double on 10 or 11 when dealer shows 2-6 or 9-A
                if (pv.soft == 10 or pv.soft == 11) then
                    engine:doubleDown()
                    goto continue_loop
                end
            end

            while engine.phase == Engine.Phase.PLAYER_TURN do
                if basicStrategyHit(engine) then
                    engine:hit()
                else
                    engine:stand()
                end
            end
        end

        ::continue_loop::

        -- Dealer turn: auto-resolves
        -- Hand result: auto-acknowledge after a virtual delay
        if engine.phase == Engine.Phase.HAND_RESULT then
            engine:acknowledgeResult()
        end

        -- Salvage: reef early in watch for chips, flotsam late
        if engine.phase == Engine.Phase.SALVAGE then
            local handInWatch = Run.currentActHandNumber(engine.run)
            if handInWatch <= 3 and #engine.draftCandidates > 0 then
                engine:chooseSalvage("reef", engine.draftCandidates[1])
            else
                engine:chooseSalvage("flotsam")
            end
        end

        -- Shop: buy cheapest affordable modifier, then depart
        if engine.phase == Engine.Phase.SHOP then
            local offer = engine:getShopOffer()
            if #offer > 0 and not engine:isAtModifierCap() then
                -- Find cheapest affordable
                local cheapest = nil
                local cheapestPrice = math.huge
                for _, modType in ipairs(offer) do
                    local price = engine:shopPrice(modType)
                    if price <= engine.chipStack and price < cheapestPrice then
                        cheapest = modType
                        cheapestPrice = price
                    end
                end
                -- Only buy if we have plenty of chips
                if cheapest and engine.chipStack > cheapestPrice * 3 then
                    engine:purchaseModifier(cheapest)
                end
            end
            engine:leaveShop()
        end
    end

    return run.outcome, run
end

function Sim.run(numRuns)
    -- Create a meta with all unlocks for balanced testing
    local meta = Meta.load()
    -- Don't use persistent meta — create a fresh one for simulation
    local meta = {
        startingChips = function() return 200 end,
        maxModifiers = function() return 3 end,
        secondWindActive = function() return false end,
        luckyStartActive = function() return false end,
        tideMarkActive = function() return false end,
        cardBackStyle = function() return "standard" end,
        feltTinted = function() return false end,
        hasUnlock = function() return false end,
        unlockedSet = function() return {} end,
        save = function() end,
        addFlotsam = function() end,
        trackRunProgress = function() end,
        artefactRollState = function()
            return { collected = {}, maxWatchReached = 1, hasWon = false, totalRuns = 0, uniqueModifiersUsed = 0 }
        end,
        artefactCount = function() return 0 end,
        addArtefact = function() end,
        clearJournalNewCount = function() end,
    }
    setmetatable(meta, { __index = Meta })

    local wins = 0
    local foundered = 0
    local totalChips = 0
    local watchReached = { 0, 0, 0, 0 }
    local handsPlayedTotal = 0

    for i = 1, numRuns do
        local outcome, run = playRun(meta)
        if outcome == "won" then
            wins = wins + 1
        else
            foundered = foundered + 1
        end
        totalChips = totalChips + run.chipStack
        watchReached[math.min(run.currentAct, 4)] = watchReached[math.min(run.currentAct, 4)] + 1
        handsPlayedTotal = handsPlayedTotal + #run.hands
    end

    print("=== Balance Simulation: " .. numRuns .. " runs ===")
    print(string.format("Win rate:       %.1f%% (%d wins, %d foundered)", wins / numRuns * 100, wins, foundered))
    print(string.format("Avg chips:      %.0f", totalChips / numRuns))
    print(string.format("Avg hands:      %.1f", handsPlayedTotal / numRuns))
    print("Watch reached:")
    for w = 1, 4 do
        print(string.format("  Watch %d: %d (%.1f%%)", w, watchReached[w], watchReached[w] / numRuns * 100))
    end
    print("Thresholds: " .. table.concat(Run.WatchThresholds, ", "))
    print("Starting chips: " .. Run.StartingChips)
end

return Sim