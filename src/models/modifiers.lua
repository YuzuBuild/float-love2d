-- Modifier types: 25 purchasable + 1 event-only (passenger)
-- Ports Modifier.swift

local Modifier = {}

Modifier.Types = {
    -- Starter pool
    "hotStreak", "insuranceMan", "luckySplit", "chipAway",
    "doubleDownDiscount", "lifeline", "cardShark",
    -- Decision modifiers
    "seventeen", "standingOrder", "theHardWay", "pushArtist",
    "patientCapital", "theFloor", "allOrNothing",
    -- Betting modifiers
    "compoundInterest", "tide", "theLedger",
    -- Extended outcome pool
    "salvage", "highRoller", "trueCount", "floodTide",
    "momentum", "deadCalm", "patience", "ballast",
    -- Event-granted — never purchasable
    "passenger",
}

Modifier.DisplayName = {
    hotStreak = "Hot Streak",
    insuranceMan = "Insurance Man",
    luckySplit = "Lucky Split",
    chipAway = "Chip Away",
    doubleDownDiscount = "Double Down Discount",
    lifeline = "Lifeline",
    cardShark = "Card Shark",
    seventeen = "Seventeen",
    standingOrder = "Standing Order",
    theHardWay = "The Hard Way",
    pushArtist = "Push Artist",
    patientCapital = "Patient Capital",
    theFloor = "The Floor",
    allOrNothing = "All or Nothing",
    compoundInterest = "Compound Interest",
    tide = "Tide",
    theLedger = "The Ledger",
    salvage = "Salvage",
    highRoller = "High Roller",
    trueCount = "True Count",
    floodTide = "Flood Tide",
    momentum = "Momentum",
    deadCalm = "Dead Calm",
    patience = "Patience",
    ballast = "Ballast",
    passenger = "The Passenger",
}

Modifier.Description = {
    hotStreak = "Win 3 hands in a row — your next bet is free.",
    insuranceMan = "First time you fust per watch, get half your bet back.",
    luckySplit = "Splits always receive a face card.",
    chipAway = "Pushes pay out 10% of your bet.",
    doubleDownDiscount = "Double downs cost 50% instead of 100%.",
    lifeline = "If below 50 chips, automatically borrows 50. Debt repaid from your next win. Forgiven if the run ends.",
    cardShark = "See the dealer's hole card once per act.",
    seventeen = "Hands that end on exactly 17 pay double.",
    standingOrder = "When the dealer fusts, your payout is 1.5×.",
    theHardWay = "Doubling down on 13 or lower pays a bonus equal to your original stake.",
    pushArtist = "Pushes return 40% of your bet.",
    patientCapital = "Each hand you stand without hitting first earns +15 chips.",
    theFloor = "You can never lose more than 30 chips on a single hand.",
    allOrNothing = "Wins pay 2×. Losses cost 2×.",
    compoundInterest = "Each consecutive winning hand increases the minimum bet by 5.",
    tide = "Odd-numbered hands pay 1.5×. Even-numbered hands pay 0.75×.",
    theLedger = "Bets below your 3-hand average pay 1.25×.",
    salvage = "Fusting always refunds 15% of your bet.",
    highRoller = "Win a hand with a bet of 100 or more to earn a 15% bonus.",
    trueCount = "When the dealer fusts, earn an extra 10% of your bet.",
    floodTide = "Gain 20 bonus chips at the start of acts 2 and 3.",
    momentum = "Each win in a streak earns +5 bonus chips, up to +20.",
    deadCalm = "Stand on 18 or 19 and win — payout is 1.5× instead of 1×.",
    patience = "Two pushes in a row pay out 50% of your bet.",
    ballast = "Once per act, halve your active bet after cards are dealt.",
    passenger = "Takes up a modifier slot. Asks for nothing. Gives nothing.",
}

Modifier.BaseCost = {
    hotStreak = 75, insuranceMan = 50, luckySplit = 100, chipAway = 50,
    doubleDownDiscount = 75, lifeline = 75, cardShark = 100,
    seventeen = 75, standingOrder = 75, theHardWay = 100, pushArtist = 75,
    patientCapital = 50, theFloor = 100, allOrNothing = 75,
    compoundInterest = 75, tide = 75, theLedger = 50,
    salvage = 50, highRoller = 75, trueCount = 75, floodTide = 50,
    momentum = 75, deadCalm = 100, patience = 50, ballast = 75,
    passenger = 0,
}

Modifier.Icon = {
    hotStreak = "🔥", insuranceMan = "🛡", luckySplit = "✦", chipAway = "◈",
    doubleDownDiscount = "2×", lifeline = "⌛", cardShark = "👁",
    salvage = "⚓", highRoller = "↑", trueCount = "✕", floodTide = "~",
    momentum = "▲", deadCalm = "◇", patience = "=", ballast = "▽",
    passenger = "👤", seventeen = "17", standingOrder = "◻",
    theHardWay = "✶", pushArtist = "≈", patientCapital = "○",
    theFloor = "▬", allOrNothing = "!", compoundInterest = "∑",
    tide = "〜", theLedger = "≤",
}

Modifier.EventOnlyTypes = { passenger = true }
Modifier.DiscountPrice = 25

-- Shop offer: 3 random types excluding active + event-only
function Modifier.shopOffer(excluding)
    excluding = excluding or {}
    local exclSet = {}
    for _, t in ipairs(excluding) do exclSet[t] = true end

    local pool = {}
    for _, t in ipairs(Modifier.Types) do
        if not exclSet[t] and not Modifier.EventOnlyTypes[t] then
            table.insert(pool, t)
        end
    end

    -- Shuffle pool
    for i = #pool, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    return { pool[1], pool[2], pool[3] }
end

return Modifier