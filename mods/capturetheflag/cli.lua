-- CLI stuff
minetest.register_privilege("team",{
	description = "Team manager",
})

minetest.register_chatcommand("team", {
	description = "Open the team console",
	func = function(name, param)
		local test =  string.match(param,"player (.-)")
		if test then
			print("is a player request "..test)
				
			if cf.player(test) then
				if cf.player(test).team then
					if cf.player(test).auth then
						minetest.chat_send_player(name,test.." is in team "..cf.player(test).team.." (team owner)",false)
					else
						minetest.chat_send_player(name,test.." is in team "..cf.player(test).team,false)
					end
				else
					minetest.chat_send_player(name,test.." is not in a team",false)
				end
			end
		elseif cf.team(param) then
			minetest.chat_send_player(name,"Team "..param..":",false)
			local count = 0
			for _,value in pairs(cf.team(param).players) do
				count = count + 1
				if value.aut == true then
					minetest.chat_send_player(name,count..">> "..value.name.." (team owner)",false)
				else
					minetest.chat_send_player(name,count..">> "..value.name,false)
				end
			end
		elseif 
			cf and
			cf.players and
			cf.players[name] and
			cf.players[name].team and
			cf.setting("gui")
		then
			if cf.setting("team_gui_initial") == "news" and cf.setting("news_gui") then
				cf.gui.team_board(name,cf.players[name].team)
			elseif cf.setting("team_gui_initial") == "flags" and cf.setting("flag_teleport_gui") then
				cf.gui.team_flags(name,cf.players[name].team)
			elseif cf.setting("team_gui_initial") == "diplo" and cf.setting("diplomacy") then
				cf.gui.team_dip(name,cf.players[name].team)
			elseif cf.setting("team_gui_initial") == "admin" then
				cf.gui.team_settings(name,cf.players[name].team)
			elseif cf.setting("news_gui") then
				cf.gui.team_board(name,cf.players[name].team)			
			end
		end
	end,
})

minetest.register_chatcommand("join", {
	params = "team name",
	description = "Add to team",
	func = function(name, param)
		local player = cf.player(name)
		
		if not player then
			player = {name=name}
		end

		if cf.add_user(param,player) == true then
			minetest.chat_send_all(name.." has joined team "..param)
		end
	end,
})
minetest.register_chatcommand("list_teams", {
	params = "",
	description = "List all avaliable teams",
	func = function(name, param)
		minetest.chat_send_player(name, "Teams:")
		for k,v in pairs(cf.teams) do
			if v and v.players then
				local numItems = 0
				for k,v in pairs(v.players) do
				    numItems = numItems + 1
				end
				local numItems2 = 0
				for k,v in pairs(v.flags) do
				    numItems2 = numItems2 + 1
				end
				minetest.chat_send_player(name, ">> "..k.." ("..numItems2.." flags, "..numItems.." players)")
			end
		end                                                                         
	end,
})

minetest.register_chatcommand("ateam", {
	params = "team name",
	description = "Create a team",
	privs = {team=true},
	func = function(name, param)
		if string.match(param,"([%a%b_]-)") and cf.team({name=param,add_team=true}) then
			minetest.chat_send_player(name, "Added team "..param)
		else
			minetest.chat_send_player(name, "Error adding team "..param)
		end
	end,
})

minetest.register_chatcommand("ctf", {
	description = "Do admin debug stuff",
	privs = {team=true},
	func = function(name, param)
		cf.clean_flags()
		cf.clean_player_lists()
	end,
})

minetest.register_chatcommand("reload_ctf", {
	description = "reload the ctf main frame and get settings",
	privs = {team=true},
	func = function(name, param)
		cf.save()
		cf.init()
	end,
})

minetest.register_chatcommand("team_owner", {
	params = "player name",
	description = "Create a team",
	privs = {team=true},
	func = function(name, param)
		if cf and cf.players and cf.player(param) and cf.player(param).team and cf.team(cf.player(param).team) then
			if cf.player(param).auth == true then
				cf.player(param).auth = false
				minetest.chat_send_player(name, param.." was downgraded from team admin status")
			else
				cf.player(param).auth = true
				minetest.chat_send_player(name, param.." was upgraded to an admin of "..cf.player(name).team)
			end
			cf.save()
		else
			minetest.chat_send_player(name, "Player "..param.." does not exist")
		end
	end,
})

minetest.register_chatcommand("all", {
	params = "msg",
	description = "Send a message on the global channel",
	func = function(name, param)
		if not cf.setting("global_channel") then
			minetest.chat_send_player(name,"The global channel is disabled")
			return
		end

		if cf.player(name) and cf.player(name).team then
			minetest.chat_send_all(cf.player(name).team.." <"..name.."> "..param)
		else
			minetest.chat_send_all("GLOBAL <"..name.."> "..param)
		end

	end,
})

minetest.register_chatcommand("post", {
	params = "message",
	description = "Post a message on your team's message board",
	func = function(name, param)

		if cf and cf.players and cf.players[name] and cf.players[name].team and cf.teams[cf.players[name].team] then
			if not cf.player(name).auth then
				minetest.chat_send_player(name, "You do not own that team")
			end

			if not cf.teams[cf.players[name].team].log then
				cf.teams[cf.players[name].team].log = {}
			end

			table.insert(cf.teams[cf.players[name].team].log,{msg=param})

			minetest.chat_send_player(name, "Posted: "..param)
		else
			minetest.chat_send_player(name, "Could not post message")
		end
	end,
})

-- Chat plus stuff
if chatplus then
	chatplus.register_handler(function(from,to,msg)
		if not cf.setting("team_channel") then
			return nil
		end

		local fromp = cf.player(from)
		local top = cf.player(to)

		if not fromp then
			if not cf.setting("global_channel") then
				minetest.chat_send_player(from,"You are not yet part of a team, so you have no mates to send to",false)
			else
				minetest.chat_send_player(to,"GLOBAL <"..from.."> "..msg,false)
			end
			return false
		end
		
		if not top then
			return false
		end

		return (fromp.team == top.team)
	end)
end