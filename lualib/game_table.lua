local skynet = require "skynet"
local log = require "log"
local K = {}

local TableState = {
  WaitingToStart = 1,
  InProgress = 2
}

function K.new()
  local o = {}
  setmetatable(o, K)
  K.init(o)
  return o
end

function K:init()

  self.cards = {}
  self.game_state = TableState.WaitingToStart
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
