local skynet = require "skynet"
local log = require "log"
local K = {}


function K.new()
  local o = {}
  setmetatable(o, {__index = K})
  K.init(o)
  return o
end

function K:init()
  self._cards = {}
end

function K:shuffle()
  for i=#self._cards,2,-1 do
    local tmp = self._cards[i]
    local index = math.random(1, i - 1)
    self._cards[i] = self._cards[index]
    self._cards[index] = tmp
  end
end

function K:create()
  local num = 3*9 + 7
  for i = 1,3 do
    for j = 1,9 do
      for k = 1,4 do
        table.insert(self._cards, i * 16 + j)
      end
    end
  end
  for j = 1,7 do
    for k = 1,4 do
      table.insert(self._cards, 4 * 16 + j)
    end
  end
end

function K:getCards(cardNum)
  local t = {}
  for i = 1,cardNum do
    local card = table.remove(self._cards,1)
    table.insert(t,1,card)
  end
  return t
end

function K:getLastCard()
  local t = {}
  local card = table.remvoe(self._cards)
  table.insert(t,1,card)
  return t
end


function K:RequestStart()

  self:begin()
end

function K:checkCanStart()
  if self.num_player ~= 4 then
    return false
  end
  for k,p in pairs(self.player) do
    if not p.isReady() then
      return false
    end
  end

  return true
end

local function handler(obj,method)
  return function(...)
    return method(obj,...)
  end
end

function K:begin()
  self:setMatchState(TableState.InProgress)
  skynet.timeout(1000,handler(self,self.timer))
end

function K:setMatchState(state)
  self.game_state = state
  if self.game_state == TableState.InProgress then
    self:initCards()
  end
end

function K:initCards()

end

function K:timer()
  self:updateGameState()

  skynet.timeout(1000,handler(self,self.timer))
end

function K:updateGameState()

end

return K
