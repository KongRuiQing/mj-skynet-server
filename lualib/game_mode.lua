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

function K:newTimer(loop)
	local o = {}
	local obj = self

	local timer_func = function()
		log("Tick one second")
		obj:gameTimer(1)
		if loop then
			skynet.timeout(1*100,o)
		end
	end
	setmetatable(o,{__call = timer_func})
	return o
end


function K.new()
	local o = {}
	setmetatable(o,{__index = K })
	--K.init(o)
	return o
end

function K:init()
	self._matchState = 0
	self._needPlayerNum = 4
	self._table = game_table.new()
	self._player = {}
	self._currentIndex = 1
end

function K:addMaster(agent)
	local n = math.random(self._needPlayerNum)
	self._player[n] = PlayerClass.new(agent,n)
	self._player[n]:setMaster()
	self._masterIndex = n
	return n
end

function K:create(data)
	self:init()
	self._agent = data._agent
end

function K:addPlayer(agent)
	local n = math.random(self._needPlayerNum)
	while self._player[n] do
		n = (n) % self._need_player_num + 1
	end
	self._player[n] = PlayerClass.new(agent,n)
	return n
end

function K:addRobot()
	local num = self:getPlayerNum()
	if num >= self._need_player_num then
		return nil
	end
	local robot_id = self._masterIndex % self._need_player_num + 1
	while self._player[robot_id] do
		robot_id = ((robot_id) % self._need_player_num) + 1
	end
	log("%d addRobot robot_id %d",skynet.self(),robot_id)

	self._player[robot_id] = PlayerClass.robot(robot_id)

	return self._player[robot_id]
end


function K:HandleMatchIsWaitingToStart()
	self._table:init()
end

function K:HandleMatchHasStarted()
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
	self:broadcastGamePlayCard()

end

function K:gameTimer()
	if self._matchState == MatchState.InProgress then
		self._tickTime = self._tickTime + 1
		if self._tickTime >= 20 then
			self._currentIndex = self._currentIndex % self._need_player_num
	end
end

function K:broadcastGamePlayCard()
	for agent_id,player_index in pairs(self._agent) do
		local card_in_hand = self._player[player_index]:getCards()
		local other = {}
		for j,player in pairs(self._player) do
			if player_index ~= j then
				table.insert(other,j,self._player[j]:getCardNumInHand())
			end
		end
		skynet.send(agent_id,"lua","onStartGame",{
			hand_card = card_in_hand,
			other = other,
			state = CardHelp.getStateAtStart(card_in_hand)
		})
	end
end

function K:onMatchStateSet()
	if self._matchState == MatchState.WaitingToStart then
		self:HandleMatchIsWaitingToStart()
	elseif self._matchState == MatchState.InProgress then
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

function K:getPlayerNum()
	local n = 0
	for _,_ in pairs(self._player) do
		n = n + 1
	end
	return n
end

function K:startGame()
	self:setMatchState(MatchState.InProgress)
end

return K
