MP = SMODS.current_mod
MP.LOBBY = {
	connected = false,
	temp_code = "",
	temp_seed = "",
	code = nil,
	type = "",
	config = {
		gold_on_life_loss = true,
		no_gold_on_round_loss = false,
		death_on_round_loss = true,
		different_seeds = false,
		starting_lives = 4,
		starting_money_modifier = 0,
		starting_hand_modifier = 0,
		starting_discard_modifier = 0,
		showdown_starting_antes = 3,
		ruleset = "ruleset_mp_standard",
		custom_seed = "random",
		different_decks = false,
		back = "Red Deck",
		sleeve = "sleeve_casl_none",
		stake = 1,
		multiplayer_jokers = true,
		nano_battle_royale = true,
		nano_br_mode = "nemesis",
		nano_br_nemesis_odd_money = 0,
		nano_br_potluck_score_multiplier = 1.0,
		nano_br_hivemind_transfer_tax = 1,
	},
	deck = {
		back = "Red Deck",
		sleeve = "sleeve_casl_none",
		stake = 1,
	},
	username = "Guest",
	player_id = "",
	enemy_id = nil,
	team_id = "RED",
	players = {},
	player_count = 0,
	is_host = false,
	is_started = false,
}
MP.GAME = {}
MP.UI = {}
MP.ACTIONS = {}

G.C.MULITPLAYER = HEX("AC3232")

function MP.load_mp_file(file)
	local chunk, err = SMODS.load_file(file, "NanoMultiplayer")
	if chunk then
		local ok, func = pcall(chunk)
		if ok then
			return func
		else
			sendWarnMessage("Failed to process file: " .. func, "MULTIPLAYER")
		end
	else
		sendWarnMessage("Failed to find or compile file: " .. tostring(err), "MULTIPLAYER")
	end
	return nil
end

function MP.load_mp_dir(directory)
	local files = NFS.getDirectoryItems(MP.path .. "/" .. directory)
	local regular_files = {}

	for _, filename in ipairs(files) do
		local file_path = directory .. "/" .. filename
		if file_path:match(".lua$") then
			if filename:match("^_") then
				MP.load_mp_file(file_path)
			else
				table.insert(regular_files, file_path)
			end
		end
	end

	for _, file_path in ipairs(regular_files) do
		MP.load_mp_file(file_path)
	end
end

MP.load_mp_file("misc/utils.lua")
MP.load_mp_file("misc/insane_int.lua")

function MP.reset_game_states()
	sendDebugMessage("Resetting game states", "MULTIPLAYER")
	MP.GAME = {
		ready_blind = false,
		ready_blind_text = localize("b_ready"),
		processed_round_done = false,
		lives = 0,
		loaded_ante = 0,
		loading_blinds = false,
		comeback_bonus_given = true,
		comeback_bonus = 0,
		end_pvp = false,
		can_blind_end = false,
		enemies = {}, 
		location = "loc_selecting",
		next_blind_context = nil,
		ante_key = tostring(math.random()),
		antes_keyed = {},
		prevent_eval = false,
		misprint_display = "",
		spent_total = 0,
		spent_before_shop = 0,
		global_highest_score = MP.INSANE_INT.empty(),
		timer = 120,
		timer_started = false,
		last_score = 0,
		pre_calc_score = 0,
		calculating_hand = false,
		score_offset = 0,
		setting_deck = false,
	}

	MP.GAME.enemies = {}

	for k, player in pairs(MP.LOBBY.players) do
		MP.GAME.enemies[player.id] = {
			enemy_id = nil,
			score = MP.INSANE_INT.empty(),
			highest_score = MP.INSANE_INT.empty(),
			score_text = "0",
			hands = 4,
			location = "Selecting a Blind",
			skips = 0,
			lives = 4,
			sells = 0,
			spent_last_shop = 0,
		}
	end

	-- Used for enemy scores not owned by a particular player
	MP.GAME.enemies["house"] = {
		enemy_id = nil,
		score = MP.INSANE_INT.empty(),
		highest_score = MP.INSANE_INT.empty(),
		score_text = "0",
		hands = 4,
		location = "Always winning",
		skips = 0,
		lives = 4,
		sells = 0,
		spent_last_shop = 0,
	}
end

MP.reset_game_states()

MP.LOBBY.username = MP.UTILS.get_username()

if not SMODS.current_mod.lovely then
	G.E_MANAGER:add_event(Event({
		no_delete = true,
		trigger = "immediate",
		blockable = false,
		blocking = false,
		func = function()
			if G.MAIN_MENU_UI then
				MP.UTILS.overlay_message(
					MP.UTILS.wrapText(
						"Your Multiplayer Mod is not loaded correctly, make sure the Multiplayer folder does not have an extra Multiplayer folder around it.",
						50
					)
				)
				return true
			end
		end,
	}))
	return
end

SMODS.Atlas({
	key = "modicon",
	path = "modicon.png",
	px = 34,
	py = 34,
})

MP.load_mp_dir("compatibility")

MP.load_mp_file("networking/action_handlers.lua")

MP.load_mp_dir("objects/editions")
MP.load_mp_dir("objects/stickers")
MP.load_mp_dir("objects/blinds")
MP.load_mp_dir("objects/decks")
MP.load_mp_dir("objects/jokers")
MP.load_mp_dir("objects/consumables")
MP.load_mp_dir("gamemodes")
MP.load_mp_dir("rulesets")

MP.load_mp_dir("ui/components")
MP.load_mp_dir("ui")

MP.load_mp_file("misc/disable_restart.lua")
MP.load_mp_file("misc/mod_hash.lua")

local SOCKET = MP.load_mp_file("networking/socket.lua")
MP.NETWORKING_THREAD = love.thread.newThread(SOCKET)
MP.NETWORKING_THREAD:start(SMODS.Mods["NanoMultiplayer"].config.server_url, SMODS.Mods["NanoMultiplayer"].config.server_port)
MP.ACTIONS.connect()
