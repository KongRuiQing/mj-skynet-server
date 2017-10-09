--
-- Author: kongruiqing
-- Date: 2017-10-08 20:56:24
--
local skynet = require "skynet"
local service = require "service"
local table = require "table"
local player = require "player"
local log = require "log"

local room = {}
local data = {
	_table = table.new(),
	_player = {}
	_agent = {}
}

function K.initRoom(agent)
	data._player[1] = player.new(agent)
	data._player[1]:setMaster()
	data._agent[agent] = 1
end

function K:joinRoom(agent)
	local num_player = #data.player
	if num_player < 4 then
		data._player[num_player + 1] = player.new(agent)
		data._agent[agent] = num_player + 1
	end
end

function K:ready(agent)
	local player_index = data._agent[agent]
	if not player_index then
		return false
	end
	data._player[player_index]:ready()
end

function K:start(agent)
	local player_index = data._agent[agent]
	if not player_index then
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






service.init {
	command = K,
	info = data,
}
