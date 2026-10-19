-- ancient — parte de Hyprland del shell. duran la enlaza en ~/.config/hypr/shell.lua
-- al hacer `duran switch ancient`. theme = colores y ajustes que lee scheme/active.lua.

-- Lo que escribe ancient desde Ajustes: modo (radiant | dire) y ventanas flotantes (0 | 1)
local opts = {}
local f = io.open(os.getenv("HOME") .. "/.local/state/ancient/hypr", "r")
if f then
    for line in f:lines() do
        local k, v = line:match("^(%w+)=(.*)$")
        if k then opts[k] = v end
    end
    f:close()
end

-- Paneles del shell sin animación de Hyprland (el shell los anima)
hl.layer_rule({ match = { namespace = "ancient-.*" }, no_anim = true })

-- Talento VENTANAS: todas flotantes
if opts.float == "1" then
    hl.window_rule({ match = { class = ".*" }, float = true })
end

local themes = {
    radiant = {
        accent = "c9a45c", accent2 = "8fc27f", accent3 = "c8463a",
        onAccent = "0a0c0e", inactive = "3b3428", outline = "4a3f2c", bg = "0a0c0e",
        gapsIn = 6, gapsOut = 12, animations = true, blur = true, vrr = 0,
    },
    dire = {
        accent = "e0583a", accent2 = "ff8a5c", accent3 = "c8463a",
        onAccent = "0a0c0e", inactive = "3b1a15", outline = "4a2a20", bg = "0d0807",
        gapsIn = 6, gapsOut = 12, animations = true, blur = true, vrr = 2,
    },
}

return { theme = themes[opts.mode] or themes.radiant }
