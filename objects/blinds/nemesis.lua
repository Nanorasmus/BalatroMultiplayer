SMODS.Atlas({
	key = "player_blind_chip",
	path = "player_blind_row.png",
	atlas_table = "ANIMATION_ATLAS",
	frames = 21,
	px = 34,
	py = 34,
})

SMODS.Blind({
	key = "nemesis",
	dollars = 5,
	mult = 1, -- Jen's Almanac crashes the game if the mult is 0
	boss_colour = G.C.MULITPLAYER,
	boss = { min = 1, max = 10 },
	atlas = "player_blind_chip",
	discovered = true,
	in_pool = function(self)
		return false
	end,
})

function MP.is_pvp_boss()
	if not G.GAME or not G.GAME.blind then
		return false
	end
	return G.GAME.blind.config.blind.key == "bl_mp_nemesis" or G.GAME.blind.config.blind.key == "bl_mp_potluck" or G.GAME.blind.config.blind.key == "bl_mp_hivemind"
end

function MP.is_blind_pvp_boss(blind)
	if not blind then
		return false
	end
	return MP.is_key_pvp_blind(blind.config.blind.key)
end

function MP.is_key_pvp_blind(key)
	return key == "bl_mp_nemesis" or key == "bl_mp_potluck" or key == "bl_mp_hivemind"
end