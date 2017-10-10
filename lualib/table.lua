local skynet = require "skynet"

local log = require "log"
local table = {}

local TableState = {
  WaitingToStart = 1,
  InProgress = 2
}

function table.new()
  local o = {}
  setmetatable(o, table)
  table.init(o)
  return o
end

function table:init()

  self.cards = {}
  self.game_state = TableState.WaitingToStart
end



function table:RequestStart()

  self:begin()
end

function table:checkCanStart()
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

function table:begin()
  self:setMatchState(TableState.InProgress)
  skynet.timeout(1000,handler(self,self.timer))
end

function table:setMatchState(state)
  self.game_state = state
  if self.game_state == TableState.InProgress then
    self:initCards()
  end
end

function self:initCards()

end

function table:timer()
  self:updateGameState()

  skynet.timeout(1000,handler(self,self.timer))
end

function table:updateGameState()
  if game_state == TableState.WaitingToStart then

  elseif game_state == TableState.InProgress then
  end
end

return table
