-- Localization by @themike_71
-- Corrections by ElTioRata
return {
	descriptions = {
		Joker = {
			j_mp_defensive_joker = {
				name = "Comodín defensivo",
				text = {
					"Este comodín gana {C:chips}+#1#{} fichas",
					"por {C:red,E:1}vida{} perdida esta ronda",
					"{C:inactive}(Cantidad actual: {C:chips}+#2#{C:inactive} fichas)",
				},
			},
			j_mp_skip_off = {
				name = "Avioncito",
				text = {
					"{C:blue}+#1#{} Manos y {C:red}+#2#{} descartes",
					"por {C:attention}ciega{} adicional omitida",
					"en comparación con tu {X:purple,C:white}némesis{}",
					"{C:inactive}(Cantidad actual: {C:blue}+#3#{C:inactive}/{C:red}+#4#{C:inactive}, #5#)",
				},
			},
			j_mp_lets_go_gambling = {
				name = "Let's Go Gambling",
				text = {
					"Cuando se vende, {C:green}#1# en #2#{} probabilidades",
					"de ser destruida, si no se destruye gana {X:mult,C:white} +X#3# {}",
					"{C:inactive}(Aumenta {X:mult,C:white}+X#4#{C:inactive} cuando derrotas a la {C:attention}ciega jefe{C:inactive})",
					"{C:inactive}(Cantidad actual: {X:mult,C:white}X#5#{C:inactive} multi)",
				},
			},
			j_mp_hanging_bad = {
				name = "Tirando mal",
				text = {
					"Durante las {C:attention}ciegas{} contra tu {X:purple,C:white}némesis{}",
					"la {C:attention}primera{} carta jugada que anote queda",
					"{C:attention}debilitada{} para ambos jugadores",
				},
			},
			j_mp_speedrun = {
				name = "SPEEDRUN",
				text = {
					"Si gastas todas tus {C:blue}manos{} antes que",
					"tu {X:purple,C:white}némesis{} en una {C:attention}ciega JcJ{},",
					"{C:attention}triplicas{} tu puntuación total",
				},
			},
			j_broken = {
				name = "ERROR :(",
				text = {
					"Esta carta está rota o no está",
					"implementada en la versión actual",
					"de un mod que estás usando.",
				},
			},
		},
		Planet = {
			c_mp_asteroid = {
			name = "Asteroide",
			text = {
				"Disminuye #1# nivel de la",
				"{C:legendary,E:1}mano de póker{}",
				"con mayor nivel",
				"de tu {X:purple,C:white}némesis{}",
				},
			},
		},
		Blind = {
			bl_mp_nemesis = {
				name = "Tu némesis",
				text = {
					"Tú contra tu propio némesis,", -- Changed as of 1.0
					"quien tenga más fichas gana",
				},
			},
			-- New as of 1.0
			bl_mp_precision = {
				name = "La marca",
				text = {
					"Enfréntate a otro jugador,",
					"el más cercano al objetivo gana",
				},
			},
			bl_mp_horde = {
				name = "La horda",
				text = {
					"Pelea contra todos los jugadores,",
					"el puntaje más bajo pierde",
				},
			},
			bl_mp_truce = {
				name = "La tregua",
				text = {
					"Copia #1#,",
					"no mueras",
				},
			},
		},
		Gamemode = {
			gamemode_mp_attrition = {
				name = "Desgaste",
				text = {
					"Pelea 1 a 1 contra tu {X:purple,C:white}Némesis{},",
					"El jugador con menos puntos",
					"pierde una vida.",
					"{C:inactive}--", -- Lives text
					"{C:red}4 vidas",
					"{C:inactive}--", -- Other
					"{C:inactive}Tu {X:purple,C:white}némesis{C:inactive} cambia cada ciega.{}",
				},
			},
			gamemode_mp_battle_royale = {
				name = "Batalla campal",
				text = {
					"Pelea contra todos los jugadores restantes",
					"en cada ciega jefe. El jugador con",
					"la menor puntuación pierde una vida.",
					"{C:inactive}--", -- Lives text
					"{C:red}2-4 vidas{C:inactive}, dependiendo la cantidad de jugadores",
					"{C:inactive}--", -- Other
					"{C:inactive}Con 5 jugadores o más, los últimos 2 pierden una vida",
				},
			},
			gamemode_mp_precision = {
				name = "Precisión",
				text = {
					"Pelea contra todos los jugadores restantes ",
					"en cada ciega jefe. El jugador con la ",
					"puntuación más lejana al blanco pierde una vida",
					"{C:inactive}--", -- Lives text
					"{C:red}2-4 vidas{C:inactive}, dependiendo la cantidad de jugadores",
					"{C:inactive}--", -- Other
					"{C:inactive}Con 5 jugadores o más, los últimos 2 pierden una vida",
				},
			},
			gamemode_mp_speedrun = {
				name = "Speedrun",
				text = {
					"El primer jugador en vencer la ciega 8",
					"gana. No hay vidas ni reinicios al perder",
					"1 a 1 con diferentes semillas",
					"{C:inactive}--", -- Lives text
					"{C:red}Gana o pierde{}",
					"{C:inactive}--", -- Other
					"{C:inactive}Misma semilla, los jugadores estarán en la misma semilla",
				},
			},
		},
		Edition = {
			e_mp_phantom = {
				name = "Fantasma",
				text = {
					"{C:attention}Eternos{} y {C:dark_edition}negativos{}",
					"Creados y destruidos por tu {X:purple,C:white}némesis{}",
				},
			},
		},
		Other = {
			current_nemesis = {
				name = "Némesis",
				text = {
					"{X:purple,C:white}#1#{}",
					"Tu propio némesis",
				},
			},
		},
	},
	misc = {
		labels = {
			mp_phantom = "Fantasma",
		},
		challenge_names = {
			c_multiplayer_1 = "Multijugador",
		},
		dictionary = {
			singleplayer = "Un jugador",
			join_lobby = "Unirse a sala",
			return_lobby = "Regresar a sala",
			reconnect = "Reconectar",
			create_lobby = "Crear sala",
			start_lobby = "Iniciar sala",
			coming_soon = "¡Próximamente!",
			ready = "Listo",
			unready = "No listo",
			wait_enemy = "Esperando contrincante...",
			lives = "Vidas",
			leave_lobby = "Abandonar sala",
			lost_life = "-1 a vida",
			failed = "Falló",
			defeat_enemy = "Contrincante derrotado",
			total_lives_lost = " Vidas totales perdidas ($4 cada una)",
			attrition_name = "Atrición",
			attrition_desc = "Cada ronda de jefe es una competencia entre jugadores donde el que tenga la puntuación más baja pierde una vida.",
			showdown_name = "Confrontación",
			showdown_desc = "Ambos jugadores juegan 3 apuestas normales, luego deben seguir superando la puntuación anterior del oponente cada ronda.",
			draft_name = "Borrador",
			draft_desc = "Se jugará con el mazo evolutivo del mod Balatro Draft, donde se consigue una Draft Tag (etiqueta) después de la ciega PvP.",
			draft_req = "Requiere el mod Balatro Draft",
			monty_special_name = "El especial del Dr. Monty",
			monty_special_desc = "Modo especial diseñado por @dr_monty_the_snek en nuestro Discord. ¡Supongo que tendrás que jugar para averiguar de qué trata! (el modo cambia en cada actualización)",
			precision_name = "Precisión",
			precision_desc = "Es como Atrición, pero gana quien se acerque al puntaje marcado (en vez del mayor puntaje).",
			royale_name = "Batalla camapl",
			royale_desc = "Atrición, excepto que con 8 jugadores con 1 sola vida.",
			vanilla_plus_name = "Vanilla+",
			vp_desc = "El primero que falle una ronda pierde, no hay ciegas JcJ.",
			enter_lobby_code = "Agregar código de sala",
			join_clip = "Pegar desde el portapapeles",
			username = "Nombre de usuario:",
			enter_username = "Agregar nombre de usuario",
			join_discord = "Únete a nuestro Discord ",
			discord_name = "Discord de multijugador de Balatro",
			discord_msg = "Puedes reportar errores y encontrar más jugadores allí",
			enter_to_save = "Presiona ENTER para guardar cambios",
			in_lobby = "En sala",
			connected = "Conectado al servidor",
			warn_service = "ADVERTENCIA: No se encontró el servidor multijugador",
			set_name = "¡Agrega tu usuario en el menú! (Mods > Multijugador > Configuración)",
			start = "INICIAR",
			wait_for = "ESPERANDO AL",
			host_start = "ANFITRIÓN PARA INICIAR",
			players = "JUGADORES",
			lobby_options_cap = "OPCIONES DE SALA",
			lobby_options = "Opciones del sala",
			copy_clipboard = "Copiar desde el portapapeles",
			connect_player = "Jugadores conectados:",
			opts_only_host = "Solo el anfitrión puede modificar esta opción",
			opts_cb_money = "Recibe oro al perder una vida",
			opts_no_gold_on_loss = "Sin recompensa al perder una ronda",
			opts_death_on_loss = "Pierde una vida por ronda no-JcJ",
			opts_start_antes = "Iniciando ciega",
			opts_diff_seeds = "Los jugadores estan en diferentes semillas",
			opts_lives = "Vidas",
			opts_gm = "Opciones del modo de juego",
			bl_or = "o",
			bl_life = "Vive",
			bl_death = "muere",
			loc_ready = "Listo para JcJ",
			loc_selecting = "Eligiendo ciega",
			loc_shop = "En la tienda",
			loc_playing = "Jugando ",
			current_seed = "Semilla actual: ",
			random = "Al azar",
			reset = "Reiniciar",
			set_custom_seed = "Agregar semilla",
			mod_hash_warning = "¡Los jugadores tienen diferentes mods o diferentes versiones de mods! ¡Esto puede causar problemas!",
			lobby_choose_deck = "MAZO",
			opts_player_diff_deck = "Los jugadores tienen diferentes mazos",
			-- New as of 1.0
			page_title_lobby = "Sala",
			page_title_gamemode = "Elegir modo de juego",
			lobby_host = "Anfitrión",
			lobby_member = "Miembro",
			lobby_spectator = "Espectador",
			lobby_deck = "Mazo de sala",
			b_open_lobby = "Crear sala",
			b_join_lobby = "Unirse a sala",
			not_connected = "No se encontró servidor",
			b_reconnect = "Reconectar",
			b_copy_code = "Copiar código",
			b_return_to_lobby = "Regresar a sala",
			b_leave_lobby = "Abandonar sala",
			k_enter_code = "Agregar código",
			k_planetesimal = "Planetesimal",
			consider_supporting = "Este mod está hecho por una persona, si quieres apoyar el desarrollo puedes considerar",
			kofi_name = "donar en Ko-Fi",
			new_host = "El anfitrión abandonó la sala, Ahora eres el anfitrión. Se ha cambiado el código",
			enemy_loc = { "Contrincante", "Ubicación" },
			return_to_lobby_split = { "regresar a", "sala" },
			leave_lobby_split = { "Abandonar", "sala" },
			k_bl_mp_nemesis_score_text = "Puntuación del némesis:",
			k_bl_mp_nemesis_secondary_text = "Manos restantes: ",
			k_bl_mp_horde_score_text = "Puntuación a superar:",
			k_bl_mp_horde_secondary_text = "Clasificación actual: ",
			k_bl_mp_precision_score_text = "Puntuación marcada",
			k_bl_mp_precision_secondary_text = "Clasificación actual: ",
			k_gamemode = "Modo de juego",
		},
		v_dictionary = {
			mp_art = { "Arte: #1#" },
			mp_code = { "Código: #1#" },
			mp_idea = { "Idea: #1#" },
			mp_skips_ahead = { "#1# Omisiones por delante" },
			mp_skips_behind = { "#1# Omisiones por detrás" },
			mp_skips_tied = { "Empatadas" },
			a_xmult_plus = "+X#1# Multi",
		},
	},
}
