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
		return false,nil
	end
	local room = skynet.newservice "room"
	local ok,player_index = skynet.call(room, "lua", "initRoom", agent)
	if ok  then
		data.roomNum = data.roomNum + 1
	end

	return ok,room,player_index
end

local function _init()
	data.roomNum = 0
	data.full = false
end

service.init {
	command = K,
	init = _init,
	info = data,
}
