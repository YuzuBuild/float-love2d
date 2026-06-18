-- Card model, Deck, and hand evaluation
-- Ports Card.swift + evaluate() from the Swift codebase

local Card = {}

-- Suit enum
Card.Suit = { "hearts", "diamonds", "clubs", "spades" }
Card.SuitSymbol = { hearts = "♥", diamonds = "♦", clubs = "♣", spades = "♠" }

local function isRedSuit(suit)
    return suit == "hearts" or suit == "diamonds"
end

-- Rank values: 2-14 (ace=14)
Card.Rank = {
    two = 2, three = 3, four = 4, five = 5, six = 6, seven = 7,
    eight = 8, nine = 9, ten = 10, jack = 11, queen = 12, king = 13, ace = 14
}

local RankNames = {
    [2] = "2", [3] = "3", [4] = "4", [5] = "5", [6] = "6", [7] = "7",
    [8] = "8", [9] = "9", [10] = "10", [11] = "J", [12] = "Q", [13] = "K", [14] = "A"
}

Card.RankNames = RankNames

-- Hard value for a rank (face cards = 10, ace = 11)
local function hardValue(rank)
    if rank >= 11 then return 10 end  -- J, Q, K
    if rank == 14 then return 11 end   -- A
    return rank
end
Card.hardValue = hardValue

local function isFaceCard(rank)
    return rank >= 10
end
Card.isFaceCard = isFaceCard

-- Create a standard card
function Card.new(suit, rank, opts)
    opts = opts or {}
    return {
        id = opts.id or tostring({}):gsub("table: ", ""),  -- unique-ish
        suit = suit,
        rank = rank,
        isFaceDown = opts.isFaceDown or false,
        voyageEffect = opts.voyageEffect or nil,
        fogValue = opts.fogValue or nil,
        fogRevealed = opts.fogRevealed or false,
    }
end

-- Create a voyage card (special card seeded into deck)
function Card.newVoyage(voyageType, fogValue)
    return {
        id = tostring({}):gsub("table: ", ""),
        suit = "spades",    -- placeholder
        rank = 2,           -- placeholder
        isFaceDown = false,
        voyageEffect = voyageType,
        fogValue = voyageType == "fogBank" and (fogValue or math.random(4, 9)) or nil,
        fogRevealed = false,
    }
end

function Card.isVoyage(card)
    return card.voyageEffect ~= nil
end

-- Deck: 6-deck shoe
Card.Deck = {}
local Deck = Card.Deck
Deck.__index = Deck

Deck.reshuffleThreshold = 52

function Deck.new(numberOfDecks)
    numberOfDecks = numberOfDecks or 6
    local cards = {}
    for _ = 1, numberOfDecks do
        for _, suit in ipairs(Card.Suit) do
            for rank = 2, 14 do
                table.insert(cards, Card.new(suit, rank))
            end
        end
    end
    -- Fisher-Yates shuffle
    for i = #cards, 2, -1 do
        local j = math.random(1, i)
        cards[i], cards[j] = cards[j], cards[i]
    end
    return setmetatable({ cards = cards }, Deck)
end

function Deck:shuffle()
    for i = #self.cards, 2, -1 do
        local j = math.random(1, i)
        self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
    end
end

function Deck:deal()
    if #self.cards == 0 then return nil end
    return table.remove(self.cards)
end

function Deck:topCard()
    return self.cards[#self.cards]
end

-- Remove and return a face card (10/J/Q/K), non-voyage. For Lucky Split.
function Deck:dealFaceCard()
    for i = #self.cards, 1, -1 do
        local c = self.cards[i]
        if isFaceCard(c.rank) and not Card.isVoyage(c) then
            return table.remove(self.cards, i)
        end
    end
    return nil
end

-- Insert a voyage card into the top portion of the deck
function Deck:insertVoyageCard(card)
    local count = #self.cards
    local range = math.min(25, math.max(1, count))
    local insertAt = math.max(1, count - math.random(1, range) + 1)
    table.insert(self.cards, insertAt, card)
end

-- Hand evaluation
local HandValue = {}
HandValue.__index = HandValue

function HandValue.new(hard, soft)
    return setmetatable({ hard = hard, soft = soft }, HandValue)
end

function HandValue:isBust() return self.soft > 21 end
function HandValue:isNatural() return self.soft == 21 end

Card.HandValue = HandValue

-- Evaluate a hand of cards. Handles voyage card effects.
function Card.evaluate(cards)
    local hasSquall = false
    for _, c in ipairs(cards) do
        if c.voyageEffect == "squall" then hasSquall = true; break end
    end

    local total = 0
    local aces = 0

    for _, c in ipairs(cards) do
        if not c.isFaceDown then
            local effect = c.voyageEffect
            if effect == "deadweight" then
                total = total + 13
            elseif effect == "undertow" then
                -- counts as 0
            elseif effect == "squall" then
                total = total + 3
            elseif effect == "fogBank" then
                total = total + (c.fogValue or 7)
            else
                -- normal card
                if c.rank == 14 then  -- ace
                    if hasSquall then
                        total = total + 1
                    else
                        aces = aces + 1
                        total = total + 11
                    end
                else
                    total = total + hardValue(c.rank)
                end
            end
        end
    end

    local hard = total - (aces * 10)

    -- Reduce aces 11→1 to avoid bust where possible
    while total > 21 and aces > 0 do
        total = total - 10
        aces = aces - 1
    end

    return HandValue.new(hard, total)
end

-- Check if a suit is red (for rendering)
function Card.isRed(suit)
    return isRedSuit(suit)
end

return Card