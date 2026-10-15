-- ancient — parte de Hyprland del shell. duran la enlaza en ~/.config/hypr/shell.lua
-- al hacer `duran switch ancient`. theme = colores y ajustes que lee scheme/active.lua.

-- Paneles del shell sin animación de Hyprland (el shell los anima)
hl.layer_rule({ match = { namespace = "ancient-.*" }, no_anim = true })

return {
    theme = {
        accent = "c0caf5", accent2 = "7aa2f7", accent3 = "bb9af7",
        onAccent = "16161e", inactive = "16161e", outline = "414868", bg = "1a1b26",
        gapsIn = 5, gapsOut = 10, animations = true, blur = true, vrr = 0,
    },
}
