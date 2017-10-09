local skynet = require "skynet"

local log = require "log"
local player = require "player"
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
  self.player = {}
  self.num_player = 0
  self.cards = {}
  self.game_state = TableState.WaitingToStart
end


function table:master(agent)
  if ~self.player[agent] then
    return false
  end
  return true
end

function table:join(agent)
  if self.player[agent] then
    return false
  end
  self.player[agent] = player.new(agent)

  self.num_player = self.num_player + 1
  return true
end

function table:onPlayerReady(is_ready)

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
