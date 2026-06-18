-- SceneManager: simple screen stack for LÖVE2D
-- Replaces SwiftUI's view routing

local SceneManager = {}
SceneManager._stack = {}
SceneManager.__index = SceneManager

function SceneManager.current()
    return SceneManager._stack[#SceneManager._stack]
end

function SceneManager.switch(scene)
    if #SceneManager._stack > 0 then
        local old = SceneManager._stack[#SceneManager._stack]
        if old.exit then old:exit() end
    end
    SceneManager._stack = { scene }
    if scene.enter then scene:enter() end
end

function SceneManager.push(scene)
    if scene.enter then scene:enter() end
    table.insert(SceneManager._stack, scene)
end

function SceneManager.pop()
    local top = table.remove(SceneManager._stack)
    if top and top.exit then top:exit() end
    if #SceneManager._stack > 0 then
        local prev = SceneManager._stack[#SceneManager._stack]
        if prev.resume then prev:resume() end
    end
end

-- Input dispatch
function SceneManager.update(dt)
    local scene = SceneManager.current()
    if scene and scene.update then scene:update(dt) end
end

function SceneManager.draw()
    local scene = SceneManager.current()
    if scene and scene.draw then scene:draw() end
end

function SceneManager.mousepressed(x, y, button)
    local scene = SceneManager.current()
    if scene and scene.mousepressed then scene:mousepressed(x, y, button) end
end

function SceneManager.keypressed(key)
    local scene = SceneManager.current()
    if scene and scene.keypressed then scene:keypressed(key) end
end

function SceneManager.touchpressed(id, x, y)
    local scene = SceneManager.current()
    if scene and scene.touchpressed then scene:touchpressed(id, x, y) end
end

return SceneManager