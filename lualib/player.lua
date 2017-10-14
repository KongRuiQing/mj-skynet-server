local skynet = require "skynet"
local player = {}

function player.new(...)
  local o = {}
  setmetatable(o, {__index = player})
  player.initPlayer(o,...)
  return o
end

function player.robot(...)
  local o = {}
  setmetatable(o, {__index = player})
  player.initRobot(o,...)
  return o
end

function player:initPlayer(agent)
  self.agent = agent
  self.cards = {}
  self.is_ready = false
  self.is_master = false
  self.name = ""
end


function player:initRobot(robot_id)
  self.agent = nil
  self.cards = {}
  self.is_ready = true
  self.is_master = false
  self.name = "robot-" .. robot_id
end

function player:getName()
  return self.name
end

function player:setMaster()
  self.is_master = true
  self.is_ready = true
end

function player:ready()
  if self.is_master then
    return false
  end
  self.is_ready = not self.is_ready
  self.table:onPlayerReady(self.is_ready)
  return true
end

function player:isReady()
  if self.is_master then
    return true
  end
  return self.is_ready
end

function player:start()
  if not self.is_master then
    return false
  end
  local bool = self.table:checkCanStart()
  if bool then
    return self.table:RequestStart()
  end
  return bool
end

return player
