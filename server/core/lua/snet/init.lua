local snet = {}
local socket = require("socket")

snet._VERSION = "SNET v.1.0.1"
snet._COPYRIGHT = "Copyright © 2020 Pavel Akulichev"
snet._DESCRIPTION = "Simple Network Module v.1.0.1"

-- SNET Statuses Definition
SNET_DISCONNECTED = 0
SNET_CONNECTED = 1

-- SNET Priorities
SNET_SYSTEM_PRIORITY = 4
SNET_HIGH_PRIORITY = 3
SNET_MEDIUM_PRIORITY = 2
SNET_LOW_PRIORITY = 1
SNET_BYPASS_PRIORITY = 0

-- SNET Service Packet IDs
SNET_CONFIRM_PRIORITY = 0xFFFFFFFF
SNET_BLOCK_PACKET = 0xFFFFFFFF - 1

snet.bstream = require("snet.bstream")
local server_class = require("snet.server")
local client_class = require("snet.client")

function snet.server(address, port)
  local new_object = {}
  setmetatable(new_object, {
    __index = server_class,
    __tostring = function()
      return "SNET Server"
    end
  })

  new_object.socket = socket.udp()
  new_object.socket:settimeout(0)
  new_object.socket:setsockname(address, port)

  new_object.address = address
  new_object.port = port

  return new_object
end

function snet.client(address, port)
  local new_object = {}
  setmetatable(new_object, {
    __index = client_class,
    __tostring = function()
      return "SNET Client"
    end
  })

  new_object.socket = socket.udp()
  new_object.socket:settimeout(0)
  new_object.socket:setpeername(address, port)

  new_object.address = address
  new_object.port = port

  return new_object
end

return snet