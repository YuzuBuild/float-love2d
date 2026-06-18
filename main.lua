-- Float — main.lua entry point
-- A minimalist rogue-lite card game. LÖVE2D port of the iOS Swift game.

math.randomseed(os.time())

local SceneManager = require("src.scene_manager")
local UI = require("src.ui.screens")
local Run = require("src.models.run")
local Meta = require("src.models.meta")
local Engine = require("src.engine.engine")
local Dialogue = require("src.dialogue")
local Audio = require("src.audio.audio")

-- Global state
local meta
local engine
local gameScreen

-- Fust flash state (used by GameScreen)
local fustFlash = 0

function love.load(arg)
    -- Test mode: love . --test
    if arg and arg[1] == "--test" then
        local ok, err = pcall(function()
            require("test.test_engine")
        end)
        if not ok then print("Test error: " .. tostring(err)) end
        love.event.quit()
        return
    end

    -- Simulation mode: love . --sim 1000
    if arg and arg[1] == "--sim" then
        local numRuns = tonumber(arg[2]) or 1000
        local ok, err = pcall(function()
            local Sim = require("test.sim_balance")
            Sim.run(numRuns)
        end)
        if not ok then print("Sim error: " .. tostring(err)) end
        love.event.quit()
        return
    end

    -- Load meta-progression
    meta = Meta.load()

    -- Start at departure screen
    requestDeparture("inProgress")
end

function requestDeparture(previousOutcome)
    local line = Dialogue.runStartLine(previousOutcome, meta.totalRuns)
    local accentColor = Run.randomAccent()
    local condition = Run.Condition[math.random(#Run.Condition)]

    local screen = UI.DepartureScreen.new(line, condition, accentColor,
        function() beginRun(accentColor, condition) end,
        function() showTutorial() end
    )
    SceneManager.switch(screen)
end

function beginRun(accentColor, condition)
    local run = Run.new({ startingChips = meta:startingChips() })
    run.accentColor = accentColor
    run.runCondition = condition

    engine = Engine.new(run, meta)
    gameScreen = UI.GameScreen.new(engine, meta, function()
        requestDeparture(engine.run.outcome)
    end)
    SceneManager.switch(gameScreen)

    Audio.startAmbient()
end

function showTutorial()
    -- TODO: tutorial screen
end

function love.update(dt)
    SceneManager.update(dt)
end

function love.draw()
    SceneManager.draw()
end

function love.mousepressed(x, y, button)
    SceneManager.mousepressed(x, y, button)
end

function love.keypressed(key)
    SceneManager.keypressed(key)
    if key == "m" then
        Audio.toggleMute()
    end
end

function love.touchpressed(id, x, y)
    SceneManager.touchpressed(id, x, y)
end