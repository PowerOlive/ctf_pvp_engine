ctf.register_on_init(function()
	ctf._set("endgame.destroy_team",       true)
	ctf._set("endgame.break_alliances",    true)
	ctf._set("endgame.reset_on_winner",    true)
end)

ctf_flag.register_on_capture(function(attname, flag)
	if not ctf.setting("endgame.destroy_team") then
		return
	end

	local fl_team = ctf.team(flag.team)
	if fl_team and #fl_team.flags == 0 then
		ctf.action("endgame", flag.team .. " was defeated.")
		ctf.remove_team(flag.team)
		minetest.chat_send_all(flag.team .. " has been defeated!")
	end

	if ctf.setting("endgame.reset_on_winner") then
		local winner = nil
		for name, team in pairs(ctf.teams) do
			if winner then
				return
			end
			winner = name
		end

		-- Only one team left!
		ctf.action("endgame", winner .. " won!")
		minetest.chat_send_all("Team " .. winner .. " won!")
		minetest.chat_send_all("Resetting the map, this may take a few moments...")
		minetest.after(0.5, function()
			ctf.reset()
			minetest.delete_area(vector.new(-16*2, -16*2, -16*2), vector.new(16*2, 16*2, 16*2))
			ctf.team({name="red", color="red", add_team=true})
			ctf.team({name="blue", color="blue", add_team=true})
			for name, player in pairs(ctf.players) do
				local alloc_mode = tonumber(ctf.setting("allocate_mode"))
				if alloc_mode == 0 then
					return
				end
				local team = ctf.autoalloc(name, alloc_mode)
				if team then
					ctf.log("autoalloc", name .. " was allocated to " .. team)
					ctf.join(name, team)
				end
			end
		end)
	end
end)