SMODS.Atlas({
	key = "hivemind_blind_chip",
	path = "hivemind.png",
	atlas_table = "ANIMATION_ATLAS",
	frames = 21,
	px = 34,
	py = 34,
})

SMODS.Blind({
	key = "hivemind",
	dollars = 5,
	mult = 1, -- Jen's Almanac crashes the game if the mult is 0
	boss_colour = G.C.GOLD,
	boss = { min = 1, max = 10 },
	atlas = "hivemind_blind_chip",
	discovered = true,
	in_pool = function(self)
		return false
	end,
})