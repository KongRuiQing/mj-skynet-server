--
-- Author: kongruiqing
-- Date: 2017-10-08 20:56:24
--
local skynet = require "skynet"
local service = require "service"
local game_table = require "game_table"
local PlayerClass = require "player"
local log = require "log"
local queue = require "skynet.queue"

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
		--log("send proto(onPlayerJoin) agent_id %d player_index %d",agent_id,player_index)
		skynet.send(agent_id,"lua","onPlayerJoin",{
			name = p:getName(),
			is_ready = p:isReady(),
			player_index = p:getIndex()
		})
	end
end

local function HandleMatchIsWaitingToStart()
	data._table:init()
end

local function HandleMatchHasStarted()

end

local function onMatchStateSet()
	if data._matchState == MatchState.WaitingToStart then
		HandleMatchIsWaitingToStart()
	elseif data._matchState == MatchState.InProgress then
		HandleMatchHasStarted()
	end
end

local function setMatchState(matchState)
	if matchState == data._matchState then
		return
	end
	data._matchState = matchState
	onMatchStateSet()
end


function gameTimer()

end

function K.initRoom(agent)
	data._need_player_num = 4
	local n = math.random(data._need_player_num)

	data._player[n] = PlayerClass.new(agent,n)
	data._player[n]:setMaster()
	data._agent[agent] = n
	setMatchState(MatchState.WaitingToStart)
	log("%d initRoom player_index %d" ,skynet.self(),n)
	return true,n
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

function K.getPlayerNum()
	local n = 0
	for _,_ in pairs(data._player) do
		n = n + 1
	end
	return n
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
	local num_player = K.getPlayerNum()
	if num_player >= data._need_player_num then
		return false
	end

	local robot_id = K.getMasterIndex() % data._need_player_num + 1
	while data._player[robot_id] do
		robot_id = ((robot_id) % data._need_player_num) + 1
	end
	log("%d addRobot robot_id %d",skynet.self(),robot_id)

	data._player[robot_id] = PlayerClass.robot(robot_id)
	BroadcastPlayerJoin(data._player[robot_id])
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
