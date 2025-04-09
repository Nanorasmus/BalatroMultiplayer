if next(SMODS.find_mod("AntePreview")) then
    sendDebugMessage("Next Ante Preview compatibility detected", "MULTIPLAYER")
    local predict_next_ante_ref = predict_next_ante
    function predict_next_ante()
        local predictions = predict_next_ante_ref()
        if MP.LOBBY.code then
            if G.GAME.round_resets.ante > 1 then
                if MP.LOBBY.config.nano_br_mode == "nemesis" then
                    predictions.Boss.blind = "bl_mp_nemesis"
                elseif MP.LOBBY.config.nano_br_mode == "potluck" then
                    predictions.Boss.blind = "bl_mp_potluck"
                elseif MP.LOBBY.config.nano_br_mode == "hivemind" then
                    predictions.Boss.blind = "bl_mp_hivemind"
                end
            end
        end
        return predictions
    end
end
