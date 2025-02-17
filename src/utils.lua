MP.SHOW_DEBUG_MESSAGES = true

function MP.send_debug_message(message)
	if MP.SHOW_DEBUG_MESSAGES then
		sendDebugMessage(message_to_string(message), "MULTIPLAYER")
	end
end

function MP.send_warn_message(message)
	sendWarnMessage(message_to_string(message), "MULTIPLAYER")
end

function MP.send_error_message(message)
	sendErrorMessage(message_to_string(message), "MULTIPLAYER")
end

function MP.send_trace_message(message)
	if MP.SHOW_DEBUG_MESSAGES then
		sendTraceMessage(message_to_string(message), "MULTIPLAYER")
	end
end

function MP.send_info_message(message)
	sendInfoMessage(message_to_string(message), "MULTIPLAYER")
end

function MP.to_big(x, y)
	if to_big then
		return to_big(x, y)
	end
	return x
end

-- Credit: https://gist.github.com/tylerneylon/81333721109155b2d244
function MP.deep_copy(obj, seen)
	-- Handle non-tables and previously-seen tables.
	if type(obj) ~= "table" then
		return obj
	end
	if seen and seen[obj] then
		return seen[obj]
	end

	-- New table; mark it as seen and copy recursively.
	local s = seen or {}
	local res = {}
	s[obj] = res
	for k, v in pairs(obj) do
		res[MP.deep_copy(k, s)] = MP.deep_copy(v, s)
	end
	return setmetatable(res, getmetatable(obj))
end

function MP.is_pvp_boss()
	if not G.GAME or not G.GAME.blind then
		return false
	end
	for _, v in ipairs(MP.blinds) do
		if G.GAME.blind.config.blind.key == v then
			return true
		end
	end
	return false
end

function MP.value_is_pvp_boss(value)
	if not G.GAME or not G.GAME.blind then
		return false
	end
	for _, v in ipairs(MP.blinds) do
		if value == v then
			return true
		end
	end
	return false
end

-- Credit to Steamo (https://github.com/Steamopollys/Steamodded/blob/main/core/core.lua)
function MP.wrapText(text, maxChars)
	local wrappedText = ""
	local currentLineLength = 0

	for word in text:gmatch("%S+") do
		if currentLineLength + #word <= maxChars then
			wrappedText = wrappedText .. word .. " "
			currentLineLength = currentLineLength + #word + 1
		else
			wrappedText = wrappedText .. "\n" .. word .. " "
			currentLineLength = #word + 1
		end
	end

	return wrappedText
end

function MP.get_joker(key)
	if not G.jokers then
		return nil
	end
	for i = 1, #G.jokers.cards do
		if G.jokers.cards[i].ability.name == key then
			return G.jokers.cards[i]
		end
	end
	return nil
end

function MP.get_non_phantom_jokers()
	if not G.jokers or not G.jokers.cards then
		return {}
	end
	local jokers = {}
	for _, v in ipairs(G.jokers.cards) do
		if v.ability.set == "Joker" and (not v.edition or v.edition.type ~= "mp_phantom") then
			table.insert(jokers, v)
		end
	end
	return jokers
end

local ease_ante_ref = ease_ante
function ease_ante(mod)
	if not MPAPI.is_in_lobby() then
		return ease_ante_ref(mod)
	end
	-- Prevents easing multiple times at once
	if MP.game_state.antes_keyed[MP.game_state.ante_key] then
		return
	end
	MP.game_state.antes_keyed[MP.game_state.ante_key] = true
	G.E_MANAGER:add_event(Event({
		trigger = "immediate",
		func = function()
			G.GAME.round_resets.ante = G.GAME.round_resets.ante + mod
			check_and_set_high_score("furthest_ante", G.GAME.round_resets.ante)
			return true
		end,
	}))
end

function MP.add_event(event)
	G.E_MANAGER:add_event(event)
end
