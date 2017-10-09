local skynet = require "skynet"

local log = require "log"
local player = require "player"
local table = {}

local TableState = {
  WaitingToStart = 1
  
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

function table:begin()
end




return table
