-- Meta-progression: Flotsam, unlock tree, run stats
-- Ports MetaProgress.swift — uses JSON file instead of SwiftData

local json = require("src.lib.json")

local Meta = {}

-- Unlock nodes
Meta.UnlockNodes = {
    "startingChipsBonus", "secondWind", "cosmeticPack1", "cosmeticPack2",
    "modifierSlotPlus1", "luckyStart", "tideMark",
    "narrativeMaren", "narrativeCully", "narrativeSable",
}

Meta.UnlockDisplayName = {
    startingChipsBonus = "Starting Chips +25",
    secondWind = "Second Wind",
    cosmeticPack1 = "Cosmetic Pack I",
    cosmeticPack2 = "Cosmetic Pack II",
    modifierSlotPlus1 = "Modifier Slot +",
    luckyStart = "Lucky Start",
    tideMark = "Tide Mark",
    narrativeMaren = "Maren",
    narrativeCully = "Cully",
    narrativeSable = "Sable",
}

Meta.UnlockDescription = {
    startingChipsBonus = "Begin every run with 225 chips.",
    secondWind = "The Lifeline modifier is always available in the shop.",
    cosmeticPack1 = "Unlocks an alternate card back.",
    cosmeticPack2 = "Unlocks table felt colour options.",
    modifierSlotPlus1 = "Hold up to 4 active modifiers instead of 3.",
    luckyStart = "One free modifier is offered at the start of each run.",
    tideMark = "Shows a waterline during your run — whether your stack is on pace for port.",
    narrativeMaren = "A ship's accountant with a lot of opinions about your play.",
    narrativeCully = "A regular at the wharf. Enthusiastic. Rarely helpful.",
    narrativeSable = "The old rigger. Has seen more voyages than anyone admits.",
}

Meta.UnlockCost = {
    narrativeMaren = 3, narrativeCully = 3, narrativeSable = 3,
    cosmeticPack1 = 6, startingChipsBonus = 8, tideMark = 8,
    cosmeticPack2 = 10, secondWind = 12, luckyStart = 14, modifierSlotPlus1 = 18,
}

Meta.UnlockPrerequisites = {
    secondWind = { "startingChipsBonus" },
    cosmeticPack2 = { "cosmeticPack1" },
    tideMark = { "cosmeticPack2" },
    luckyStart = { "modifierSlotPlus1" },
}

local SAVE_FILE = "float_meta.json"

-- Load from disk or create new
function Meta.load()
    local data = nil
    local file = io.open(SAVE_FILE, "r")
    if file then
        local content = file:read("*a")
        file:close()
        if content and #content > 0 then
            data = json.decode(content)
        end
    end

    if not data then
        data = {
            totalFlotsamEarned = 0,
            availableFlotsam = 0,
            unlockedNodes = {},
            personalChipRecord = 0,
            totalRuns = 0,
            totalWins = 0,
            totalLoansEver = 0,
            dialogueProgress = {},
            -- NEW: narrative tracking
            collectedArtefacts = {},   -- array of artefact IDs
            maxWatchReached = 1,        -- highest watch reached across all runs
            hasWon = false,             -- has the player ever won
            uniqueModifiersUsed = {},   -- array of modifier types ever used
            journalNewCount = 0,        -- unread new artefacts count
        }
    end

    -- Ensure unlockedNodes is a set-like table
    if not data.unlockedNodes then data.unlockedNodes = {} end
    if not data.dialogueProgress then data.dialogueProgress = {} end
    -- NEW: ensure narrative fields exist
    if not data.collectedArtefacts then data.collectedArtefacts = {} end
    if not data.maxWatchReached then data.maxWatchReached = 1 end
    if not data.hasWon then data.hasWon = false end
    if not data.uniqueModifiersUsed then data.uniqueModifiersUsed = {} end
    if not data.journalNewCount then data.journalNewCount = 0 end

    setmetatable(data, { __index = Meta })
    return data
end

function Meta:save()
    local file = io.open(SAVE_FILE, "w")
    if file then
        file:write(json.encode(self))
        file:close()
    end
end

function Meta:unlockedSet()
    local set = {}
    for _, node in ipairs(self.unlockedNodes) do
        set[node] = true
    end
    return set
end

function Meta:hasUnlock(node)
    return self:unlockedSet()[node] == true
end

function Meta:canUnlock(node)
    if self:hasUnlock(node) then return false end
    if self.availableFlotsam < (Meta.UnlockCost[node] or 0) then return false end
    local prereqs = Meta.UnlockPrerequisites[node]
    if prereqs then
        for _, prereq in ipairs(prereqs) do
            if not self:hasUnlock(prereq) then return false end
        end
    end
    return true
end

function Meta:unlock(node)
    if not self:canUnlock(node) then return false end
    self.availableFlotsam = self.availableFlotsam - (Meta.UnlockCost[node] or 0)
    table.insert(self.unlockedNodes, node)
    self:save()
    return true
end

function Meta:addFlotsam(run)
    local actsCompleted = run.currentAct - 1
    if run.outcome == "won" then actsCompleted = actsCompleted + 1 end

    local earned = actsCompleted
    if run.outcome == "won" then earned = earned + 5 end
    if Run_peek(run) > self.personalChipRecord then earned = earned + 2 end
    if #run.newModifiersUsed > 0 then earned = earned + 1 end
    -- NEW: salvage flotsam earned during run
    if run._salvageFlotsam then earned = earned + run._salvageFlotsam end

    run.flotsamEarned = earned
    self.totalFlotsamEarned = self.totalFlotsamEarned + earned
    self.availableFlotsam = self.availableFlotsam + earned

    if Run_peek(run) > self.personalChipRecord then
        self.personalChipRecord = Run_peek(run)
    end
    self.totalRuns = self.totalRuns + 1
    if run.outcome == "won" then self.totalWins = self.totalWins + 1 end

    self:save()
end

-- Helper: peak chips from a run
function Run_peek(run)
    local peak = run.chipStack
    for _, h in ipairs(run.hands) do
        if h.chipsAfter > peak then peak = h.chipsAfter end
    end
    return peak
end

-- Applied bonuses
function Meta:startingChips()
    return self:hasUnlock("startingChipsBonus") and 225 or 200
end

function Meta:maxModifiers()
    return self:hasUnlock("modifierSlotPlus1") and 4 or 3
end

function Meta:secondWindActive()
    return self:hasUnlock("secondWind")
end

function Meta:luckyStartActive()
    return self:hasUnlock("luckyStart")
end

function Meta:cardBackStyle()
    return self:hasUnlock("cosmeticPack1") and "alternate" or "standard"
end

function Meta:feltTinted()
    return self:hasUnlock("cosmeticPack2")
end

function Meta:tideMarkActive()
    return self:hasUnlock("tideMark")
end

-- Dialogue progress
function Meta:dialogueIndex(characterKey)
    return self.dialogueProgress[characterKey] or 0
end

function Meta:advanceDialogue(characters)
    for _, c in ipairs(characters) do
        self.dialogueProgress[c] = (self.dialogueProgress[c] or 0) + 1
    end
    self:save()
end

-------------------------------------------------------------------------------
-- NEW: Artefact / narrative tracking
-------------------------------------------------------------------------------

function Meta:collectedArtefactSet()
    local set = {}
    for _, id in ipairs(self.collectedArtefacts) do set[id] = true end
    return set
end

function Meta:hasArtefact(id)
    return self:collectedArtefactSet()[id] == true
end

function Meta:addArtefact(id)
    if self:hasArtefact(id) then return false end
    table.insert(self.collectedArtefacts, id)
    self.journalNewCount = self.journalNewCount + 1
    self:save()
    return true
end

function Meta:artefactCount()
    return #self.collectedArtefacts
end

function Meta:clearJournalNewCount()
    self.journalNewCount = 0
    self:save()
end

function Meta:trackRunProgress(run)
    -- Track max watch reached
    if run.currentAct > self.maxWatchReached then
        self.maxWatchReached = run.currentAct
    end
    -- Track if won
    if run.outcome == "won" then
        self.hasWon = true
    end
    -- Track unique modifiers used
    for _, modType in ipairs(run.newModifiersUsed) do
        local found = false
        for _, existing in ipairs(self.uniqueModifiersUsed) do
            if existing == modType then found = true; break end
        end
        if not found then
            table.insert(self.uniqueModifiersUsed, modType)
        end
    end
    self:save()
end

-- Build state for artefact roll
function Meta:artefactRollState()
    return {
        collected = self:collectedArtefactSet(),
        maxWatchReached = self.maxWatchReached,
        hasWon = self.hasWon,
        totalRuns = self.totalRuns,
        uniqueModifiersUsed = #self.uniqueModifiersUsed,
    }
end

return Meta