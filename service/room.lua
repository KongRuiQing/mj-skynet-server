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

local MatchState = {
	EnteringMap = 1,
	WaitingToStart = 2,
	InProgress = 3,
	WaitingPostMatch = 4,
	LeavingMap = 5,
	Aborted = 6,
}

local data = {
	_table = game_table.new(),
	_player = {},
	_agent = {},
	_matchState = 0
}

local function BroadcastPlayerJoin(p)
	for agent_id,player_index in pairs(data._agent) do
		skynet.send(agent_id,"lua","onPlayerJoin",{
			name = p:getName(),
			is_ready = p:isReady(),
		})
	end
end

local function setMatchState(matchState)
	if matchState == data._matchState then
		return
	end
	data._matchState = matchState
	onMatchStateSet()
end

local function onMatchStateSet()
	if data._matchState == MatchState.WaitingToStart then
		HandleMatchIsWaitingToStart()
	elseif data._matchState == MatchState.InProgress then
		HandleMatchHasStarted()
	end
end

local function HandleMatchIsWaitingToStart()
	data._table:init()
end

local function HandleMatchHasStarted()

end

function gameTimer()

end

function K.initRoom(agent)
	data._player[1] = PlayerClass.new(agent)
	data._player[1]:setMaster()
	data._agent[agent] = 1
	data._need_player_num = 2
	setMatchState(MatchState.WaitingToStart)
	skynet.timeout(1000,K.gameTimer)
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

function K.startGame(agent)
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

	for player_index , player in pairs(data._player) do
		if not player:isReady() then
			return false
		end
	end
	setMatchState(GameState.InProgress)
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
