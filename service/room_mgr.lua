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
	if data.full then
		return false
	end
	local room = skynet.newservice "room"
	skynet.call(room, "lua", "initRoom", agent)
	return room
end

service.init {
	command = K,
	info = data,
}