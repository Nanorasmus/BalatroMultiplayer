if SMODS.Mods["Distro"] and SMODS.Mods["Distro"].can_load then
	G.E_MANAGER:add_event(Event({
		trigger = "immediate",
		no_delete = true,
		blockable = false,
		blocking = false,
		timer = "REAL",
		func = function()
			if DiscordIPC and DiscordIPC.send_activity then
				local send_activity_ref = DiscordIPC.send_activity
				DiscordIPC.send_activity = function(bypass_block)
					if MP.LOBBY.code and not bypass_block then
						return
					end
					send_activity_ref()
				end
				return true
			end
		end,
	}))

	function get_multiplayer_details()
		local enemy_username = "The House"
		if MP.LOBBY.enemy_id then
			enemy_username = MP.LOBBY.players[MP.LOBBY.enemy_id].username
		end

		return "Multiplayer Versus " .. enemy_username .. " | " .. tostring(MP.GAME.lives) .. " Lives Left"
	end

	local start_run_ref = Game.start_run
	function Game:start_run(args)
		start_run_ref(self, args)

		if MP.LOBBY.code then
			local back_key, back_name = Distro.get_back_name()
			local stake_key, stake_name = Distro.get_stake_name()

			DiscordIPC.activity = {
				details = get_multiplayer_details(),
				state = "Selecting Blind",
				timestamps = {
					start = os.time() * 1000,
				},
				assets = {
					large_image = back_key,
					large_text = back_name,
					small_image = stake_key,
					small_text = stake_name,
				},
			}

			DiscordIPC.send_activity(true)
		end
	end

	local update_selecting_hand_ref = Game.update_selecting_hand
	function Game:update_selecting_hand(dt)
		if not G.STATE_COMPLETE then
			if MP.LOBBY.code then
				DiscordIPC.activity.details = get_multiplayer_details()
				DiscordIPC.activity.state = G.GAME.current_round.hands_left
					.. " Hands, "
					.. G.GAME.current_round.discards_left
					.. " Discards left"
				DiscordIPC.send_activity(true)
			end
		end

		update_selecting_hand_ref(self, dt)
	end

	local update_shop_ref = Game.update_shop
	function Game:update_shop(dt)
		if not G.STATE_COMPLETE then
			if MP.LOBBY.code then
				DiscordIPC.activity.details = get_multiplayer_details()
				DiscordIPC.activity.state = "Shopping"
				DiscordIPC.send_activity(true)
			end
		end

		update_shop_ref(self, dt)
	end

	local main_menu_ref = Game.main_menu
	function Game:main_menu(change_context)
		main_menu_ref(self, change_context)

		if MP.LOBBY.code then
			DiscordIPC.activity = {
				details = MP.LOBBY.player_count > 1 and "In Multiplayer Lobby with " .. MP.LOBBY.player_count - 1 .. "other players" or "In Multiplayer Lobby",
				timestamps = {
					start = os.time() * 1000,
				},
				assets = {
					large_image = "default",
				},
			}
			DiscordIPC.send_activity(true)
		end
	end
end
