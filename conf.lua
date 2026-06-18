-- Float — LÖVE2D configuration
local conf = {}

function conf(t)
    t.version = "11.5"
    t.console = false
    t.window.title = "Float"
    t.window.width = 390
    t.window.height = 844
    t.window.minwidth = 320
    t.window.minheight = 568
    t.window.resizable = true
    t.window.vsync = 1
    t.window.fsaa = 0
    t.window.highdpi = true
    t.modules.joystick = false
    t.modules.video = false
    t.modules.physics = false
end

return conf