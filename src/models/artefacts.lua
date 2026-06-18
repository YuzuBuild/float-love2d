-- Artefacts: lore collectibles found through flotsam
-- Each is a fragment of the Reaches mystery. Progression-gated.
-- The player assembles the truth from pieces — never fully confirmed.

local Artefacts = {}

-- Unlock conditions:
-- "any"       — can be found from run 1
-- "watch3"    — first time you reach watch 3
-- "watch4"    — first time you reach watch 4
-- "won"       — after your first win
-- "runs5"     — after 5 total runs
-- "runs10"    — after 10 total runs
-- "runs20"    — after 20 total runs
-- "artefact:X" — after finding artefact X (chain unlocks)
-- "modifier"  — after using 5+ different modifiers across runs

Artefacts.List = {
    -- Early finds (any run)
    {
        id = "bright_fabric",
        title = "Scrap of Bright Fabric",
        condition = "any",
        text = "A scrap of bright fabric. The weave is tight, the colour is wrong for this latitude. Nobody sells this at the wharf. Nobody asks where you got it.",
    },
    {
        id = "seed_pod",
        title = "Seed Pod",
        condition = "any",
        text = "A seed pod. Warm to the touch. Shouldn't have survived the crossing. The wood grain inside spirals the wrong direction.",
    },
    {
        id = "glass_bead",
        title = "Glass Bead",
        condition = "any",
        text = "A glass bead with something moving inside it. Not liquid. Not an insect. You stopped looking.",
    },
    {
        id = "charter_page",
        title = "Page from a Charter",
        condition = "any",
        text = "A page from a charter. The appendix reference is circled. The ink is fresh. The appendix is missing from all known copies.",
    },
    {
        id = "warm_stone",
        title = "Warm Stone",
        condition = "any",
        text = "A stone that stays warm. Not hot — warm, like something recently let go of it. It doesn't cool. You've tried.",
    },
    {
        id = "salt_shell",
        title = "Salt Shell",
        condition = "any",
        text = "A shell that tastes of salt, but the salt is wrong. The minerals don't match the local water. You'd need to be somewhere else to find water like this.",
    },

    -- Mid finds (watch 3+)
    {
        id = "ship_log_fragment",
        title = "Ship's Log Fragment",
        condition = "watch3",
        text = "A page torn from a ship's log. The entries are routine through watch three. Watch four has one entry: coordinates. No heading. No crew names. The coordinates don't appear on any chart you've seen.",
    },
    {
        id = "tide_chart",
        title = "Tide Chart",
        condition = "watch3",
        text = "A tide chart for waters that aren't the wharf. The tides don't match the local moon cycle. The chart is accurate for somewhere. The somewhere isn't here.",
    },
    {
        id = "coat_button",
        title = "Coat Button",
        condition = "watch3",
        text = "A button from a coat. The same coat Higgs wears. The same coat someone left at the wharf last week. The same coat. You're sure of it now.",
    },
    {
        id = "endorsement_form",
        title = "Endorsement Form",
        condition = "watch3",
        text = "A blank Residency Endorsement form. The fields are: name, vessel, crossings completed, crossings required. The last field is empty. There's a note in the margin: 'See appendix.' The appendix reference is the same one circled on the charter page.",
    },

    -- Deep finds (watch 4+)
    {
        id = "mayors_income_file",
        title = "The Mayor's Income File",
        condition = "watch4",
        text = "A file labelled 'Mayor's Income.' The final entry has a notation you don't recognise. The notation appears on three other files in the cabinet. None of those ships came back from the Reaches.",
    },
    {
        id = "harbour_authority_seal",
        title = "Harbour Authority Seal",
        condition = "watch4",
        text = "A stamp from the harbour authority. The harbour authority dissolved in the reorganisation. The seal is still warm, like it was used recently. Higgs has ink on his fingers.",
    },
    {
        id = "second_ledger_page",
        title = "Second Ledger Page",
        condition = "watch4",
        text = "A page from a second ledger. Ships departed against ships returned. The shortfall is larger than the official records account for. The handwriting is precise. It's not Higgs's.",
    },
    {
        id = "spare_rigging",
        title = "Spare Rigging",
        condition = "watch4",
        text = "A length of rigging. The knotwork is old — older than the wharf, older than the planks. The rope is warm. Sable would know what it is. Sable has seen it before.",
    },
    {
        id = "driftwood_map",
        title = "Driftwood Map",
        condition = "watch4",
        text = "A piece of driftwood with scratches that might be a map. The coastline doesn't match any chart. The coordinates are close to the ones in the ship's log fragment. Close. Not the same.",
    },

    -- Late finds (after first win)
    {
        id = "reaches_flower",
        title = "Reaches Flower",
        condition = "won",
        text = "A flower. Tropical. It shouldn't have survived the crossing. It's still warm. Nobody who comes back has a tan. Nobody smells like somewhere warm. This flower doesn't smell like anywhere. It smells like the absence of somewhere.",
    },
    {
        id = "passenger_ticket",
        title = "Passenger Ticket",
        condition = "won",
        text = "A ticket for passage. The destination is blank. The departure date is blank. The passenger name is yours. The ink is fresh. You don't remember buying it.",
    },
    {
        id = "endorsement_stamped",
        title = "Stamped Endorsement",
        condition = "won",
        text = "A Residency Endorsement form. Stamped. The stamp is from the harbour authority — the one that dissolved. The signature is Higgs's. The date is blank. The crossings required field is blank. The stamp is warm.",
    },

    -- Chained finds (require other artefacts)
    {
        id = "appendix_fragment",
        title = "Appendix Fragment",
        condition = "artefact:charter_page",
        text = "A fragment of the missing appendix. The number of crossings required is referenced. The number is not stated. Instead there is a formula: crossings = crossings + 1. The formula is crossed out. Below it: 'See appendix.'",
    },
    {
        id = "maud_crew_list",
        title = "Maud Crew List",
        condition = "artefact:spare_rigging",
        text = "A crew manifest for the Maud. Sable is listed for crossings one through six. Crossing seven: 'rigging problem, ashore.' The handwriting on crossing seven is different. It's Higgs's.",
    },
    {
        id = "calloway_manifest",
        title = "Calloway Cross Manifest",
        condition = "artefact:second_ledger_page",
        text = "The manifest for the Calloway Cross's third crossing. Maren is not listed. There's a note: 'Equipment problem. Minor.' The note is in the same precise handwriting as the second ledger. Maren's handwriting.",
    },
    {
        id = "notation_key",
        title = "Notation Key",
        condition = "artefact:mayors_income_file",
        text = "A card that explains the notation on the Mayor's Income file. The notation means 'returned without memory.' It means the ship came back. The crew did not. Not fully. The notation is used for ships that complete the crossing. All of them.",
    },

    -- Deep lore (run count gated)
    {
        id = "higgs_coat",
        title = "Higgs's Coat",
        condition = "runs10",
        text = "The coat Higgs wears. You found it hanging on a hook in the office. It's the same coat. The same one someone left last week. The same one in the berth three ship. The same one. There is one coat. It is always the same coat.",
    },
    {
        id = "wharf_photo",
        title = "Wharf Photograph",
        condition = "runs10",
        text = "A photograph of the wharf. The planks are new. The sky is blue. The water is blue. The Reaches are visible — green and warm. Higgs is in the photograph. He's wearing the same coat. The photograph is dated. The date is before your first crossing.",
    },
    {
        id = "mayors_income_log",
        title = "Mayor's Income — Full Log",
        condition = "runs20",
        text = "The complete log of the Mayor's Income. Forty-seven crossings. The entries are routine until crossing forty-two. After that, the handwriting changes. It becomes yours. You don't remember writing them. The entries describe the Reaches in detail. The descriptions don't match what you remember. You don't remember the Reaches. The log says you did.",
    },
    {
        id = "endorsement_yours",
        title = "Your Endorsement",
        condition = "runs20",
        text = "Your Residency Endorsement. Approved. The stamp is Higgs's. The date is the date of your first crossing. The crossings required field is filled in. The number is higher than your total runs. The number is still counting.",
    },

    -- Hidden finds (specific conditions)
    {
        id = "empty_bottle",
        title = "Empty Bottle",
        condition = "any",
        text = "A bottle. Empty. The label is in a language you almost recognise. The residue smells like the Reaches flower — like the absence of somewhere. The glass is warm.",
    },
    {
        id = "cully_notebook",
        title = "Cully's Notebook",
        condition = "any",
        text = "A notebook full of systems. Drift System. Tide System. Reef System. Forty-one crossings, none successful. Each entry ends with 'almost.' The handwriting gets shakier. The last entry says: 'The port isn't the point. The almost is.'",
    },
    {
        id = "sable_rope_knot",
        title = "Sable's Knot",
        condition = "any",
        text = "A knot Sable tied. It's a rigging knot — one she says she used on the Maud. The rope is old. The knot is tight. She says it holds because the rope remembers. She says everything remembers. She says that's the problem.",
    },
    {
        id = "maren_calculations",
        title = "Maren's Calculations",
        condition = "any",
        text = "A sheet of numbers. Expected value, variance, win rate. At the bottom: 'The shortfall is not random. The shortfall is structural. The ships that don't come back are not lost. They are returned without their crews. The crews are returned without their memories. The memories are returned as flotsam. I don't know where they go. The math doesn't cover it.'",
    },

    -- Final layer
    {
        id = "reaches_coordinates",
        title = "Reaches Coordinates",
        condition = "artefact:driftwood_map",
        text = "Coordinates for the Reaches. They match the ship's log fragment. They match the driftwood map. They match the notation on the Mayor's Income file. The coordinates point to a place that is visible from the wharf on clear days. The place is not on any chart. The place is right there. It has always been right there.",
    },
    {
        id = "final_entry",
        title = "Final Entry",
        condition = "artefact:mayors_income_log",
        text = "The last entry in the Mayor's Income log. Your handwriting. It says: 'I remember the crossing. I don't remember what came after. I remember the wharf. I remember Higgs. I remember the forms. I don't remember filing them. I don't remember leaving. I remember arriving. I have always been arriving. The Reaches are the wharf. The wharf is the Reaches. They are the same place seen from different sides of the same water. I wrote this. I will not remember writing it. It will float back.'",
    },
    {
        id = "higgs_truth",
        title = "What Higgs Knows",
        condition = "artefact:notation_key",
        text = "Higgs knows. He has always known. The endorsement is not processing. There is nothing to process. The crossings are not counted because there is no number. The number was omitted because the number is not finite. The Reaches are not a destination. The Reaches are what the wharf looks like from the other side. Higgs files the forms because someone has to. He has been filing them for longer than the planks. He does not know what happens to the forms. He knows what happens to the people. They come back. They always come back. They don't remember. The flotsam remembers for them. Higgs keeps the records. That is the extent of what he knows how to do. He is not sinister. He is situated. He belongs to this in a way you don't. Not yet. You will.",
    },
}

-- Build lookup by ID
Artefacts.ById = {}
for _, a in ipairs(Artefacts.List) do
    Artefacts.ById[a.id] = a
end

-- Check if an artefact can be found given current state
function Artefacts.canFind(artefact, state)
    local cond = artefact.condition
    if cond == "any" then return true end
    if cond == "watch3" then return state.maxWatchReached >= 3 end
    if cond == "watch4" then return state.maxWatchReached >= 4 end
    if cond == "won" then return state.hasWon end
    if cond == "runs5" then return state.totalRuns >= 5 end
    if cond == "runs10" then return state.totalRuns >= 10 end
    if cond == "runs20" then return state.totalRuns >= 20 end
    if cond == "modifier" then return state.uniqueModifiersUsed >= 5 end
    if cond:match("^artefact:") then
        local required = cond:sub(10)
        return state.collected[required] == true
    end
    return false
end

-- Roll for an artefact during salvage
-- Returns artefact table or nil (plain flotsam)
function Artefacts.roll(state)
    -- 35% chance of artefact if any are available
    if math.random() > 0.35 then return nil end

    -- Build pool of available artefacts not yet collected
    local pool = {}
    for _, a in ipairs(Artefacts.List) do
        if not state.collected[a.id] and Artefacts.canFind(a, state) then
            table.insert(pool, a)
        end
    end

    if #pool == 0 then return nil end
    return pool[math.random(#pool)]
end

function Artefacts.getTitle(id)
    local a = Artefacts.ById[id]
    return a and a.title or "Unknown"
end

function Artefacts.getText(id)
    local a = Artefacts.ById[id]
    return a and a.text or ""
end

function Artefacts.getCount()
    return #Artefacts.List
end

return Artefacts