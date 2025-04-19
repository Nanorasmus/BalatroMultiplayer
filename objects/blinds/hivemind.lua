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

function MP.is_team_based()
	return MP.LOBBY and MP.LOBBY.code and MP.LOBBY.config.nano_battle_royale and MP.LOBBY.config.nano_br_mode == "hivemind"
end

local create_playing_card_ref = create_playing_card
function create_playing_card(card_init, area, skip_materialize, silent, colours, skip_emplace)
	local card = create_playing_card_ref(card_init, area, skip_materialize, silent, colours, skip_emplace)
	if MP.is_team_based() then
		if MP and MP.LOBBY.code and MP.LOBBY.is_started and not MP.GAME.setting_deck and area and (area == G.deck or area == G.hand or area == G.discard or area == G.play) then
			MP.ACTIONS.add_card(card)
		end
	end
	return card
end

local set_edition_ref = Card.set_edition
function Card:set_edition(edition, immediate, silent, delay)
	local new_edition = "none"

	if edition then
		if type(edition) == "string" then
			new_edition = edition
		else
			local reversed_edition = MP.UTILS.reverse_key_value_pairs(edition, true)
			if reversed_edition["true"] then
				new_edition = reversed_edition["true"]
			end
		end
	end


	if MP and MP.LOBBY.code and MP.LOBBY.is_started and not MP.GAME.setting_deck and (self.area == G.deck or self.area == G.hand or self.area == G.discard or self.area == G.play) then
		MP.ACTIONS.set_card_edition(self, new_edition)
	end

	set_edition_ref(self, edition, immediate, silent, delay)
end

local level_up_hand_ref = level_up_hand
function level_up_hand(card, hand, instant, amount, bypass_team_sync)
	if not bypass_team_sync then
		MP.ACTIONS.change_hand_level(hand, amount or 1)
	end
	level_up_hand_ref(card, hand, instant, amount)
end

local copy_card_ref = copy_card
function copy_card(other, new_card, card_scale, playing_card, strip_edition)
	if new_card and new_card.playing_card and other and other.playing_card and MP and MP.LOBBY.code and MP.LOBBY.is_started and not MP.GAME.setting_deck
	and (new_card.area == G.deck or new_card.area == G.hand or new_card.area == G.discard or new_card.area == G.play)
	and (other.area == G.deck or other.area == G.hand or other.area == G.discard or other.area == G.play) then
		MP.ACTIONS.copy_card(other, new_card)
	end
	

	local old_setting_deck = MP.GAME.setting_deck

	MP.GAME.setting_deck = true
	local card = copy_card_ref(other, new_card, card_scale, playing_card, strip_edition)
	MP.GAME.setting_deck = old_setting_deck
	
	return card
end