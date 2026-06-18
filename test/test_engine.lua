-- Headless test: verify engine logic works
-- Run with: love . --test  (or just lua5.3 test/test_engine.lua if lua is installed)

-- This file can be run from LÖVE2D by adding --test flag handling
-- For now, it's a manual verification script

local Card = require("src.models.card")
local Modifier = require("src.models.modifiers")
local VoyageCard = require("src.models.voyage_card")
local Run = require("src.models.run")
local Engine = require("src.engine.engine")
local Meta = require("src.models.meta")

local tests = {}
local failures = 0

function test(name, fn)
    tests[#tests + 1] = { name = name, fn = fn }
end

function assertEquals(a, b, msg)
    if a ~= b then
        print("FAIL: " .. (msg or "assertEquals") .. " — expected " .. tostring(b) .. ", got " .. tostring(a))
        failures = failures + 1
    end
end

function assertTrue(v, msg)
    if not v then
        print("FAIL: " .. (msg or "assertTrue"))
        failures = failures + 1
    end
end

-- Test 1: Deck creates 312 cards (6 * 52)
test("Deck has 312 cards", function()
    local deck = Card.Deck.new()
    assertEquals(#deck.cards, 312, "deck size")
end)

-- Test 2: Hand evaluation — simple
test("evaluate simple hand", function()
    local cards = {
        Card.new("hearts", 10),
        Card.new("spades", 7),
    }
    local hv = Card.evaluate(cards)
    assertEquals(hv.soft, 17, "10+7 soft")
    assertEquals(hv.hard, 17, "10+7 hard")
end)

-- Test 3: Hand evaluation — ace as 11
test("evaluate ace as 11", function()
    local cards = {
        Card.new("hearts", 14),  -- ace
        Card.new("spades", 6),
    }
    local hv = Card.evaluate(cards)
    assertEquals(hv.soft, 17, "A+6 soft")
    assertEquals(hv.hard, 7, "A+6 hard")
end)

-- Test 4: Hand evaluation — ace reduces from 11 to 1
test("evaluate ace reduces to 1 on bust", function()
    local cards = {
        Card.new("hearts", 14),  -- ace
        Card.new("spades", 10),
        Card.new("clubs", 5),
    }
    local hv = Card.evaluate(cards)
    assertEquals(hv.soft, 16, "A+10+5 soft (ace reduces)")
end)

-- Test 5: Voyage card — deadweight counts as 13
test("deadweight counts as 13", function()
    local cards = {
        Card.newVoyage("deadweight"),
        Card.new("spades", 5),
    }
    local hv = Card.evaluate(cards)
    assertEquals(hv.soft, 18, "deadweight(13)+5")
end)

-- Test 6: Voyage card — undertow counts as 0
test("undertow counts as 0", function()
    local cards = {
        Card.newVoyage("undertow"),
        Card.new("spades", 10),
    }
    local hv = Card.evaluate(cards)
    assertEquals(hv.soft, 10, "undertow(0)+10")
end)

-- Test 7: Voyage card — squall locks aces to 1
test("squall locks aces to 1", function()
    local cards = {
        Card.newVoyage("squall"),     -- 3 + locks aces
        Card.new("hearts", 14),       -- ace = 1 (not 11)
        Card.new("spades", 5),
    }
    local hv = Card.evaluate(cards)
    assertEquals(hv.soft, 9, "squall(3)+ace(1)+5 = 9")
end)

-- Test 8: Run constants
test("run constants", function()
    assertEquals(Run.StartingChips, 200)
    assertEquals(Run.HandsPerAct, 8)
    assertEquals(Run.ActCount, 5)
    assertEquals(Run.WatchThresholds[1], 300)
    assertEquals(Run.WatchThresholds[5], 2500)
end)

-- Test 9: Engine basic flow — place bet and deal
test("engine place bet and deal", function()
    local meta = Meta.load()
    local run = Run.new({ startingChips = meta:startingChips() })
    local engine = Engine.new(run, meta)

    assertEquals(engine.phase, "betting")
    assertEquals(engine.chipStack, 200)

    engine:placeBet(20)
    assertEquals(engine.phase, "playerTurn")
    assertEquals(engine.chipStack, 180)  -- 200 - 20
    assertEquals(#engine:activeHand(), 2)  -- two cards dealt
    assertEquals(#engine.dealerCards, 2)  -- dealer has 2 cards
end)

-- Test 10: Modifier shop offer excludes active
test("shop offer excludes active", function()
    local pool = Modifier.shopOffer({ "hotStreak" })
    for _, t in ipairs(pool) do
        assertTrue(t ~= "hotStreak", "hotStreak should be excluded")
    end
    assertEquals(#pool, 3, "should return 3 offers")
end)

-- Test 11: Voyage card draft offer returns 3 types
test("voyage card draft offer", function()
    local offer = VoyageCard.draftOffer()
    assertEquals(#offer, 3, "draft offer should have 3 choices")
    -- All should be distinct
    assertTrue(offer[1] ~= offer[2], "first two should differ")
    assertTrue(offer[2] ~= offer[3], "last two should differ")
    assertTrue(offer[1] ~= offer[3], "first and last should differ")
end)

-- Run tests
print("=== Float Engine Tests ===")
for _, t in ipairs(tests) do
    local ok, err = pcall(t.fn)
    if not ok then
        print("ERROR in '" .. t.name .. "': " .. tostring(err))
        failures = failures + 1
    end
end

if failures == 0 then
    print("\nAll " .. #tests .. " tests passed ✓")
else
    print("\n" .. failures .. " test(s) FAILED ✗")
end

os.exit(failures > 0 and 1 or 0)