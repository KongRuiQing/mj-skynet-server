local skynet = require "skynet"
local log = require "log"
local PlayerClass = require "player"
local game_table = require "game_table"
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


function K.new()
	local o = {}
	setmetatable(o,{__index = room })
	K.init(o)
	return o
end

function K:init()
	self._matchState = 0
	self._need_player_num = 4
	self._table = game_table.new()
	self._player = {}
end

function K:addMaster(agent)
	local n = math.random(data._need_player_num)
	self._player[n] = PlayerClass.new(agent,n)
	self._player[n]:setMaster()
	self._masterIndex = n
	return n
end

function K:addPlayer(agent)
	local n = math.random(data._need_player_num)
	while self._player[n] do
		n = (n) % self._need_player_num + 1
	end
	self._player[n] = PlayerClass.new(agent,n)
	return n
end

function K:addRobot()
	local robot_id = self._masterIndex % self._need_player_num + 1
	while self._player[robot_id] do
		robot_id = ((robot_id) % self._need_player_num) + 1
	end
	log("%d addRobot robot_id %d",skynet.self(),robot_id)

	self._player[robot_id] = PlayerClass.robot(robot_id)
end


function K:HandleMatchIsWaitingToStart()
	self._table:init()
end

function K:HandleMatchHasStarted()
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

function K:onMatchStateSet()
	if data._matchState == MatchState.WaitingToStart then
		self:HandleMatchIsWaitingToStart()
	elseif data._matchState == MatchState.InProgress then
		self:HandleMatchHasStarted()
	end
end

function K:setMatchState(matchState)
	if matchState == self._matchState then
		return
	end
	self._matchState = matchState
	self:onMatchStateSet()
end

function K.getPlayerNum()
	local n = 0
	for _,_ in pairs(self._player) do
		n = n + 1
	end
	return n
end

function K.startGame()
	self:setMatchState(GameState.InProgress)
end

return K
