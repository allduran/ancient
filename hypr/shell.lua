-- ancient — parte de Hyprland del shell. duran la enlaza en ~/.config/hypr/shell.lua
-- al hacer `duran switch ancient`. theme = colores y ajustes que lee scheme/active.lua.

-- Lo que escribe ancient desde Ajustes: modo (radiant | dire), ventanas flotantes (0 | 1)
-- y la build de Dire (direGaps, direAnim, direBlur, direVrr)
local opts = {}
local f = io.open(os.getenv("HOME") .. "/.local/state/ancient/hypr", "r")
if f then
	for line in f:lines() do
		local k, v = line:match("^(%w+)=(.*)$")
		if k then
			opts[k] = v
		end
	end
	f:close()
end

-- Paneles del shell sin animación de Hyprland (el shell los anima)
hl.layer_rule({ match = { namespace = "ancient-.*" }, no_anim = true })

-- Talento VENTANAS: todas flotantes
if opts.float == "1" then
	hl.window_rule({ match = { class = ".*" }, float = true })
end

-- Atajos cambiados en Ajustes → Atajos (los escribe ancient; solo existen con ancient activo)
pcall(dofile, os.getenv("HOME") .. "/.local/state/ancient/keybinds.lua")

local themes = {
	radiant = {
		accent = "c9a45c",
		accent2 = "8fc27f",
		accent3 = "c8463a",
		onAccent = "0a0c0e",
		inactive = "3b3428",
		outline = "4a3f2c",
		bg = "0a0c0e",
		gapsIn = 6,
		gapsOut = 12,
		animations = true,
		blur = true,
		vrr = 0,
	},
	dire = {
		accent = "e0583a",
		accent2 = "ff8a5c",
		accent3 = "c8463a",
		onAccent = "0a0c0e",
		inactive = "3b1a15",
		outline = "4a2a20",
		bg = "0d0807",
		gapsIn = 6,
		gapsOut = 12,
		animations = true,
		blur = true,
		vrr = 2,
	},
}

local theme = themes[opts.mode] or themes.radiant

-- Build de Dire (Ajustes → Build Dire)
if opts.mode == "dire" then
	if opts.direGaps == "0" then
		theme.gapsIn, theme.gapsOut = 0, 0
	end
	theme.animations = opts.direAnim == "1"
	theme.blur = opts.direBlur == "1"
	theme.vrr = tonumber(opts.direVrr) or theme.vrr
end

return { theme = theme }
