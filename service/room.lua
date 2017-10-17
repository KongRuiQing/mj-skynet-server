--
-- Author: kongruiqing
-- Date: 2017-10-08 20:56:24
--
local skynet = require "skynet"
local service = require "service"
local log = require "log"
local queue = require "skynet.queue"
local game_mode = require "game_mode"
local K = {}

local data = {
	_agent = {},
	_GameMode = game_mode.new()
}

local function BroadcastPlayerJoin(p)
	for agent_id,player_index in pairs(data._agent) do
		--log("send proto(onPlayerJoin) agent_id %d player_index %d",agent_id,player_index)
		skynet.send(agent_id,"lua","onPlayerJoin",{
			name = p:getName(),
			is_ready = p:isReady(),
			player_index = p:getIndex()
		})
	end
end


function K.initRoom(agent)
	data._GameMode:create(data)

	local player_index = data._GameMode:addMaster(agent)
	data._agent[agent] = player_index

	log("%d initRoom player_index %d" ,skynet.self(),player_index)
	return true,player_index
end

function K.joinRoom(agent)

end

function K.ready(agent)
	local player_index = data._agent[agent]
	if not player_index then
		return false
	end
	data._player[player_index]:ready()
end

function K.startGame(agent)
	local player_index = data._agent[agent]
	if not player_index then
		return false
	end
	--local b = data._GameMode:checkCarStart(player_index)
	--if b then
	data._GameMode:startGame()
	return true
end

function K.getMasterIndex()
	for _,player_index in pairs(data._agent) do
		local p = data._player[player_index]
		if p and p:isMaster() then
			return p:getIndex()
		end
	end
	return 0
end


function K.addRobot()
	local robot = data._GameMode:addRobot()
	if robot then
		BroadcastPlayerJoin(robot)
	end
	return true
end

local function _init()
	log("room addresss %d",skynet.self())
	math.randomseed(os.time())
end


service.init {
	command = K,
	info = data,
	init = _init,
}
