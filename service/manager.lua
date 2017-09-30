local skynet = require "skynet"
local service = require "service"
local log = require "log"

local manager = {}
local users = {}

local function new_agent()
	-- todo: use a pool
	return skynet.newservice "agent"
end

local function free_agent(agent)
	-- kill agent, todo: put it into a pool maybe better
	skynet.kill(agent)
end

function manager.assign(fd)
	local agent
	repeat
		agent = users[fd]
		if not agent then
			agent = new_agent()
			if not users[fd] then
				-- double check
				users[fd] = agent
			else
				free_agent(agent)
				agent = users[fd]
			end
		end
	until skynet.call(agent, "lua", "assign", fd)
	log("Assign %d [%s]", fd, agent)
end

function manager.exit(userid)
	users[userid] = nil
end

service.init {
	command = manager,
	info = users,
}


