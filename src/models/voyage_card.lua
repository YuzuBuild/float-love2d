-- Voyage card types: deadweight, undertow, squall, fog bank
-- Ports VoyageCard.swift

local VoyageCard = {}

VoyageCard.Types = { "deadweight", "undertow", "squall", "fogBank" }

VoyageCard.DisplayName = {
    deadweight = "Deadweight",
    undertow = "Undertow",
    squall = "Squall",
    fogBank = "Fog Bank",
}

VoyageCard.Description = {
    deadweight = "Counts as 13. No reduction. Whoever draws it carries the weight.",
    undertow = "Counts as 0. Whoever draws it must take one more card.",
    squall = "Counts as 3. All aces in the hand become 1 — no soft totals.",
    fogBank = "Value hidden until the hand resolves. Could be 4. Could be 9.",
}

VoyageCard.Icon = {
    deadweight = "⚓",
    undertow = "↓",
    squall = "〜",
    fogBank = "?",
}

-- Returns 3 distinct types for draft candidates
function VoyageCard.draftOffer()
    local pool = {}
    for _, t in ipairs(VoyageCard.Types) do
        table.insert(pool, t)
    end
    -- Shuffle and take 3
    for i = #pool, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    return { pool[1], pool[2], pool[3] }
end

return VoyageCard