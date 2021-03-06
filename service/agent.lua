local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"

local agent = {}
local data = {}
local cli = client.handler()

function cli:ping()
	--assert(self.login)
	log "ping"
end

function cli:login()
	assert(not self.login)
	if data.fd then
		log("login fail %s fd=%d", data.userid, self.fd)
		return { ok = false }
	end
	data.fd = self.fd
	self.login = true
	log("login succ %s fd=%d", data.userid, self.fd)
	client.push(self, "push", { text = "welcome" })	-- push message to client
	return { ok = true }
end

function cli:createRoom()
	if not self.login then
		return {ok = false}
	end
	if self.room then
		log("create room fail room is exist %d",self.room)
		return {ok = false}
	end
	log("self:%d",skynet.self())
	local result,room,player_index = skynet.call(service.room_mgr, "lua", "createRoom", skynet.self())
	if result then
		self.room = room
	end
	return {ok = result,player_index = player_index}
end

function cli:addRobot()
	if not self.login then
		return {ok = false}
	end

	if not self.room then
		return {ok = false}
	end
	skynet.send(self.room,"lua","addRobot")

	return {ok = true}
end

function cli:startGame()
	if not self.login then
		return {ok = false}
	end
	if not self.room then
		return {ok = false}
	end

	local result = skynet.call(self.room,"lua","startGame",skynet:self())

	return {ok = result}
end


function cli:joinRoom()
	if not self.login then
		return {ok = false}
	end
	if not self.room then
		return {ok = false}
	end
	--skynet.call(service.room,"lua","initRoom",skynet.self())
end

function cli:ready()
	if not self.login then
		return {ok = false}
	end
	if not self.room then
		return {ok = false}
	end
	skynet.call(self.room,"lua","ready",skynet.self())
end

function cli:usecard(req)
	if not self.login then
		return {ok = false}
	end
	if not self.room then
		return {ok = false}
	end
	skynet.send(self.room,"lua","usecard",skynet.self(),req.cmd,req.card)
end

local function new_user(fd)
	local ok, error = pcall(client.dispatch , { fd = fd })
	log("fd=%d is gone. error = %s", fd, error)
	client.close(fd)
	if data.fd == fd then
		data.fd = nil
		skynet.sleep(1000)	-- exit after 10s
		if data.fd == nil then
			-- double check
			if not data.exit then
				data.exit = true	-- mark exit
				skynet.call(service.manager, "lua", "exit", data.userid)	-- report exit
				log("user %s afk", data.userid)
				skynet.exit()
			end
		end
	end
end

function agent.assign(fd, userid)
	if data.exit then
		return false
	end
	if data.userid == nil then
		data.userid = userid
	end
	assert(data.userid == userid)

	skynet.fork(new_user, fd)
	return true
end

function agent.onPlayerJoin(player_info)
	--log("notify onPlayerJoin %s",name)
	client.push(data, "NotifyPlayerJoin", {
		name = player_info.name ,
		is_ready = player_info.is_ready,
		player_index = player_info.player_index
	})	-- push message to client
	return 0
end

function agent.onStartGame(player_cards)
	client.push(data,"NotifyStartGame",player_cards)
end




service.init {
	command = agent,
	info = data,
	require = {
		"manager",
		"room_mgr"
	},
	init = client.init "proto"
}
