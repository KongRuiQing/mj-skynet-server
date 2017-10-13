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
  self.cards = {
    0x01,0x02
  }
  for i=#self.cards,2,-1 do
    local tmp = self.cards[i]
    local index = math.random(1, i - 1)
    self.cards[i] = self.cards[index]
    self.cards[index] = tmp
  end
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
