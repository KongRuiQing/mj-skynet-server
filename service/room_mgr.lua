--
-- Author: kongruiqing
-- Date: 2017-10-07 18:47:14
--
local skynet = require "skynet"
local service = require "service"
local log = require "log"

local data = {}
local K = {}


function K.createRoom(agent)
	log("createRoom %d", agent)
	if data.full then
		return false,nil
	end
	local room = skynet.newservice "room"
	local ok,player_index = skynet.call(room, "lua", "initRoom", agent)
	return ok,room,player_index
end

service.init {
	command = K,
	info = data,
}
