-- Animation system: simple tweening for card slide-in and flip
-- Handles per-card animation state

local Animation = {}
Animation.__index = Animation

function Animation.new()
    return setmetatable({
        cards = {},  -- map of card.id -> { x, y, targetX, targetY, scale, targetScale, flipProgress, flipping, faceDown, revealProgress }
    }, Animation)
end

-- Register or update a card's target position
function Animation:setTarget(cardId, targetX, targetY, isFaceDown)
    local state = self.cards[cardId]
    if not state then
        -- New card — start from deck source position
        state = {
            x = self.deckSourceX or 9999,
            y = self.deckSourceY or 0,
            targetX = targetX,
            targetY = targetY,
            scaleX = 1,
            flipProgress = 1,
            flipping = false,
            faceDown = isFaceDown or false,
            pendingReveal = false,
        }
        self.cards[cardId] = state
    else
        state.targetX = targetX
        state.targetY = targetY
    end
end

-- Trigger a flip animation (face-down → face-up)
function Animation:triggerFlip(cardId)
    local state = self.cards[cardId]
    if state and state.faceDown then
        state.flipping = true
        state.flipProgress = 1  -- start at full (face down)
    end
end

-- Set deck source position (where cards animate from)
function Animation:setDeckSource(x, y)
    self.deckSourceX = x
    self.deckSourceY = y
end

-- Update all card animations
function Animation:update(dt)
    local speed = 8  -- animation speed
    for id, state in pairs(self.cards) do
        -- Position tweening
        state.x = state.x + (state.targetX - state.x) * math.min(1, dt * speed)
        state.y = state.y + (state.targetY - state.y) * math.min(1, dt * speed)

        -- Flip animation
        if state.flipping then
            state.flipProgress = state.flipProgress - dt * 6
            if state.flipProgress <= 0 then
                state.flipping = false
                state.faceDown = false
                state.flipProgress = 1
            elseif state.flipProgress <= 0.5 and not state.faceDownChanged then
                state.faceDownChanged = true
                state.faceDown = false
            end
        end
    end
end

-- Get the current render state for a card
function Animation:getState(cardId)
    return self.cards[cardId]
end

-- Check if a card is still animating
function Animation:isAnimating(cardId)
    local state = self.cards[cardId]
    if not state then return false end
    local dx = math.abs(state.x - state.targetX)
    local dy = math.abs(state.y - state.targetY)
    return dx > 1 or dy > 1 or state.flipping
end

-- Remove a card from tracking
function Animation:remove(cardId)
    self.cards[cardId] = nil
end

-- Clear all
function Animation:clear()
    self.cards = {}
end

-- Get current scaleX for a card (for flip animation)
function Animation:getScaleX(cardId)
    local state = self.cards[cardId]
    if not state then return 1 end
    if state.flipping then
        -- Scale from 1 → 0 → 1 during flip
        local p = state.flipProgress
        if p > 0.5 then
            return (p - 0.5) * 2  -- 1 → 0
        else
            return (0.5 - p) * 2  -- 0 → 1
        end
    end
    return 1
end

return Animation