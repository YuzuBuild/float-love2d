-- Run conditions, outcome, accent colors, and Run state
-- Ports Run.swift

local Run = {}

-- Run conditions (one per voyage, shown at departure)
Run.Condition = {
    "calmCrossing", "roughWater", "fog", "clearSkies",
    "springTide", "theLedgerIsOpen", "shortPassage", "knownWaters",
}

Run.ConditionDisplayName = {
    calmCrossing = "Calm Crossing",
    roughWater = "Rough Water",
    fog = "Fog",
    clearSkies = "Clear Skies",
    springTide = "Spring Tide",
    theLedgerIsOpen = "The Ledger is Open",
    shortPassage = "Short Passage",
    knownWaters = "Known Waters",
}

Run.ConditionHiggsLine = {
    calmCrossing = "Conditions look favourable. For now.",
    roughWater = "Choppy out there. You'll want to commit.",
    fog = "Visibility is poor past the first marker.",
    clearSkies = "Good light today.",
    springTide = "Tide's running with you.",
    theLedgerIsOpen = "I've been authorised to offer terms.",
    shortPassage = "Weather window is narrow. You'll want to move.",
    knownWaters = "I've run this crossing before. I made notes.",
}

Run.ConditionEffectSummary = {
    calmCrossing = "Dealer stands on soft 17 — all watches.",
    roughWater = "Minimum bet is 30 this voyage.",
    fog = "Dealer's hole card stays hidden until their turn.",
    clearSkies = "Dealer's hole card is always face up.",
    springTide = "Pushes pay out in your favour.",
    theLedgerIsOpen = "All modifier costs reduced by 15.",
    shortPassage = "Two watches. Win condition: 400 chips.",
    knownWaters = "You see the top deck card before each bet.",
}

Run.Outcome = { inProgress = "inProgress", won = "won", foundered = "fust" }

Run.AccentColors = { "dustyGreen", "slateBlue", "warmOchre" }

function Run.randomAccent()
    return Run.AccentColors[math.random(#Run.AccentColors)]
end

-- Constants — refined loop: 20 hands, 4 watches of 5
Run.StartingChips = 200
Run.MinimumBet = 10
Run.HandsPerAct = 5
Run.ActCount = 4
Run.MaxModifiers = 3
Run.LoanAmount = 75
Run.WatchThresholds = { 150, 350, 650, 1000 }

function Run.departureThreshold(act)
    local idx = math.max(1, math.min(act, #Run.WatchThresholds))
    return Run.WatchThresholds[idx]
end

function Run.winThreshold()
    return Run.WatchThresholds[#Run.WatchThresholds]
end

-- Create a new run state
function Run.new(opts)
    opts = opts or {}
    return {
        id = tostring({}):gsub("table: ", ""),
        startDate = os.time(),
        endDate = nil,
        chipStack = opts.startingChips or Run.StartingChips,
        currentAct = 1,
        currentHandNumber = 1,
        outcome = Run.Outcome.inProgress,
        accentColor = opts.accentColor or Run.randomAccent(),
        hands = {},
        activeModifiers = {},
        -- State flags
        consecutiveWins = 0,
        consecutivePushes = 0,
        lifelineDebt = 0,
        cardSharkUsedThisAct = false,
        insuranceUsedThisAct = false,
        loanUsedThisAct = false,
        ballastUsedThisAct = false,
        flotsamEarned = 0,
        newModifiersUsed = {},
        voyageCardsSeeded = 0,
        totalLoansThisRun = 0,
        runCondition = nil,  -- key from Run.Condition
    }
end

-- Computed helpers
function Run.currentActHandNumber(run)
    return ((run.currentHandNumber - 1) % Run.HandsPerAct) + 1
end

function Run.isInShop(run)
    return run.currentHandNumber > 0
       and run.currentHandNumber % Run.HandsPerAct == 0
       and run.outcome == Run.Outcome.inProgress
end

function Run.peakChips(run)
    local peak = run.chipStack
    for _, h in ipairs(run.hands) do
        if h.chipsAfter > peak then peak = h.chipsAfter end
    end
    return peak
end

function Run.hasModifier(run, modType)
    for _, m in ipairs(run.activeModifiers) do
        if m.type == modType then return true end
    end
    return false
end

function Run.activeModifierTypes(run)
    local types = {}
    for _, m in ipairs(run.activeModifiers) do
        table.insert(types, m.type)
    end
    return types
end

return Run