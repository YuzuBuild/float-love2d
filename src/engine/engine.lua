-- GameEngine: drives a single run. Pure game logic — no UI/rendering deps.
-- Ports GameEngine.swift (801 lines)

local Card = require("src.models.card")
local Deck = Card.Deck
local Modifier = require("src.models.modifiers")
local VoyageCard = require("src.models.voyage_card")
local Run = require("src.models.run")

local Engine = {}
Engine.__index = Engine

-- Phase constants
Engine.Phase = {
    BETTING = "betting",
    TIDE = "tide",             -- NEW: pre-hand risk/reward choice
    PLAYER_TURN = "playerTurn",
    DEALER_TURN = "dealerTurn",
    HAND_RESULT = "handResult",
    SALVAGE = "salvage",       -- NEW: post-hand flotsam-or-reef choice
    SHOP = "shop",
    GAME_OVER = "gameOver",
}

-- Tide choices (pre-hand)
Engine.Tide = {
    RISING = "rising",   -- +20% payout, dealer draws one extra card at end
    FALLING = "falling", -- -20% payout, player sees dealer hole card
    FLAT = "flat",       -- no modification
}

-- Salvage choices (post-hand)
Engine.Salvage = {
    FLOTSAM = "flotsam",   -- +1 Flotsam, no deck modification
    REEF = "reef",         -- seed voyage card, gain +2 chips per remaining hand this watch
}

-- Wharf event types
Engine.WharfEvent = {
    THE_PASSENGER = "thePassenger",
    UNCLAIMED_CRATE = "unclaimedCrate",
    DELAYED_DEPARTURE = "delayedDeparture",
    CONTRABAND_INSPECTION = "contrabandInspection",
    SECOND_OPINION = "secondOpinion",
}

function Engine.new(run, meta)
    local self = setmetatable({}, Engine)
    self.run = run
    self.meta = meta
    self.chipStack = run.chipStack
    self.deck = Deck.new()
    self.phase = Engine.Phase.BETTING

    -- Visible state
    self.playerHands = {{}}
    self.activeHandIndex = 1
    self.dealerCards = {}
    self.currentBets = {0}
    self.cardSharkReady = false
    self.luckyStartOffer = {}
    self.draftCandidates = {}
    self.activeWharfEvent = nil
    self.knownWatersCard = nil
    self.lastInsuranceRefund = 0
    self.activeTide = nil       -- NEW: tide choice for current hand
    self.reefBonus = 0          -- NEW: accumulated reef chips for this watch

    -- Private state
    self.nextBetFree = false
    self.frozenShopOffer = {}
    self.playerHitThisHand = false
    self.theHardWayEligible = false
    self.compoundInterestBonus = 0
    self.betHistory = {}

    -- Lucky start
    if meta:luckyStartActive() and #run.activeModifiers == 0 then
        self.luckyStartOffer = Modifier.shopOffer({})
    end

    return self
end

-------------------------------------------------------------------------------
-- Computed properties
-------------------------------------------------------------------------------

function Engine:activeHand()
    return self.playerHands[self.activeHandIndex] or {}
end

function Engine:activeBet()
    return self.currentBets[self.activeHandIndex] or 0
end

function Engine:playerValue()
    return Card.evaluate(self:activeHand())
end

function Engine:dealerValue()
    return Card.evaluate(self.dealerCards)
end

function Engine:isNatural()
    local hand = self:activeHand()
    return #hand == 2 and Card.evaluate(hand):isNatural()
end

function Engine:seededVoyageCards()
    local result = {}
    for _, c in ipairs(self.deck.cards) do
        if c.voyageEffect then
            table.insert(result, c.voyageEffect)
        end
    end
    return result
end

function Engine:effectiveMinimumBet()
    local base = Run.MinimumBet
    if self.run.runCondition == "roughWater" then base = 30 end
    return base + self.compoundInterestBonus
end

function Engine:paceDeficit()
    if not self.meta:tideMarkActive() then return nil end
    local handsIntoAct = (self.run.currentHandNumber - 1) % Run.HandsPerAct
    local handsLeft = Run.HandsPerAct - handsIntoAct
    if handsLeft <= 0 then return nil end
    local needed = Run.departureThreshold(self.run.currentAct) - self.chipStack
    if needed <= 0 then return 0 end
    return math.ceil(needed / handsLeft)
end

function Engine:canHit()
    return self.phase == Engine.Phase.PLAYER_TURN and not self:playerValue():isBust()
end

function Engine:canDouble()
    return self.phase == Engine.Phase.PLAYER_TURN
       and #self:activeHand() == 2
       and self.chipStack >= self:activeBet()
end

function Engine:canSplit()
    local hand = self:activeHand()
    return self.phase == Engine.Phase.PLAYER_TURN
       and #hand == 2
       and Card.hardValue(hand[1].rank) == Card.hardValue(hand[2].rank)
       and #self.playerHands == 1
       and self.chipStack >= self:activeBet()
end

function Engine:canUseCardShark()
    return self.phase == Engine.Phase.PLAYER_TURN
       and Run.hasModifier(self.run, "cardShark")
       and not self.run.cardSharkUsedThisAct
       and self.cardSharkReady
end

function Engine:canUseBallast()
    return self.phase == Engine.Phase.PLAYER_TURN
       and Run.hasModifier(self.run, "ballast")
       and not self.run.ballastUsedThisAct
       and self:activeBet() > self:effectiveMinimumBet()
end

function Engine:isAtModifierCap()
    return #self.run.activeModifiers >= self.meta:maxModifiers()
end

-------------------------------------------------------------------------------
-- Betting
-------------------------------------------------------------------------------

function Engine:placeBet(amount)
    if self.phase ~= Engine.Phase.BETTING then return end
    if amount < self:effectiveMinimumBet() then return end

    local deduction = self.nextBetFree and 0 or amount
    if self.chipStack < deduction then return end

    self.chipStack = self.chipStack - deduction
    self.nextBetFree = false
    self._pendingBet = amount

    -- NEW: Go to tide phase (pre-hand risk/reward choice)
    self.phase = Engine.Phase.TIDE
end

-------------------------------------------------------------------------------
-- Tide phase (NEW)
-------------------------------------------------------------------------------

-- Player chooses tide; then deal begins
function Engine:chooseTide(tide)
    if self.phase ~= Engine.Phase.TIDE then return end
    self.activeTide = tide

    -- Determine hole card visibility
    -- Clear Skies condition: always visible
    -- Falling tide: visible
    -- Watch 3 (Fog): always hidden (overrides Clear Skies and Falling)
    local holeFaceDown = self.run.runCondition ~= "clearSkies"
    if tide == Engine.Tide.FALLING then
        holeFaceDown = false
    end
    if self:watchHasTrait("fogWatch") then
        holeFaceDown = true  -- Fog watch overrides everything
    end

    self:beginDeal(self._pendingBet or 0, holeFaceDown)
    self._pendingBet = nil
end

-------------------------------------------------------------------------------
-- Deal
-------------------------------------------------------------------------------

function Engine:beginDeal(bet, holeFaceDown)
    -- Default: hole card face down unless clearSkies or explicitly face up
    if holeFaceDown == nil then
        holeFaceDown = self.run.runCondition ~= "clearSkies"
    end

    self.playerHands = {{}}
    self.currentBets = {bet}
    self.activeHandIndex = 1
    self.dealerCards = {}
    self.cardSharkReady = false
    self.playerHitThisHand = false
    self.theHardWayEligible = false
    self.lastInsuranceRefund = 0
    self._risingExtraDrawn = false  -- NEW: reset rising tide flag
    table.insert(self.betHistory, bet)

    table.insert(self.playerHands[1], self:draw())
    table.insert(self.dealerCards, self:draw())
    table.insert(self.playerHands[1], self:draw())
    table.insert(self.dealerCards, self:draw(holeFaceDown))

    if Run.hasModifier(self.run, "cardShark") and not self.run.cardSharkUsedThisAct then
        self.cardSharkReady = true
    end

    self.phase = Engine.Phase.PLAYER_TURN

    if self:isNatural() then
        self:peekAndResolve()
    end
end

-------------------------------------------------------------------------------
-- Player actions
-------------------------------------------------------------------------------

function Engine:hit()
    if not self:canHit() then return end
    self.playerHitThisHand = true
    local card = self:draw()
    table.insert(self.playerHands[self.activeHandIndex], card)

    -- Undertow: force one extra draw
    if card.voyageEffect == "undertow" then
        table.insert(self.playerHands[self.activeHandIndex], self:draw())
    end

    if self:playerValue():isBust() then
        self:handlePlayerFust()
    end
end

function Engine:stand()
    if self.phase ~= Engine.Phase.PLAYER_TURN then return end
    self:advanceHandOrDealer()
end

function Engine:doubleDown()
    if not self:canDouble() then return end

    if Run.hasModifier(self.run, "theHardWay") then
        self.theHardWayEligible = self:playerValue().soft <= 13
    end

    local extra = self:activeBet()
    if Run.hasModifier(self.run, "doubleDownDiscount") then
        extra = math.max(1, math.floor(self:activeBet() / 2))
    end

    self.chipStack = self.chipStack - extra
    self.currentBets[self.activeHandIndex] = self.currentBets[self.activeHandIndex] + extra

    local card = self:draw()
    table.insert(self.playerHands[self.activeHandIndex], card)
    if card.voyageEffect == "undertow" then
        table.insert(self.playerHands[self.activeHandIndex], self:draw())
    end

    if self:playerValue():isBust() then
        self:handlePlayerFust()
    else
        self:advanceHandOrDealer()
    end
end

function Engine:split()
    if not self:canSplit() then return end
    local bet = self:activeBet()
    self.chipStack = self.chipStack - bet

    local cardA = self:activeHand()[1]
    local cardB = self:activeHand()[2]

    self.playerHands[1] = { cardA, self:drawForSplit() }
    table.insert(self.playerHands, { cardB, self:drawForSplit() })
    self.currentBets = { bet, bet }
    self.activeHandIndex = 1
end

function Engine:revealHoleCard()
    if not self:canUseCardShark() then return end
    if self.dealerCards[2] then
        self.dealerCards[2].isFaceDown = false
    end
    self.run.cardSharkUsedThisAct = true
    self.cardSharkReady = false
end

function Engine:useBallast()
    if not self:canUseBallast() then return end
    local refund = math.floor(self:activeBet() / 2)
    self.chipStack = self.chipStack + refund
    self.currentBets[self.activeHandIndex] = self.currentBets[self.activeHandIndex] - refund
    self.run.ballastUsedThisAct = true
end

-------------------------------------------------------------------------------
-- Internal hand flow
-------------------------------------------------------------------------------

function Engine:peekAndResolve()
    if self.dealerCards[2] then
        self.dealerCards[2].isFaceDown = false
    end
    self:runDealerLogic()
    self:resolveAllHands()
end

function Engine:advanceHandOrDealer()
    if self.activeHandIndex < #self.playerHands then
        self.activeHandIndex = self.activeHandIndex + 1
    else
        self:dealerPhase()
    end
end

function Engine:handlePlayerFust()
    if Run.hasModifier(self.run, "insuranceMan") and not self.run.insuranceUsedThisAct then
        local refund = math.floor(self:activeBet() / 2)
        self.chipStack = self.chipStack + refund
        self.lastInsuranceRefund = refund
        self.run.insuranceUsedThisAct = true
    end
    self.run.consecutiveWins = 0
    self:advanceHandOrDealer()
end

function Engine:dealerPhase()
    self.phase = Engine.Phase.DEALER_TURN
    if self.dealerCards[2] and self.run.runCondition ~= "fog" then
        self.dealerCards[2].isFaceDown = false
    end
    self:runDealerLogic()
    self:resolveAllHands()
end

-------------------------------------------------------------------------------
-- Dealer logic (watch-scaled)
-------------------------------------------------------------------------------

function Engine:runDealerLogic()
    while self:shouldDealerDraw() do
        local card = self:draw()
        table.insert(self.dealerCards, card)
        if card.voyageEffect == "undertow" then
            table.insert(self.dealerCards, self:draw())
        end
    end

    -- NEW: Rising tide — dealer draws one extra card after normal logic
    if self.activeTide == Engine.Tide.RISING and not self._risingExtraDrawn then
        self._risingExtraDrawn = true
        local card = self:draw()
        table.insert(self.dealerCards, card)
        if card.voyageEffect == "undertow" then
            table.insert(self.dealerCards, self:draw())
        end
    end
end

function Engine:shouldDealerDraw()
    local v = Card.evaluate(self.dealerCards)
    if v:isBust() then return false end
    local isSoft17 = v.soft == 17 and v.hard ~= v.soft

    if self.run.runCondition == "calmCrossing" then
        return v.soft < 17
    end

    local act = self.run.currentAct
    if act == 1 then
        return v.soft < 17
    elseif act == 2 then
        return v.soft < 17 or isSoft17
    else
        return v.soft <= 17
    end
end

-------------------------------------------------------------------------------
-- NEW: Watch identity system
-- Each watch has a mechanical identity that changes how hands play.
-------------------------------------------------------------------------------

Engine.WatchIdentity = {
    [1] = { name = "Calm",       -- Standard. Dealer stands soft 17.
    },
    [2] = { name = "Tide",       -- Odd hands pay 1.5×, even hands pay 0.75×.
    },
    [3] = { name = "Fog",        -- Hole card always hidden. Reef seeds 2 cards instead of 1.
    },
    [4] = { name = "The Reaches", -- All modifier payouts ×2, all modifier costs ×2.
    },
}

function Engine:watchIdentity()
    return Engine.WatchIdentity[self.run.currentAct] or { name = "Unknown" }
end

-- Check if current watch has a specific identity trait
function Engine:watchHasTrait(trait)
    local act = self.run.currentAct
    if trait == "tideOdds" then return act == 2 end
    if trait == "fogWatch" then return act == 3 end
    if trait == "amplified" then return act == 4 end
    return false
end

function Engine:resolveAllHands()
    -- Fog Bank: reveal all fog cards
    for i, hand in ipairs(self.playerHands) do
        for j, c in ipairs(hand) do
            if c.voyageEffect == "fogBank" then c.fogRevealed = true end
        end
    end
    for _, c in ipairs(self.dealerCards) do
        if c.voyageEffect == "fogBank" then c.fogRevealed = true end
    end

    local dealerVal = Card.evaluate(self.dealerCards)
    local overallOutcome = "inProgress"
    local chipsGained = 0

    for i, hand in ipairs(self.playerHands) do
        local bet = self.currentBets[i] or 0
        local pVal = Card.evaluate(hand)
        local outcome

        if pVal:isBust() then
            outcome = "playerFust"
        elseif dealerVal:isBust() then
            outcome = "dealerFust"
        elseif pVal.soft > dealerVal.soft then
            outcome = "playerWin"
        elseif dealerVal.soft > pVal.soft then
            outcome = "dealerWin"
        else
            outcome = "push"
        end

        -- Spring Tide: pushes resolve as player wins
        if outcome == "push" and self.run.runCondition == "springTide" then
            outcome = "playerWin"
        end

        if outcome == "playerWin" or outcome == "dealerFust" then
            local payout = bet * 2

            -- Tide choice payout modifier
            if self.activeTide == Engine.Tide.RISING then
                payout = math.floor(payout * 1.2)
            elseif self.activeTide == Engine.Tide.FALLING then
                payout = math.floor(payout * 0.8)
            end

            -- NEW: Watch 2 (Tide) — odd hands 1.5×, even hands 0.75×
            if self:watchHasTrait("tideOdds") then
                if self.run.currentHandNumber % 2 ~= 0 then
                    payout = math.floor(payout * 1.5)
                else
                    payout = math.floor(payout * 0.75)
                end
            end

            if Run.hasModifier(self.run, "tide") then
                if self.run.currentHandNumber % 2 ~= 0 then
                    payout = (payout * 3) / 2
                else
                    payout = (payout * 3) / 4
                end
            end
            if Run.hasModifier(self.run, "allOrNothing") then
                payout = payout + bet
            end
            if Run.hasModifier(self.run, "highRoller") and bet >= 100 then
                payout = payout + math.max(1, math.floor(bet * 15 / 100))
            end
            if outcome == "dealerFust" then
                if Run.hasModifier(self.run, "trueCount") then
                    payout = payout + math.max(1, math.floor(bet / 10))
                end
                if Run.hasModifier(self.run, "standingOrder") then
                    payout = payout + math.floor(bet / 2)
                end
            end
            if Run.hasModifier(self.run, "deadCalm") and not pVal:isBust()
               and (pVal.soft == 18 or pVal.soft == 19) then
                payout = payout + math.floor(bet / 2)
            end
            if Run.hasModifier(self.run, "seventeen") and pVal.soft == 17 then
                payout = payout + bet
            end
            if Run.hasModifier(self.run, "theHardWay") and self.theHardWayEligible and i == 1 then
                payout = payout + math.floor(bet / 2)
            end
            if Run.hasModifier(self.run, "theLedger") and #self.betHistory > 3 then
                local recent = {}
                for j = #self.betHistory - 3, #self.betHistory - 1 do
                    table.insert(recent, self.betHistory[j])
                end
                local avg = 0
                for _, b in ipairs(recent) do avg = avg + b end
                avg = math.floor(avg / #recent)
                if bet < avg then payout = payout + math.floor(bet / 4) end
            end
            if Run.hasModifier(self.run, "patientCapital") and not self.playerHitThisHand and i == 1 then
                payout = payout + 15
            end

            -- NEW: Watch 4 (The Reaches) — modifier payouts amplified
            -- Double the bonus portion (everything above the base 2× payout)
            if self:watchHasTrait("amplified") then
                local basePayout = bet * 2
                if payout > basePayout then
                    local bonus = payout - basePayout
                    payout = basePayout + bonus * 2
                end
            end

            chipsGained = chipsGained + payout

        elseif outcome == "push" then
            chipsGained = chipsGained + bet
            if Run.hasModifier(self.run, "chipAway") then
                chipsGained = chipsGained + math.max(1, math.floor(bet / 10))
            end
            if Run.hasModifier(self.run, "pushArtist") then
                chipsGained = chipsGained + math.max(1, math.floor(bet * 40 / 100))
            end

        elseif outcome == "playerFust" then
            if Run.hasModifier(self.run, "salvage") then
                chipsGained = chipsGained + math.max(1, math.floor(bet * 15 / 100))
            end

        elseif outcome == "dealerWin" then
            if Run.hasModifier(self.run, "allOrNothing") then
                chipsGained = chipsGained - bet
            end
            if Run.hasModifier(self.run, "theFloor") then
                local totalLoss = bet
                if Run.hasModifier(self.run, "allOrNothing") then totalLoss = totalLoss + bet end
                if totalLoss > 30 then
                    chipsGained = chipsGained + (totalLoss - 30)
                end
            end
        end

        if i == 1 then overallOutcome = outcome end
    end

    self.chipStack = self.chipStack + chipsGained

    -- Post-resolution modifier tracking
    if overallOutcome == "playerWin" or overallOutcome == "dealerFust" then
        self.run.consecutiveWins = self.run.consecutiveWins + 1
        self.run.consecutivePushes = 0

        if Run.hasModifier(self.run, "momentum") then
            local bonus = math.min(self.run.consecutiveWins, 4) * 5
            self.chipStack = self.chipStack + bonus
        end
        if Run.hasModifier(self.run, "hotStreak") and self.run.consecutiveWins >= 3 then
            self.nextBetFree = true
            self.run.consecutiveWins = 0
        end
        if Run.hasModifier(self.run, "compoundInterest") then
            self.compoundInterestBonus = self.compoundInterestBonus + 5
        end

    elseif overallOutcome == "push" then
        self.run.consecutiveWins = 0
        self.run.consecutivePushes = self.run.consecutivePushes + 1
        self.compoundInterestBonus = 0
        if Run.hasModifier(self.run, "patience") and self.run.consecutivePushes >= 2 then
            local primaryBet = self.currentBets[1] or 0
            self.chipStack = self.chipStack + math.max(1, math.floor(primaryBet / 2))
            self.run.consecutivePushes = 0
        end

    else
        self.run.consecutiveWins = 0
        self.run.consecutivePushes = 0
        self.compoundInterestBonus = 0
    end

    -- Lifeline debt repayment
    if Run.hasModifier(self.run, "lifeline") and self.run.lifelineDebt > 0
       and (overallOutcome == "playerWin" or overallOutcome == "dealerFust") then
        local repay = math.min(self.run.lifelineDebt, chipsGained)
        self.chipStack = self.chipStack - repay
        self.run.lifelineDebt = self.run.lifelineDebt - repay
    end

    -- Lifeline auto-trigger
    if Run.hasModifier(self.run, "lifeline") and self.chipStack < 50 and self.chipStack > 0
       and self.run.lifelineDebt == 0 then
        self.chipStack = self.chipStack + 50
        self.run.lifelineDebt = 50
    end

    self:persistHand(overallOutcome)
    self:finalizeAfterHand(overallOutcome)
end

-------------------------------------------------------------------------------
-- Persistence (in-memory, no SwiftData)
-------------------------------------------------------------------------------

function Engine:persistHand(outcome)
    local hand = {
        act = self.run.currentAct,
        handNumber = self.run.currentHandNumber,
        bet = self.currentBets[1] or 0,
        chipsBefore = self.run.chipStack,
        chipsAfter = self.chipStack,
        outcome = outcome,
        playerCards = self.playerHands[1] or {},
        dealerCards = self.dealerCards,
    }
    table.insert(self.run.hands, hand)
    self.run.chipStack = self.chipStack
end

-------------------------------------------------------------------------------
-- Post-hand state
-------------------------------------------------------------------------------

function Engine:finalizeAfterHand(outcome)
    self.phase = Engine.Phase.HAND_RESULT
    self._pendingOutcome = outcome
end

function Engine:acknowledgeResult()
    if self.phase ~= Engine.Phase.HAND_RESULT then return end

    if self.chipStack < Run.MinimumBet then
        self:endRun("foundered")
        return
    end

    -- NEW: Go to salvage phase (flotsam or reef)
    self.draftCandidates = VoyageCard.draftOffer()
    self.phase = Engine.Phase.SALVAGE
end

-- NEW: Salvage phase — player chooses flotsam or reef
function Engine:chooseSalvage(choice, voyageType)
    if self.phase ~= Engine.Phase.SALVAGE then return end

    if choice == Engine.Salvage.FLOTSAM then
        -- +1 Flotsam, no deck modification
        self.run._salvageFlotsam = (self.run._salvageFlotsam or 0) + 1

        -- NEW: Roll for artefact
        local Artefacts = require("src.models.artefacts")
        local state = self.meta:artefactRollState()
        local artefact = Artefacts.roll(state)
        if artefact then
            self.meta:addArtefact(artefact.id)
            self.lastArtefactFound = artefact  -- UI can display this
        else
            self.lastArtefactFound = nil
        end
    elseif choice == Engine.Salvage.REEF and voyageType then
        -- Seed voyage card(s), gain +2 chips per remaining hand this watch
        local card = Card.newVoyage(voyageType)
        self.deck:insertVoyageCard(card)
        self.run.voyageCardsSeeded = self.run.voyageCardsSeeded + 1

        -- NEW: Watch 3 (Fog) — reef seeds an extra card
        if self:watchHasTrait("fogWatch") then
            local card2 = Card.newVoyage(voyageType)
            self.deck:insertVoyageCard(card2)
            self.run.voyageCardsSeeded = self.run.voyageCardsSeeded + 1
        end

        local handsLeft = Run.HandsPerAct - Run.currentActHandNumber(self.run)
        local bonus = math.max(0, handsLeft) * 2
        self.chipStack = self.chipStack + bonus
        self.run.chipStack = self.chipStack
        self.lastArtefactFound = nil
    end

    self.draftCandidates = {}
    self:advanceAfterSalvage()
end

function Engine:effectiveActCount()
    if self.run.runCondition == "shortPassage" then return 2 end
    return Run.ActCount
end

function Engine:effectiveWinThreshold()
    if self.run.runCondition == "shortPassage" then return 350 end
    return Run.winThreshold()
end

function Engine:advanceAfterSalvage()
    if self.run.currentHandNumber % Run.HandsPerAct == 0 then
        if self.run.currentAct < self:effectiveActCount() then
            self.run.currentAct = self.run.currentAct + 1
            self:resetActFlags()
            self:freezeShopOffer()
            self.phase = Engine.Phase.SHOP
            return
        else
            if self.chipStack >= self:effectiveWinThreshold() then
                self:endRun("won")
            else
                self:endRun("foundered")
            end
            return
        end
    end

    self.run.currentHandNumber = self.run.currentHandNumber + 1
    self:resetForBetting()
end

-------------------------------------------------------------------------------
-- Shop
-------------------------------------------------------------------------------

Engine.shopOffer = Engine.frozenShopOffer  -- alias not great; use method

function Engine:getShopOffer()
    return self.frozenShopOffer
end

function Engine:freezeShopOffer()
    local pool = Modifier.shopOffer(Run.activeModifierTypes(self.run))

    if self.meta:secondWindActive() and not self.run:hasModifier("lifeline") then
        -- Ensure lifeline is in the offer
        local hasLifeline = false
        for _, t in ipairs(pool) do if t == "lifeline" then hasLifeline = true; break end end
        if not hasLifeline then
            table.remove(pool)  -- remove last
            table.insert(pool, "lifeline")
        end
    end

    self.frozenShopOffer = pool
    self:rollWharfEvent()
end

function Engine:rollWharfEvent()
    self.activeWharfEvent = nil
    if math.random() >= 0.20 then return end

    local candidates = {
        { type = Engine.WharfEvent.THE_PASSENGER },
        { type = Engine.WharfEvent.SECOND_OPINION },
        { type = Engine.WharfEvent.DELAYED_DEPARTURE },
    }

    local crateExcluded = Run.activeModifierTypes(self.run)
    for _, t in ipairs(self.frozenShopOffer) do
        table.insert(crateExcluded, t)
    end
    local freebie = Modifier.shopOffer(crateExcluded)[1]
    if freebie then
        table.insert(candidates, { type = Engine.WharfEvent.UNCLAIMED_CRATE, modifier = freebie })
    end

    local removable = {}
    for _, t in ipairs(Run.activeModifierTypes(self.run)) do
        if not Modifier.EventOnlyTypes[t] then
            table.insert(removable, t)
        end
    end
    if #removable > 0 then
        local victim = removable[math.random(#removable)]
        table.insert(candidates, { type = Engine.WharfEvent.CONTRABAND_INSPECTION, modifier = victim })
    end

    local event = candidates[math.random(#candidates)]

    if event.type == Engine.WharfEvent.DELAYED_DEPARTURE then
        self.chipStack = self.chipStack + 50
        self.run.chipStack = self.chipStack
        self.frozenShopOffer = {}
    elseif event.type == Engine.WharfEvent.CONTRABAND_INSPECTION then
        self.chipStack = self.chipStack + 75
        self.run.chipStack = self.chipStack
        self:discardModifier(event.modifier)
    end

    self.activeWharfEvent = event
end

function Engine:shopPrice(modType)
    local base = Modifier.BaseCost[modType] or 0
    if self.run.runCondition == "theLedgerIsOpen" then
        base = math.max(0, base - 15)
    end

    -- NEW: Watch 4 (The Reaches) — modifier costs doubled
    if self:watchHasTrait("amplified") then
        base = base * 2
    end

    -- Check if player can afford any offer
    local canAffordAny = false
    for _, t in ipairs(self.frozenShopOffer) do
        local b = Modifier.BaseCost[t] or 0
        if self.run.runCondition == "theLedgerIsOpen" then
            b = math.max(0, b - 15)
        end
        if self:watchHasTrait("amplified") then b = b * 2 end
        if self.chipStack >= b then canAffordAny = true; break end
    end

    if not canAffordAny then return Modifier.DiscountPrice end
    return base
end

function Engine:purchaseModifier(modType)
    if self.phase ~= Engine.Phase.SHOP then return end
    local cost = self:shopPrice(modType)
    if self.chipStack < cost then return end
    if #self.run.activeModifiers >= self.meta:maxModifiers() then return end

    self.chipStack = self.chipStack - cost
    self.run.chipStack = self.chipStack

    table.insert(self.run.activeModifiers, {
        type = modType,
        purchaseAct = self.run.currentAct,
        chipCost = cost,
    })

    -- Track first-use
    local alreadyUsed = false
    for _, t in ipairs(self.run.newModifiersUsed) do
        if t == modType then alreadyUsed = true; break end
    end
    if not alreadyUsed then
        table.insert(self.run.newModifiersUsed, modType)
    end
end

function Engine:discardModifier(modType)
    local newMods = {}
    for _, m in ipairs(self.run.activeModifiers) do
        if m.type ~= modType then
            table.insert(newMods, m)
        end
    end
    self.run.activeModifiers = newMods
end

function Engine:takeLoan()
    if self.phase ~= Engine.Phase.SHOP or self.run.loanUsedThisAct then return end
    self.run.loanUsedThisAct = true
    self.run.totalLoansThisRun = self.run.totalLoansThisRun + 1
    self.meta.totalLoansEver = self.meta.totalLoansEver + 1
    self.chipStack = self.chipStack + Run.LoanAmount
    self.run.chipStack = self.chipStack
end

function Engine:leaveShop()
    if self.phase ~= Engine.Phase.SHOP then return end
    local completedAct = self.run.currentAct - 1
    if completedAct > 0 and self.chipStack < Run.departureThreshold(completedAct) then
        self:endRun("foundered")
        return
    end
    self.run.currentHandNumber = self.run.currentHandNumber + 1
    self:resetForBetting()
end

-------------------------------------------------------------------------------
-- Wharf event actions
-------------------------------------------------------------------------------

function Engine:acceptPassenger()
    if self.activeWharfEvent and self.activeWharfEvent.type == Engine.WharfEvent.THE_PASSENGER
       and self.phase == Engine.Phase.SHOP then
        self.chipStack = self.chipStack + 60
        self.run.chipStack = self.chipStack
        if not self:isAtModifierCap() then
            table.insert(self.run.activeModifiers, {
                type = "passenger",
                purchaseAct = self.run.currentAct,
                chipCost = 0,
            })
        end
        self.activeWharfEvent = nil
    end
end

function Engine:declineWharfEvent()
    self.activeWharfEvent = nil
end

function Engine:takeUnclaimedCrate()
    if self.activeWharfEvent and self.activeWharfEvent.type == Engine.WharfEvent.UNCLAIMED_CRATE
       and self.phase == Engine.Phase.SHOP then
        if not self:isAtModifierCap() then
            table.insert(self.run.activeModifiers, {
                type = self.activeWharfEvent.modifier,
                purchaseAct = self.run.currentAct,
                chipCost = 0,
            })
            local modType = self.activeWharfEvent.modifier
            local alreadyUsed = false
            for _, t in ipairs(self.run.newModifiersUsed) do
                if t == modType then alreadyUsed = true; break end
            end
            if not alreadyUsed then
                table.insert(self.run.newModifiersUsed, modType)
            end
        end
        self.activeWharfEvent = nil
    end
end

function Engine:acceptSecondOpinion(replaceIndex)
    if self.activeWharfEvent and self.activeWharfEvent.type == Engine.WharfEvent.SECOND_OPINION then
        if replaceIndex >= 1 and replaceIndex <= #self.frozenShopOffer then
            local excluded = Run.activeModifierTypes(self.run)
            for _, t in ipairs(self.frozenShopOffer) do
                table.insert(excluded, t)
            end
            local replacement = Modifier.shopOffer(excluded)[1]
            if replacement then
                self.frozenShopOffer[replaceIndex] = replacement
            end
        end
        self.activeWharfEvent = nil
    end
end

-------------------------------------------------------------------------------
-- Lucky Start
-------------------------------------------------------------------------------

function Engine:acceptLuckyStartOffer(modType)
    if #self.luckyStartOffer == 0 then return end
    table.insert(self.run.activeModifiers, {
        type = modType,
        purchaseAct = 0,
        chipCost = 0,
    })
    self.luckyStartOffer = {}
end

function Engine:skipLuckyStart()
    self.luckyStartOffer = {}
end

-------------------------------------------------------------------------------
-- End run
-------------------------------------------------------------------------------

function Engine:endRun(outcome)
    self.run.outcome = outcome
    self.run.endDate = os.time()
    self.run.chipStack = self.chipStack
    self.meta:addFlotsam(self.run)
    self.meta:trackRunProgress(self.run)  -- NEW: track for narrative triggers
    self.meta:save()
    self.phase = Engine.Phase.GAME_OVER
    self._pendingOutcome = outcome
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

function Engine:draw(faceDown)
    if #self.deck.cards < Deck.reshuffleThreshold then
        self.deck = Deck.new()
    end
    local card = self.deck:deal()
    if not card then
        card = Card.new("spades", 14)  -- fallback ace
    end
    card.isFaceDown = faceDown or false
    return card
end

function Engine:drawForSplit()
    if Run.hasModifier(self.run, "luckySplit") then
        local card = self.deck:dealFaceCard()
        if card then
            card.isFaceDown = false
            return card
        end
    end
    return self:draw()
end

function Engine:resetActFlags()
    self.run.cardSharkUsedThisAct = false
    self.run.insuranceUsedThisAct = false
    self.run.loanUsedThisAct = false
    self.run.ballastUsedThisAct = false
    self.compoundInterestBonus = 0
    self.betHistory = {}
    if Run.hasModifier(self.run, "floodTide") and self.run.currentAct > 1 then
        self.chipStack = self.chipStack + 20
        self.run.chipStack = self.chipStack
    end
end

function Engine:resetForBetting()
    self.playerHands = {{}}
    self.currentBets = {0}
    self.activeHandIndex = 1
    self.dealerCards = {}
    self.cardSharkReady = false
    self.activeTide = nil         -- NEW: reset tide
    self._risingExtraDrawn = false -- NEW: reset rising flag

    if self.run.runCondition == "knownWaters" then
        if #self.deck.cards < Deck.reshuffleThreshold then
            self.deck = Deck.new()
        end
        self.knownWatersCard = self.deck:topCard()
    else
        self.knownWatersCard = nil
    end

    self.phase = Engine.Phase.BETTING
end

return Engine