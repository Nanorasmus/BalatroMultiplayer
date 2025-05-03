Client = {}

function Client.send(msg)
	if not (msg == "action:keepAliveAck") then
		sendTraceMessage(string.format("Client sent message: %s", msg), "MULTIPLAYER")
	end
	love.thread.getChannel("uiToNetwork"):push(msg)
end

-- Server to Client
function MP.ACTIONS.set_username(username)
	MP.LOBBY.username = username or "Guest"
	if MP.LOBBY.connected then
		Client.send(string.format("action:username,username:%s,modHash:%s", MP.LOBBY.username, MP.MOD_STRING))
	end
end

local function action_connected()
	MP.LOBBY.connected = true
	MP.UI.update_connection_status()
	Client.send(string.format("action:username,username:%s,modHash:%s", MP.LOBBY.username, MP.MOD_STRING))
end

local function action_joinedLobby(code, type)
	MP.LOBBY.code = code
	MP.LOBBY.type = type
	MP.LOBBY.team_id = "RED"
	MP.ACTIONS.lobby_info()
	MP.UI.update_connection_status()
end

function dump(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. dump(v) .. ','
	   end
	   return s .. '} '
	else
	   return tostring(o)
	end
 end


local function action_lobbyInfo(player_id, players_string, is_started)
	-- Set players
	local old = MP.LOBBY.players
	MP.LOBBY.players = {}
	MP.LOBBY.player_count = 0

	for k, v in string.gmatch(players_string, "([^\\|]+)") do
		local player = MP.UTILS.string_to_table(k, "-", ">")
		local id = MP.UTILS.postProcessStringFromNetwork(player.id)
		MP.LOBBY.players[id] = {
			id = id,
			username = MP.UTILS.postProcessStringFromNetwork(player.username),
			hash = MP.UTILS.postProcessStringFromNetwork(player.hash),
			is_host = player.isHost == "true",
			team_id = old[id] and old[id].team_id or "RED"
		}
		MP.LOBBY.player_count = MP.LOBBY.player_count + 1
	end

	-- Basic info
	MP.LOBBY.player_id = player_id
	MP.LOBBY.is_started = is_started == "true"
	MP.LOBBY.is_host = MP.LOBBY.players[MP.LOBBY.player_id].is_host

	MP.LOBBY.ready_to_start = MP.LOBBY.is_host and MP.LOBBY.player_count >= 2 and not MP.LOBBY.is_started

	if not MP.LOBBY.is_started then
		if MP.LOBBY.is_host then
			MP.ACTIONS.lobby_options()
		end

		if G.STAGE == G.STAGES.MAIN_MENU then
			MP.ACTIONS.update_player_usernames()
		end
	end
end

local function action_kicked_from_lobby()
	MP.LOBBY.code = nil
	MP.UI.update_connection_status()
end

local function action_error(message)
	sendWarnMessage(message, "MULTIPLAYER")

	MP.UTILS.overlay_message(message)
end

local function action_message(loc_key)
	MP.UI.show_message(localize(loc_key))
end

local function action_keep_alive()
	Client.send("action:keepAliveAck")
end

local function action_disconnected()
	MP.LOBBY.connected = false
	if MP.LOBBY.code then
		MP.LOBBY.code = nil
	end
	MP.UI.update_connection_status()
end

---@param deck string
---@param seed string
---@param stake_str string
local function action_start_game(seed, stake_str)
	MP.reset_game_states()
	local stake = tonumber(stake_str)
	MP.ACTIONS.set_ante(0)
	if not MP.LOBBY.config.different_seeds and MP.LOBBY.config.custom_seed ~= "random" then
		seed = MP.LOBBY.config.custom_seed
	end
	G.FUNCS.exit_overlay_menu()
	G.FUNCS.lobby_start_run(nil, { seed = seed, stake = stake })

	-- Close menu UI after 0.2 sec if it's still there
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		time = 0.2,
		func = function()
			if G.MAIN_MENU_UI then
				G.MAIN_MENU_UI:remove()
			end
		end
	}))
end

local function action_start_blind()
	if MP.GAME.in_blind then
		return
	end

	local is_pvp = MP.GAME.ready_pvp_blind

	MP.GAME.ready_blind = false
	MP.GAME.ready_pvp_blind = false

	if MP.GAME.next_blind_context then

		G.FUNCS.select_blind(MP.GAME.next_blind_context, is_pvp)

		
		if is_pvp then
			MP.GAME.timer_started = false
			MP.GAME.timer = 120

			-- Re-end timer after half a second in case opponent started it as we readied up
			G.E_MANAGER:add_event(Event({
				trigger = "after",
				time = 0.5,
				func = function()
					MP.GAME.timer_started = false
					return true
				end
			}))
		end
	else
		sendErrorMessage("No next blind context", "MULTIPLAYER")
	end
end

---@param score_str string
---@param hands_left_str string
---@param skips_str string
local function action_enemy_info(player_id, enemy_id, score_str, hands_left_str, skips_str, lives_str)
	local score = MP.INSANE_INT.from_string(score_str)

	local hands_left = tonumber(hands_left_str)
	local skips = tonumber(skips_str)
	local lives = tonumber(lives_str)

	if MP.GAME.enemies[player_id] == nil then
		MP.GAME.enemies[player_id] = {
			highest_score = MP.INSANE_INT.empty(),
		}
	end

	if score == nil or hands_left == nil then
		sendDebugMessage("Invalid score or hands_left", "MULTIPLAYER")
		return
	end

	if MP.INSANE_INT.greater_than(score, MP.GAME.enemies[player_id].highest_score) then
		MP.GAME.enemies[player_id].highest_score = score
	end
	if MP.INSANE_INT.greater_than(score, MP.GAME.global_highest_score) then
		MP.GAME.global_highest_score = score
	end

	-- Update score values for e_count, coeffiocient, and exponent
	G.E_MANAGER:add_event(Event({
		blockable = false,
		blocking = false,
		trigger = "ease",
		delay = 3,
		ref_table = MP.GAME.enemies[player_id].score,
		ref_value = "e_count",
		ease_to = score.e_count,
		func = function(t)
			return math.floor(t)
		end,
	}))

	G.E_MANAGER:add_event(Event({
		blockable = false,
		blocking = false,
		trigger = "ease",
		delay = 3,
		ref_table = MP.GAME.enemies[player_id].score,
		ref_value = "coeffiocient",
		ease_to = score.coeffiocient,
		func = function(t)
			return math.floor(t)
		end,
	}))

	G.E_MANAGER:add_event(Event({
		blockable = false,
		blocking = false,
		trigger = "ease",
		delay = 3,
		ref_table = MP.GAME.enemies[player_id].score,
		ref_value = "exponent",
		ease_to = score.exponent,
		func = function(t)
			return math.floor(t)
		end,
	}))

	-- Only update enemy if provided
	if enemy_id ~= nil then
		if enemy_id ~= "None" then
			-- Set enemy
			if player_id == MP.LOBBY.player_id then
				MP.LOBBY.enemy_id = enemy_id
			end

			MP.GAME.enemies[player_id].enemy_id = enemy_id
		else
			-- Clear enemy
			if player_id == MP.LOBBY.player_id then
				MP.LOBBY.enemy_id = nil
			end

			MP.GAME.enemies[player_id].enemy_id = nil
		end
	end

	-- Update the rest
	MP.GAME.enemies[player_id].hands = hands_left
	MP.GAME.enemies[player_id].skips = skips
	MP.GAME.enemies[player_id].lives = lives
	if MP.LOBBY.enemy_id and MP.LOBBY.enemy_id == player_id and MP.is_pvp_boss() then
		G.HUD_blind:get_UIE_by_ID("HUD_blind_count"):juice_up()
		G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned"):juice_up()
	end

	if MP.GAME.ready_blind then
		MP.UI.show_enemy_location()
	end
end

local function action_set_player_team(player_id, team_id)
	if MP.LOBBY.players[player_id] then
		MP.LOBBY.players[player_id].team_id = team_id
	end

	if MP.GAME.enemies[player_id] then
		MP.GAME.enemies[player_id].team_id = team_id
	end

	if player_id == "house" and MP.is_team_based() and G.C[team_id] then
		if MP.LOBBY.config.nano_br_mode == "hivemind" then
			G.P_BLINDS["bl_mp_hivemind"].boss_colour = G.C[team_id]
		end
	end
end

local function action_stop_game()
	if G.STAGE ~= G.STAGES.MAIN_MENU then
		G.FUNCS.go_to_menu()
		MP.UI.update_connection_status()
		MP.reset_game_states()
	end
end

local function action_end_pvp()
	MP.GAME.end_pvp = true
	MP.LOBBY.enemy_id = nil
end

local function action_end_blind()
	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 0.5,
		blockable = false,
		blocking = false,
		func = function()
			if MP.GAME.calculating_hand or MP.GAME.score_waiting then
				return false
			end

			MP.GAME.end_pvp = true
			return true
		end
	}))
end

---@param lives number
local function action_player_info(lives)
	if MP.GAME.lives ~= lives then
		if MP.GAME.lives ~= 0 and MP.LOBBY.config.gold_on_life_loss then
			MP.GAME.comeback_bonus_given = false
			MP.GAME.comeback_bonus = MP.GAME.comeback_bonus + 1
		end
		ease_lives(lives - MP.GAME.lives)
	end
	MP.GAME.lives = tonumber(lives)
end

local function action_win_game()
	win_game()
	MP.GAME.won = true
end

local function action_lose_game()
	G.STATE_COMPLETE = false
	G.STATE = G.STATES.GAME_OVER
end

-- The list of lobby option keys to parse to numbers (Reversed for easy lookup of key existance)
local lobby_option_numbers = MP.UTILS.reverse_key_value_pairs({
	"starting_lives",
	"starting_money_modifier",
	"starting_hand_modifier",
	"starting_discard_modifier",
	"nano_br_nemesis_odd_money",
	"nano_br_potluck_score_multiplier",
})

local function action_lobby_options(options)
	local different_decks_before = MP.LOBBY.config.different_decks
	local br_mode_before = MP.LOBBY.config.nano_br_mode
	for k, v in pairs(options) do
		if k == "ruleset" then
			MP.LOBBY.config.ruleset = v
			goto continue
		end
		local parsed_v = v
		if v == "true" then
			parsed_v = true
		elseif v == "false" then
			parsed_v = false
		end

		if lobby_option_numbers[k] then
			parsed_v = tonumber(v)
		end

		MP.LOBBY.config[k] = parsed_v
		if G.OVERLAY_MENU then
			local config_uie = G.OVERLAY_MENU:get_UIE_by_ID(k .. "_toggle")
			if config_uie then
				G.FUNCS.toggle(config_uie)
			end

			local lobby_options = G.OVERLAY_MENU:get_UIE_by_ID("lobby_options_menu")
			if lobby_options then
				G.FUNCS.lobby_options();
			end
		end
		::continue::
	end
	if different_decks_before ~= MP.LOBBY.config.different_decks then
		G.FUNCS.exit_overlay_menu() -- throw out guest from any menu.
	end

	if not MP.LOBBY.is_started then
		MP.ACTIONS.update_player_usernames() -- render new DECK button state
	end

	if br_mode_before ~= MP.LOBBY.config.nano_br_mode then
		-- Handle mode switching
		if MP.LOBBY.config.nano_br_mode == "hivemind" then
			MP.ACTIONS.send_deck_type()
			MP.LOBBY.config.multiplayer_jokers = false
		end
	end
end

local function action_set_deck_type(back, sleeve, stake)
	if MP.LOBBY.config.different_decks then
		MP.LOBBY.deck.back = back
		MP.LOBBY.deck.sleeve = sleeve
		MP.LOBBY.deck.stake = tonumber(stake)


		-- Refresh UI
		if G.MAIN_MENU_UI then
			G.MAIN_MENU_UI:remove()
		end

		G.FUNCS.display_lobby_main_menu_UI()

		
		if G.OVERLAY_MENU then
			-- If a menu is open
			local lobby_options = G.OVERLAY_MENU:get_UIE_by_ID("lobby_options_menu")

			-- And that menu is NOT lobby options
			if not lobby_options then
				G.FUNCS.exit_overlay_menu()
			end
		end
	end
end

local function create_card_from_str(card_str)
	if card_str == "" then
		return
	end
	local card_params = MP.UTILS.string_split(card_str, "-")

	local id = card_params[1]

	local _suit = card_params[2]
	local _rank = card_params[3]
	
	local enhancement = card_params[4]
	local edition = card_params[5]
	local seal = card_params[6]

	local card = create_playing_card({front = G.P_CARDS[_suit..'_'.._rank], center = (enhancement == "none" and nil or G.P_CENTERS[enhancement])}, G.deck, true, true, nil, false)

	if edition and edition ~= "none" then
		local edition_object = {}
		edition_object[edition] = true

		card:set_edition(edition_object, true, true)
	end
	if seal ~= "none" then
		card:set_seal(seal, true, true)
	end

	card.mp_id = id
end

local function action_set_deck(deck_str)

	MP.GAME.setting_deck = true
	-- Clear current deck
	for _, card in ipairs(G.deck.cards) do
		card:remove_from_deck()
		if card.area then
			if card.highlighted then
				card.area:remove_from_highlighted(card, true)
			end

			card.area:remove_card(card)
		end
		card:remove()
	end
	G.deck.cards = {}

	for _, card in ipairs(G.discard.cards) do
		card:remove_from_deck()
		card.area:remove_card(card)
		card:remove()
	end
	G.discard.cards = {}

	for _, card in ipairs(G.hand.cards) do
		card:remove_from_deck()
		card.area:remove_card(card)
		card:remove()
	end
	G.hand.cards = {}

	for _, card in ipairs(G.play.cards) do
		card:remove_from_deck()
		card.area:remove_card(card)
		card:remove()
	end
	G.play.cards = {}

	-- Clear cards
	for _, card in ipairs(G.playing_cards) do
		card:remove_from_deck()
		card.area:remove_card(card)
		card:remove()
	end
	G.playing_cards = {}


	-- Add new cards
	local card_strings = MP.UTILS.string_split(deck_str, "|")

	for _, card_str in pairs(card_strings) do
		create_card_from_str(card_str)
	end

	MP.GAME.setting_deck = false
end

local function find_card_by_id(id)
	for _, card in pairs(G.deck.cards) do
		if card.mp_id == id then
			return card
		end
	end
	for _, card in pairs(G.discard.cards) do
		if card.mp_id == id then
			return card
		end
	end
	for _, card in pairs(G.hand.cards) do
		if card.mp_id == id then
			return card
		end
	end
	for _, card in pairs(G.play.cards) do
		if card.mp_id == id then
			return card
		end
	end

	return nil
end

local function action_add_card(temp_id, card_str)
	local card = find_card_by_id(temp_id)
	if not card then
		MP.GAME.setting_deck = true
		create_card_from_str(card_str)
		MP.GAME.setting_deck = false
	else
		card.mp_id = MP.UTILS.string_split(card_str, "-")[1]
	end
end

local function action_remove_card(id, retry_count)
	local card = find_card_by_id(id)

	-- Remove if the card is found and in a valid play area
	if card and card.area and card.area ~= G.play then
		MP.GAME.setting_deck = true
		card:remove_from_deck()
		card.area:remove_card(card)
		card:remove()
		MP.GAME.setting_deck = false
	else if not retry_count or retry_count < 10 then
		retry_count = retry_count or 0

		-- Increment the retry count if the card could not be found (AKA it is currently moving from one area to another)
		-- This is also how we prevent an infinite loop in a case where a client is told to delete a non-existent card.
		if not card or not card.area then
			retry_count = retry_count + 1
		end


		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.2,
			blockable = false,
			blocking = false,
			func = function()
				action_remove_card(id, retry_count)
				return true
			end
		}))
		end
	end
	return true
end

local function action_copy_card(from_id, to_id)
	local from_card = find_card_by_id(from_id)
	local to_card = find_card_by_id(to_id)
	if from_card and to_card then
		MP.GAME.setting_deck = true
		copy_card(from_card, to_card)
		MP.GAME.setting_deck = false
	end
end

local function action_set_card_suit(id, suit)
	local card = find_card_by_id(id)
	if card then
		local rank_suffix = card.base.id == 14 and 2 or math.min(card.base.id+1, 14)
		if rank_suffix < 10 then rank_suffix = tostring(rank_suffix)
		elseif rank_suffix == 10 then rank_suffix = 'T'
		elseif rank_suffix == 11 then rank_suffix = 'J'
		elseif rank_suffix == 12 then rank_suffix = 'Q'
		elseif rank_suffix == 13 then rank_suffix = 'K'
		elseif rank_suffix == 14 then rank_suffix = 'A'
		end

		MP.GAME.setting_deck = true
		card:set_base(G.P_CARDS[suit..'_'..rank_suffix])
		MP.GAME.setting_deck = false
	end
end

local function action_set_card_rank(id, rank)
	local card = find_card_by_id(id)
	if card then
		local suit_prefix = string.sub(card.base.suit, 1, 1)
		
		MP.GAME.setting_deck = true
		card:set_base(G.P_CARDS[suit_prefix..'_'..rank])
		MP.GAME.setting_deck = false
	end
end

local function action_set_card_enhancement(id, enhancement)
	local card = find_card_by_id(id)
	if card then
		MP.GAME.setting_deck = true
		card:set_ability(G.P_CENTERS[enhancement])
		MP.GAME.setting_deck = false
	end
end

local function action_set_card_edition(id, edition)
	local card = find_card_by_id(id)
	if card then
		MP.GAME.setting_deck = true
		if edition and edition ~= "none" then
			local edition_object = {}
			edition_object[edition] = true
	
			card:set_edition(edition_object, true, true)
		else 
			card:set_edition(nil, true, true)
		end
		MP.GAME.setting_deck = false
	end
end

local function action_set_card_seal(id, seal)
	local card = find_card_by_id(id)
	if card then
		MP.GAME.setting_deck = true
		
		if seal ~= "none" then
			card:set_seal(seal, true, true)
		else
			card:set_seal(nil, true, true)
		end

		MP.GAME.setting_deck = false
	end
end



local function action_set_hand_level(hand, level)
	if not G.GAME.hands[hand] or not level then
		return
	end
	if not G.GAME.hands[hand].visible then
		G.GAME.hands[hand].visible = true
	end

	level = tonumber(level)

	if not level then
		print("Could not parse level for hand")
		return
	end

	level_up_hand(nil, hand, true, level - G.GAME.hands[hand].level, true)
end

local function action_send_phantom(key)
	local new_card = create_card("Joker", MP.shared, false, nil, nil, nil, key)
	new_card:set_edition("e_mp_phantom")
	new_card:add_to_deck()
	MP.shared:emplace(new_card)
end

local function action_remove_phantom(key)
	local card = MP.UTILS.get_phantom_joker(key)
	if card then
		card:remove_from_deck()
		card:start_dissolve({ G.C.RED }, nil, 1.6)
		MP.shared:remove_card(card)
	end
end

local function action_speedrun()
	local function speedrun(card)
		card:juice_up()
		if #G.consumeables.cards < G.consumeables.config.card_limit then
			local card = create_card("Spectral", G.consumeables, nil, nil, nil, nil, nil, "speedrun")
			card:add_to_deck()
			G.consumeables:emplace(card)
		end
	end
	MP.UTILS.run_for_each_joker("j_mp_speedrun", speedrun)
end

local function enemyLocation(options)
	local location = options.location
	local value = ""

	if string.find(location, "-") then
		local split = {}
		for str in string.gmatch(location, "([^-]+)") do
			table.insert(split, str)
		end
		location = split[1]
		value = split[2]
	end

	if value == "bl_mp_nemesis" and MP.LOBBY.players[options.playerId] and MP.GAME.enemies[options.playerId].enemy_id and MP.LOBBY.players[MP.GAME.enemies[options.playerId].enemy_id] then
		value = MP.LOBBY.players[MP.GAME.enemies[options.playerId].enemy_id].username
	elseif value == "bl_mp_potluck" then
		value = localize("k_potluck")
	elseif value == "bl_mp_hivemind" then
		value = localize("k_hivemind")
	else
		loc_name = localize({ type = "name_text", key = value, set = "Blind" })
		if loc_name ~= "ERROR" then
			value = loc_name
		else
			value = (G.P_BLINDS[value] and G.P_BLINDS[value].name) or value
		end
	end

	loc_location = (value == "bl_mp_nemesis" or value == "bl_mp_hivemind") and localize("loc_fighting") or G.localization.misc.dictionary[location]

	if loc_location == nil then
		if location ~= nil then
			loc_location = location
		else
			loc_location = "Unknown"
		end
	end

	MP.GAME.enemies[options.playerId].location = loc_location .. value

	if MP.GAME.ready_blind and options.playerId == MP.LOBBY.enemy_id then
		MP.UI.show_enemy_location()
	end

end

local function action_version()
	MP.ACTIONS.version()
end

local action_asteroid = action_asteroid or function()
	local hand_type = "High Card"
	local max_level = 0
	for k, v in pairs(G.GAME.hands) do
		if to_big(v.level) > to_big(max_level) then
			hand_type = k
			max_level = v.level
		end
	end
	update_hand_text({ sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 }, {
		handname = localize(hand_type, "poker_hands"),
		chips = G.GAME.hands[hand_type].chips,
		mult = G.GAME.hands[hand_type].mult,
		level = G.GAME.hands[hand_type].level,
	})
	level_up_hand(nil, hand_type, false, -1, true)
	update_hand_text(
		{ sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
		{ mult = 0, chips = 0, handname = "", level = "" }
	)
end

local function action_sold_joker()
	local function juice_taxes(card)
		if card then
			card.ability.extra.mult = card.ability.extra.mult_gain + card.ability.extra.mult
			card:juice_up()
		end
	end
	MP.UTILS.run_for_each_joker("j_mp_taxes", juice_taxes)
end

local function action_lets_go_gambling_nemesis()
	local card = MP.UTILS.get_phantom_joker("j_mp_lets_go_gambling")
	if card then
		card:juice_up()
	end
	ease_dollars(MP.LOBBY.enemy_id and card and card.ability and card.ability.extra and card.ability.extra.nemesis_dollars or 5)
end

local function action_eat_pizza(whole)
	local function eat_whole(card)
		card:remove_from_deck()
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.2,
			func = function()
				attention_text({
					text = localize("k_eaten_ex"),
					scale = 0.6,
					hold = 1.4,
					major = card,
					backdrop_colour = G.C.FILTER,
					align = "bm",
					offset = {
						x = 0,
						y = 0,
					},
				})
				card:start_dissolve({ G.C.RED }, nil, 1.6)
				return true
			end,
		}))
	end

	whole = whole == "true"
	local card = MP.UTILS.get_joker("j_mp_pizza") or MP.UTILS.get_phantom_joker("j_mp_pizza")
	if card then
		if whole then
			eat_whole(card)
			return
		end
		card:juice_up()
		card.ability.extra.discards = card.ability.extra.discards - card.ability.extra.discards_loss
		if card.ability.extra.discards <= 0 then
			eat_whole(card)
			return
		end
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.2,
			func = function()
				attention_text({
					text = localize({
						type = "variable",
						key = "a_remaining",
						vars = { card.ability.extra.discards },
					}),
					scale = 0.6,
					hold = 1.4,
					major = card,
					backdrop_colour = G.C.RED,
					align = "bm",
					offset = {
						x = 0,
						y = 0,
					},
				})
				return true
			end,
		}))
	end
end

local function action_spent_last_shop(player_id, amount)
	MP.GAME.enemies[player_id].spent_last_shop = tonumber(amount)
end

local function action_magnet()
	local card = nil
	for _, v in pairs(G.jokers.cards) do
		if not card or v.sell_cost > card.sell_cost then
			card = v
		end
	end
	if card then
		MP.ACTIONS.magnet_response(card.config.center.key)
	end
end

local function action_magnet_response(key)
	local card = create_card("Joker", G.jokers, false, nil, nil, nil, key)
	card:add_to_deck()
	G.jokers:emplace(card)
end

local function action_receive_end_game_jokers(keys)
	if not MP.end_game_jokers or not keys or keys == "0" then
		return
	end

	local split_keys = {}
	for key in string.gmatch(keys, "([^;]+)") do
		table.insert(split_keys, key)
	end
	for i, key in pairs(split_keys) do
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.15 + (0.05 * i),
			func = function()
				local card = create_card("Joker", MP.end_game_jokers, false, nil, nil, nil, key)
				card:set_edition()
				card:add_to_deck()
				MP.end_game_jokers:emplace(card)
				return true
			end,
		}))
	end
end

local function action_get_end_game_jokers(reciever_id)
	if not G.jokers or not G.jokers.cards then
		Client.send("action:receiveEndGameJokers,recieverId:".. reciever_id ..",keys:")
		return
	end
	local jokers = G.jokers.cards
	local keys = ""
	for _, card in pairs(jokers) do
		keys = keys .. card.config.center.key .. ";"
	end
	Client.send(string.format("action:receiveEndGameJokers,recieverId:".. reciever_id ..",keys:%s", keys))
end

local function action_start_ante_timer(time)
	if type(time) == "string" then
		time = tonumber(time)
	end
	MP.GAME.timer = time
	MP.GAME.timer_started = true
	G.E_MANAGER:add_event(MP.timer_event)
end


local function action_set_score(score)
	if MP.GAME.calculating_hand and G.GAME.blind.in_blind then
		MP.GAME.score_offset = (to_big(MP.GAME.pre_calc_score) - G.GAME.chips) + (String_to_number(score) - G.GAME.chips)
	end

	G.E_MANAGER:add_event(Event({
		trigger = "immediate",
		blockable = false,
		blocking = false,
		func = function()
			if MP.GAME.score_waiting == true then
				if not (G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.HAND_PLAYED or G.STATE == G.STATES.DRAW_TO_HAND) then
					MP.GAME.score_waiting = false
				end
				return false
			end

			if not G.GAME.blind.in_blind or not (G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.HAND_PLAYED or G.STATE == G.STATES.DRAW_TO_HAND) then
				return true
			end

			MP.GAME.score_waiting = true
					
			-- Handle offset if local hand is still calculating

			G.E_MANAGER:add_event(Event({
				trigger = "immediate",
				blockable = false,
				blocking = false,
				func = function()
					if MP.GAME.calculating_hand then
						return false
					end
			
					G.E_MANAGER:add_event(Event({
						trigger = "after",
						delay = 0.05,
						blockable = false,
						blocking = false,
						func = function()
							MP.GAME.score_waiting = false

							if not G.GAME.blind.in_blind or not (G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.HAND_PLAYED or G.STATE == G.STATES.DRAW_TO_HAND) then
								return true
							end

							if String_to_number(score) > G.GAME.chips then
								G.GAME.chips = String_to_number(score)
							end
							MP.GAME.last_score = G.GAME.chips

							G.GAME.chips_text = tostring(G.GAME.chips)
							return true
						end
					}))
					return true
				end,
			}))
			return true
		end
	}))
end

local function action_give_money(amount)
	ease_dollars(math.floor(to_big(amount)))
end

local function skip_blind_internal()
	-- Unready if ready
	if MP.GAME.ready_blind then
		MP.GAME.ready_blind = false
		MP.GAME.ready_pvp_blind = false
		MP.GAME.ready_blind_text = MP.GAME.ready_blind and localize("b_unready") or localize("b_ready")

		MP.ACTIONS.set_location("loc_selecting")
		MP.ACTIONS.unready_blind()
	end


	local current_blind_id = G.GAME.blind_on_deck or "Small"

	if current_blind_id == "Boss" then
		return
	end

	local blind
	if current_blind_id == "Small" then
		blind = G.blind_select_opts.small
	else
		blind = G.blind_select_opts.big
	end


	if blind == nil then
		return
	end

	if not MP.GAME.timer_started then
		MP.GAME.timer = MP.GAME.timer + 120
	end

    stop_use()
    G.CONTROLLER.locks.skip_blind = true
    G.E_MANAGER:add_event(Event({
        no_delete = true,
        trigger = 'after',
        blocking = false,blockable = false,
        delay = 2.5,
        timer = 'TOTAL',
        func = function()
          G.CONTROLLER.locks.skip_blind = nil
          return true
        end
      }))
    local _tag = blind:get_UIE_by_ID('tag_container')
    G.GAME.skips = (G.GAME.skips or 0) + 1
    if _tag then
      add_tag(_tag.config.ref_table)
      local skipped, skip_to = G.GAME.blind_on_deck or 'Small',
      G.GAME.blind_on_deck == 'Small' and 'Big' or G.GAME.blind_on_deck == 'Big' and 'Boss' or 'Boss'
      G.GAME.round_resets.blind_states[skipped] = 'Skipped'
      G.GAME.round_resets.blind_states[skip_to] = 'Select'
      G.GAME.blind_on_deck = skip_to
      play_sound('generic1')
      G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
          delay(0.3)
          SMODS.calculate_context({skip_blind = true})
          save_run()
          for i = 1, #G.GAME.tags do
            G.GAME.tags[i]:apply_to_run({type = 'immediate'})
          end
          for i = 1, #G.GAME.tags do
            if G.GAME.tags[i]:apply_to_run({type = 'new_blind_choice'}) then break end
          end
          return true
        end
      }))
	else
		G.GAME.blind_on_deck = G.GAME.blind_on_deck == 'Small' and 'Big' or G.GAME.blind_on_deck == 'Big' and 'Boss' or 'Boss'
    end
end

local function action_skip_blind()
	if G.STATE == G.STATES.BLIND_SELECT then
		skip_blind_internal()
		return
	end

	MP.GAME.ready_blocker = true

	G.E_MANAGER:add_event(Event({
		trigger = "immediate",
		blocking = false,
		blockable = false,
		func = function()
			if G.STATE == G.STATES.BLIND_SELECT then
				G.E_MANAGER:add_event(Event({
					trigger = "after",
					delay = 0.7,
					blocking = false,
					blockable = false,
					func = function()
						skip_blind_internal()
						MP.GAME.ready_blocker = false
						return true
					end
				}))
				return true
			end
			return false
		end
	}))
end

-- #region Client to Server
function MP.ACTIONS.create_lobby(gamemode)
	MP.LOBBY.config.ruleset = gamemode
	Client.send(string.format("action:createLobby,gameMode:%s", gamemode))
end

function MP.ACTIONS.join_lobby(code)
	Client.send(string.format("action:joinLobby,code:%s", code))
end

function MP.ACTIONS.lobby_info()
	Client.send("action:lobbyInfo")
end

function MP.ACTIONS.leave_lobby()
	Client.send("action:leaveLobby")
end

function MP.ACTIONS.send_money_to_player(player_id, amount)
	Client.send(string.format("action:sendMoneyToPlayer,playerId:%s,amount:%s", player_id, amount))
end

function MP.ACTIONS.kick_player(player_id)
	Client.send(string.format("action:kickPlayer,playerId:%s", player_id))
end

function MP.ACTIONS.start_game()
	Client.send("action:startGame")
end

function MP.ACTIONS.set_team(team)
	Client.send(string.format("action:setTeam,teamId:%s", team))
end

function MP.ACTIONS.ready_blind(e)
	MP.GAME.next_blind_context = e
	if MP.is_key_pvp_blind(e.config.ref_table.key) then
		MP.GAME.ready_pvp_blind = true
	end
	Client.send(string.format("action:readyBlind,isPVP:%s", MP.is_key_pvp_blind(e.config.ref_table.key)))
end

function MP.ACTIONS.unready_blind()
	MP.GAME.ready_pvp_blind = false
	Client.send("action:unreadyBlind")
end

function MP.ACTIONS.return_to_lobby()
	Client.send("action:returnToLobby")
end

function MP.ACTIONS.fail_round(hands_used)
	if MP.LOBBY.config.no_gold_on_round_loss then
		MP.GAME.blind.dollars = 0
	end
	if hands_used == 0 then
		return
	end
	Client.send("action:failRound")
end

function MP.ACTIONS.version()
	Client.send(string.format("action:version,version:%s", MULTIPLAYER_VERSION))
end

function MP.ACTIONS.set_location(location)
	if MP.GAME.location == location then
		return
	end
	MP.GAME.location = location
	Client.send(string.format("action:setLocation,location:%s", location))
end

local function process_number(number)
	local fixed_score = tostring(number)

	-- Credit to sidmeierscivilizationv on discord for this fix for Talisman
	if string.match(fixed_score, "[eE]") == nil and string.match(fixed_score, "[.]") then
		-- Remove decimal from non-exponential numbers
		fixed_score = string.sub(string.gsub(fixed_score, "%.", ","), 1, -3)
	end
	fixed_score = string.gsub(fixed_score, ",", "") -- Remove commas

	return fixed_score
end

---@param score number
---@param hands_left number
function MP.ACTIONS.play_hand(score, hands_left)
	local fixed_score = process_number(to_big(score) + to_big(MP.GAME.score_offset))
	MP.GAME.score_offset = to_big(0)

	-- Do the same for the score delta
	if score < to_big(MP.GAME.last_score) then
		MP.GAME.last_score = 0
	end
	local score_delta = process_number(score - to_big(MP.GAME.last_score))
	MP.GAME.last_score = to_big(score)
	MP.GAME.calculating_hand = false

	local blind_chips = process_number(G.GAME.blind and G.GAME.blind.chips or 0)

	Client.send(string.format("action:playHand,score:" .. fixed_score .. ",scoreDelta:" .. score_delta .. ",blindChips:" .. blind_chips .. ",handsLeft:%d", hands_left))
end

function MP.ACTIONS.lobby_options()
	local msg = "action:lobbyOptions"
	for k, v in pairs(MP.LOBBY.config) do
		msg = msg .. string.format(",%s:%s", k, tostring(v))
	end
	Client.send(msg)
end


function MP.ACTIONS.send_deck_type()
	local back = MP.LOBBY.config.different_decks and MP.LOBBY.deck.back or MP.LOBBY.config.back
	local sleeve = MP.LOBBY.config.different_decks and MP.LOBBY.deck.sleeve or MP.LOBBY.config.sleeve
	local stake = MP.LOBBY.config.different_decks and MP.LOBBY.deck.stake or MP.LOBBY.config.stake

	Client.send(string.format("action:sendDeckType,back:%s,sleeve:%s,stake:%s", back, sleeve, stake))
end

-- Pre-compile a reversed list of all the centers
local reversed_centers = nil

local last_generated_id = ""

local function card_to_string(card, reroll_id)
	if not card or not card.base or not card.base.suit or not card.base.value then
		return ""
	end

	if not reversed_centers then
		reversed_centers = MP.UTILS.reverse_key_value_pairs(G.P_CENTERS)
	end

	local suit = card.base.suit
	local rank = card.base.value

	local enhancement = reversed_centers[card.config.center] or "none"
	local edition = card.edition and  MP.UTILS.reverse_key_value_pairs(card.edition, true)["true"] or "none"
	local seal = card.seal or "none"

	local card_str = suit .. "-" .. rank .. "-" .. enhancement .. "-" .. edition .. "-" .. seal

	local id
	if card.mp_id and not reroll_id then
		id = card.mp_id
	else
		id = "ID_" .. hash(card_str .. random_string(10, G.TIMERS.UPTIME) .. last_generated_id, 1000000)
		last_generated_id = id
		card.mp_id = id
	end

	return id .. ">" .. card_str
end

function MP.ACTIONS.send_deck()

	-- Gather all cards into a single string
	local deck_str = ""
	for _, card in ipairs(G.playing_cards) do
		if deck_str ~= "" then
			deck_str = deck_str .. "|"
		end

		deck_str = deck_str .. card_to_string(card)

		if string.len(deck_str) > 800 then
			Client.send(string.format("action:sendDeck,deck:%s", deck_str))
			deck_str = ""
		end
	end

	if string.len(deck_str) > 0 then
		Client.send(string.format("action:sendDeck,deck:%s", deck_str))
	end
end

function MP.ACTIONS.copy_card(from, to)
	if MP.is_team_based() and from.playing_card and to.playing_card then
		Client.send(string.format("action:copyCard,card:%s,target:%s", from.mp_id, to.mp_id))
	end
end

function MP.ACTIONS.set_card_suit(card, suit)
	if MP.is_team_based() and card.playing_card then
		Client.send(string.format("action:setCardSuit,card:%s,suit:%s", card.mp_id, suit))
	end
end

function MP.ACTIONS.set_card_rank(card, rank)
	if MP.is_team_based() and card.playing_card then
		Client.send(string.format("action:setCardRank,card:%s,rank:%s", card.mp_id, rank .. "-"))
	end
end

function MP.ACTIONS.set_card_enhancement(card, enhancement)
	if MP.is_team_based() and card.playing_card then
		Client.send(string.format("action:setCardEnhancement,card:%s,enhancement:%s", card.mp_id, enhancement))
	end
end

function MP.ACTIONS.set_card_edition(card, edition)
	if MP.is_team_based() and card.playing_card then
		Client.send(string.format("action:setCardEdition,card:%s,edition:%s", card.mp_id, edition))
	end
end

function MP.ACTIONS.set_card_seal(card, seal)
	if MP.is_team_based() and card.playing_card then
		Client.send(string.format("action:setCardSeal,card:%s,seal:%s", card.mp_id, seal))
	end
end

function MP.ACTIONS.add_card(card)
	if MP.is_team_based() and card.playing_card then
		Client.send(string.format("action:addCard,card:%s", card_to_string(card, true)))
	end
end

function MP.ACTIONS.remove_card(card)
	if MP.is_team_based() and card.playing_card then
		Client.send(string.format("action:removeCard,card:%s", card.mp_id))
	end
end

function MP.ACTIONS.change_hand_level(hand, amount)
	if MP.is_team_based() then
		Client.send(string.format("action:changeHandLevel,hand:%s,amount:%s", hand, amount))
	end
end


function MP.ACTIONS.set_ante(ante)
	Client.send(string.format("action:setAnte,ante:%d", ante))
end

function MP.ACTIONS.new_round()
	Client.send("action:newRound")
end

function MP.ACTIONS.skip(skips)
	Client.send("action:skip,skips:" .. tostring(skips))
end

function MP.ACTIONS.send_phantom(key)
	Client.send("action:sendPhantom,key:" .. key)
end

function MP.ACTIONS.remove_phantom(key)
	Client.send("action:removePhantom,key:" .. key)
end

function MP.ACTIONS.asteroid()
	Client.send("action:asteroid")
end

function MP.ACTIONS.sold_joker()
	Client.send("action:soldJoker")
end

function MP.ACTIONS.lets_go_gambling_nemesis()
	Client.send("action:letsGoGamblingNemesis")
end

function MP.ACTIONS.eat_pizza(whole)
	Client.send("action:eatPizza,whole:" .. tostring(whole and true))
end

function MP.ACTIONS.spent_last_shop(amount)
	Client.send("action:spentLastShop,amount:" .. tostring(amount))
end

function MP.ACTIONS.magnet()
	Client.send("action:magnet")
end

function MP.ACTIONS.magnet_response(key)
	Client.send("action:magnetResponse,key:" .. key)
end

function MP.ACTIONS.get_end_game_jokers()
	Client.send("action:getEndGameJokers")
end

function MP.ACTIONS.start_ante_timer()
	Client.send("action:startAnteTimer,time:" .. tostring(MP.GAME.timer))
end

function MP.ACTIONS.fail_timer()
	Client.send("action:failTimer")
end

-- #endregion Client to Server

-- Utils
function MP.ACTIONS.connect()
	Client.send("connect")
end

function MP.ACTIONS.update_player_usernames()
	if MP.LOBBY.code then
		if G.MAIN_MENU_UI then
			G.MAIN_MENU_UI:remove()
		end
		set_main_menu_UI()
	end
end

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
	game_update_ref(self, dt)

	repeat
		local msg = love.thread.getChannel("networkToUi"):pop()
		if msg then
			local parsedAction = MP.UTILS.string_to_table(msg, ",", ":")

			if not ((parsedAction.action == "keepAlive") or (parsedAction.action == "keepAliveAck")) then
				local log = string.format("Client got %s message: ", parsedAction.action)
				for k, v in pairs(parsedAction) do
					log = log .. string.format(" (%s: %s) ", k, v)
				end
				sendTraceMessage(log, "MULTIPLAYER")
			end

			if parsedAction.action == "connected" then
				action_connected()
			elseif parsedAction.action == "version" then
				action_version()
			elseif parsedAction.action == "disconnected" then
				action_disconnected()
			elseif parsedAction.action == "joinedLobby" then
				action_joinedLobby(parsedAction.code, parsedAction.type)
			elseif parsedAction.action == "lobbyInfo" then
				action_lobbyInfo(
					parsedAction.playerId,
					parsedAction.players,
					parsedAction.isStarted
				)
			elseif parsedAction.action == "kickedFromLobby" then
				action_kicked_from_lobby()
			elseif parsedAction.action == "startGame" then
				action_start_game(parsedAction.seed, parsedAction.stake)
			elseif parsedAction.action == "startBlind" then
				action_start_blind()
			elseif parsedAction.action == "enemyInfo" then
				action_enemy_info(
					parsedAction.playerId,
					parsedAction.enemyId,
					parsedAction.score,
					parsedAction.handsLeft,
					parsedAction.skips,
					parsedAction.lives
				)
			elseif parsedAction.action == "setPlayerTeam" then
				action_set_player_team(parsedAction.playerId, parsedAction.teamId)
			elseif parsedAction.action == "stopGame" then
				action_stop_game()
			elseif parsedAction.action == "endPvP" then
				action_end_pvp()
			elseif parsedAction.action == "endBlind" then
				action_end_blind()
			elseif parsedAction.action == "playerInfo" then
				action_player_info(parsedAction.lives)
			elseif parsedAction.action == "winGame" then
				action_win_game()
			elseif parsedAction.action == "loseGame" then
				action_lose_game()
			elseif parsedAction.action == "lobbyOptions" then
				action_lobby_options(parsedAction)
			elseif parsedAction.action == "enemyLocation" then
				enemyLocation(parsedAction)
			elseif parsedAction.action == "setDeckType" then
				action_set_deck_type(parsedAction.back, parsedAction.sleeve, parsedAction.stake)
			elseif parsedAction.action == "setDeck" then
				action_set_deck(parsedAction.deck)
			elseif parsedAction.action == "addCard" then
				action_add_card(parsedAction.tempId, parsedAction.card)
			elseif parsedAction.action == "removeCard" then
				action_remove_card(parsedAction.card)
			elseif parsedAction.action == "copyCard" then
				action_copy_card(parsedAction.card, parsedAction.target)
			elseif parsedAction.action == "setCardSuit" then
				action_set_card_suit(parsedAction.card, parsedAction.suit)
			elseif parsedAction.action == "setCardRank" then
				action_set_card_rank(parsedAction.card, parsedAction.rank)
			elseif parsedAction.action == "setCardEnhancement" then
				action_set_card_enhancement(parsedAction.card, parsedAction.enhancement)
			elseif parsedAction.action == "setCardEdition" then
				action_set_card_edition(parsedAction.card, parsedAction.edition)
			elseif parsedAction.action == "setCardSeal" then
				action_set_card_seal(parsedAction.card, parsedAction.seal)
			elseif parsedAction.action == "setHandLevel" then
				action_set_hand_level(parsedAction.hand, parsedAction.level)
			elseif parsedAction.action == "sendPhantom" then
				action_send_phantom(parsedAction.key)
			elseif parsedAction.action == "removePhantom" then
				action_remove_phantom(parsedAction.key)
			elseif parsedAction.action == "speedrun" then
				action_speedrun()
			elseif parsedAction.action == "asteroid" then
				action_asteroid()
			elseif parsedAction.action == "soldJoker" then
				action_sold_joker()
			elseif parsedAction.action == "letsGoGamblingNemesis" then
				action_lets_go_gambling_nemesis()
			elseif parsedAction.action == "eatPizza" then
				action_eat_pizza(parsedAction.whole)
			elseif parsedAction.action == "spentLastShop" then
				action_spent_last_shop(parsedAction.playerId, parsedAction.amount)
			elseif parsedAction.action == "magnet" then
				action_magnet()
			elseif parsedAction.action == "magnetResponse" then
				action_magnet_response(parsedAction.key)
			elseif parsedAction.action == "getEndGameJokers" then
				action_get_end_game_jokers(parsedAction.recieverId)
			elseif parsedAction.action == "receiveEndGameJokers" then
				action_receive_end_game_jokers(parsedAction.keys)
			elseif parsedAction.action == "startAnteTimer" then
				action_start_ante_timer(parsedAction.time)
			elseif parsedAction.action == "setScore" then
				action_set_score(parsedAction.score)
			elseif parsedAction.action == "giveMoney" then
				action_give_money(parsedAction.amount)
			elseif parsedAction.action == "skipBlind" then
				action_skip_blind()
			elseif parsedAction.action == "error" then
				action_error(parsedAction.message)
			elseif parsedAction.action == "message" then
				action_message(parsedAction.locKey)
			elseif parsedAction.action == "keepAlive" then
				action_keep_alive()
			end
		end
	until not msg
end
