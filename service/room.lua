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
local room = {}
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
	_agent = {},
	_room = room.new()
}

function room.new()
	local o = {}
	setmetatable(o,{__index = room })
	room.init(o)
	return o
end

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

local function BroadcastStartGame(player_cards)
	for agent_id,player_index in pairs(data._agent) do
		skynet.send(agent_id,"lua","onStartGame",player_cards[player_index])
	end
end


function room:init()
	self._matchState = 0
	self._need_player_num = 4
	self._table = game_table.new()
	self._player = {}
end

function room:addMaster(agent)
	local n = math.random(data._need_player_num)
	self._player[n] = PlayerClass.new(agent,n)
	self._player[n]:setMaster()
	return n
end

function room:addPlayer(agent)
	local n = math.random(data._need_player_num)
	while self._player[n] do
		n = (n) % self._need_player_num + 1
	end
	self._player[n] = PlayerClass.new(agent,n)
	return n
end

function room:HandleMatchIsWaitingToStart()
	self._table:init()
end

function room:HandleMatchHasStarted()
	log("room:HandleMatchHasStarted")
	self._table:create()
	self._table:shuffle()
	for i=1,2 do
		for j = 1,4 do
			local card_list = self._table:getCards(4)
			self._player[j]:giveCards(card_list)
		end
	end
	local card_list = self._table:getCards(2)
	self._player[1]:giveCards(card_list)
	for i = 2,4 do
		local card_list = self._table:getCards(1)
		self._player[i]:giveCards(card_list)
	end
	local player_cards = {}

	for i,p in pairs(self._player) do
		local notify = {
			list = p:getCards(),
		}
		notify[other] =  {}
		for j, o in pairs(self._player) do
			table.insert(notify[other],j,o:getCardsNumInHand())
		end
		table.insert(player_cards,i,notify)
	end
	skynet.timeout(1 * 100,function() BroadcastStartGame(player_cards) end)
end

function room:onMatchStateSet()
	if data._matchState == MatchState.WaitingToStart then
		self:HandleMatchIsWaitingToStart()
	elseif data._matchState == MatchState.InProgress then
		self:HandleMatchHasStarted()
	end
end

function room:setMatchState(matchState)
	if matchState == self._matchState then
		return
	end
	self._matchState = matchState
	self:onMatchStateSet()
end

function room.getPlayerNum()
	local n = 0
	for _,_ in pairs(self._player) do
		n = n + 1
	end
	return n
end

function K.initRoom(agent)
	data._room:create()

	local player_index = data._room:addMaster(agent)
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
