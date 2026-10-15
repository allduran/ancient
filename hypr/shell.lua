-- ancient — parte de Hyprland del shell. duran la enlaza en ~/.config/hypr/shell.lua
-- al hacer `duran switch ancient`. theme = colores y ajustes que lee scheme/active.lua.

-- Paneles del shell sin animación de Hyprland (el shell los anima)
hl.layer_rule({ match = { namespace = "ancient-.*" }, no_anim = true })
-- Sin autotiling: todas las ventanas se abren flotantes
-- hl.window_rule({ match = { class = ".*" }, float = true })

return {
    theme = {
        accent = "c9a45c", accent2 = "8fc27f", accent3 = "c8463a",
        onAccent = "0a0c0e", inactive = "3b3428", outline = "4a3f2c", bg = "0a0c0e",
        gapsIn = 6, gapsOut = 12, animations = true, blur = true, vrr = 0,
    },
}
