--
-- Author: kongruiqing
-- Date: 2017-10-08 20:56:24
--
local skynet = require "skynet"
local service = require "service"
local game_table = require "game_table"
local PlayerClass = require "player"
local log = require "log"

local K = {}

local data = {
	_table = game_table.new(),
	_player = {},
	_agent = {}
}

local function BroadcastPlayerJoin(p)
	for agent_id,player_index in pairs(data._agent) do
		skynet.send(agent_id,"lua","onPlayerJoin",{name = p:getName()})
	end
end

function K.initRoom(agent)
	data._player[1] = PlayerClass.new(agent)
	for k,v in pairs(data._player[1]) do
		log("player. %s",k)
	end
	log("agent %d",agent)
	data._player[1]:setMaster()
	data._agent[agent] = 1
	data._need_player_num = 2
end

function K.joinRoom(agent)
	local num_player = #data._player
	if num_player < data._need_player_num then
		data._player[num_player + 1] = PlayerClass.new(agent)
		data._agent[agent] = num_player + 1
	end
end

function K.ready(agent)
	local player_index = data._agent[agent]
	if not player_index then
		return false
	end
	data._player[player_index]:ready()
end

function K.start(agent)
	local player_index = data._agent[agent]
	if not player_index then
		return false
	end
	if not data._player[player_index] then
		return false
	end
	if not data._player[player_index]:isMaster() then
		return false
	end

	data._table:start()

	local card_step = 1
	while card_step < 13 do
		local cards = data._table.get_cards(2)
		player_index = (card_step - 1) % 4
		data._player[player_index]:give_cards(cards)

	end

	for _,p in pairs(data._player) do
		p:sync_cards()
	end
	return true
end

function K.addRobot()
	local num_player = #data._player
	if num_player >= data._need_player_num then
		return false
	end

	local robot_id = num_player + 1
	data._player[robot_id] = PlayerClass.robot(robot_id)
	BroadcastPlayerJoin(data._player[robot_id])
	return true
end


service.init {
	command = K,
	info = data,
}
