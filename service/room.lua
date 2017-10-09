--
-- Author: kongruiqing
-- Date: 2017-10-08 20:56:24
--
local skynet = require "skynet"
local service = require "service"
local table = require "table"

local log = require "log"

local room = {}
local data = {}

local player = {}

local robot = {}

function K.initRoom(agent)
	data.player_list = {agent,robot,robot,robot}
end



service.init {
	command = K,
	info = data,
}
