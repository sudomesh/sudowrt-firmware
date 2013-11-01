#!/usr/bin/env lua

require("string")

--[[

  The purpose of the script is to provide a
  wrapper library for the batctl command line
  utility.

--]]

BATCTL_STATUS_SUCCESS = 0
BATCTL_STATUS_FAILURE = -1

COMMAND_BATCTL_INTERFACE             = '2>&1 batctl if'
COMMAND_BATCTL_ORIGINATORS           = '2>&1 batctl o'
COMMAND_BATCTL_ORIGINATOR_INTERVAL   = '2>&1 batctl it'
COMMAND_BATCTL_LOG_LEVEL             = '2>&1 batctl ll'
COMMAND_BATCTL_KERNEL_LOG            = '2>&1 batctl l'
COMMAND_BATCTL_GATEWAY_MODE          = '2>&1 batctl gw'
COMMAND_BATCTL_GATEWAY_LIST          = '2>&1 batctl gwl'
COMMAND_BATCTL_LOCAL_TRANSLATIONS    = '2>&1 batctl tl'
COMMAND_BATCTL_GLOBAL_TRANSLATIONS   = '2>&1 batctl tg'
COMMAND_BATCTL_CLAIM_TABLE           = '2>&1 batctl cl'
COMMAND_BATCTL_VIS_SERVER_MODE       = '2>&1 batctl vm'
COMMAND_BATCTL_VIS_DATA              = '2>&1 batctl vd'
COMMAND_BATCTL_PACKET_AGGREGATION    = '2>&1 batctl ag'
COMMAND_BATCTL_BONDING_MODE          = '2>&1 batctl b'
COMMAND_BATCTL_BRIDGE_LOOP_AVOIDANCE = '2>&1 batctl bl'
COMMAND_BATCTL_FRAGMENTATION_MODE    = '2>&1 batctl f'
COMMAND_BATCTL_AP_ISOLATION_MODE     = '2>&1 batctl ap'

COMMAND_BATCTL_STATISTICS = '2>&1 batctl s'
COMMAND_BATCTL_PING       = '2>&1 batctl p'
COMMAND_BATCTL_TRACEROUTE = '2>&1 batctl tr'
COMMAND_BATCTL_TCPDUMP    = '2>&1 batctl td'
COMMAND_BATCTL_BISECT     = '2>&1 batctl bisect'

MESSAGE_NO_BATMAN_NODES_IN_RANGE = 'No batman nodes in range'
MESSAGE_NO_GATEWAYS_IN_RANGE     = 'No gateways in range'

ERROR_MODULE_NOT_LOADED         = 'Error . batman.adv module has not been loaded'
ERROR_INTERFACE_DOES_NOT_EXISTS = 'Error . interface does not exist:'
ERROR_MESH_NOT_ENABLED          = 'Error . mesh has not been enabled yet'
ERROR_VALUE_NOT_ALLOWED         = 'The following values are allowed:'

--[[
  An object for modeling the result of a
  batctl command.
--]]

Result = {}
Result.__index = Result

function Result.build(status, data)
  local rslt = {}
  setmetatable(rslt, Result)
  rslt.status = status
  rslt.data = data
  return rslt
end

--[[
  An object for modeling a network interface
  managed by batman-adv
--]]

Interface = {}
Interface.__index = Interface

function Interface.build(name, status)
  local iface = {}
  setmetatable(iface, Interface)
  iface.name = name
  iface.status = status
  return iface
end

--[[
  An object for modeling batman-adv
  originators
--]]

Originator = {}
Originator.__index = Originator

function Originator.build(address, last_seen_str, num_255, next_hop, outgoing_interface, potential_next_hops)
  local orig = {}
  setmetatable(orig, Originator)
  
  function parse_last_seen_ms(str)
    units = string.match(str, '%d+.%d+(%a)')
    if units == 's' then
      factor = 1000
    elseif units == 'm' then
      factor = 60 * 1000
    else
      return 0
    end
    
    milliseconds = string.match(str, '(%d+).%d+%a') * factor
    return milliseconds + string.match(str, '%d+.(%d+)%a')
  end
  
  orig.address = address
  orig.last_seen_ms = parse_last_seen_ms(last_seen_str)
  orig.num_255 = num_255
  orig.next_hop = next_hop
  orig.outgoing_interface = outgoing_interface
  orig.potential_next_hops = potential_next_hops
  return orig
end

--[[
  An object for modeling batman-adv
  gateways
--]]

Gateway = {}
Gateway.__index = Gateway

function Gateway.build(address, num_255, next_hop, outgoing_interface, class)
  local gatew = {}
  setmetatable(gatew, Gateway)
  
  gatew.address = address
  gatew.num_255 = num_255
  gatew.next_hop = next_hop
  gatew.outgoing_interface = outgoing_interface
  gatew.class = class
  return gatew
end

function line_contains_error(line)  
  if string.find(line, ERROR_MODULE_NOT_LOADED) == nil and
      string.find(line, ERROR_INTERFACE_DOES_NOT_EXISTS) == nil and
      string.find(line, ERROR_MESH_NOT_ENABLED) == nil and
      string.find(line, ERROR_VALUE_NOT_ALLOWED) == nil then
    return false
  end
  
  return true
end

--[[
  returns a Result containing an array of
  Interface objects representing all of the
  interfaces that batman-adv is currently
  managing.
--]]
function get_interface_settings()
  interfaces = {}
  batctl = io.popen(COMMAND_BATCTL_INTERFACE)
    
  for line in batctl:lines() do
    if line_contains_error(line) then
      return Result.build(BATCTL_STATUS_FAILURE, line)
    else
      interfaces[#interfaces + 1] = Interface.build(string.match(line, '(.+):%s(.+)'))
    end
  end
  
  return Result.build(BATCTL_STATUS_SUCCESS, interfaces)
end

--[[
  adds $interface_name to batman-adv's list
  of managed interfaces.
--]]
function add_interface(interface_name)
  batctl = io.popen(COMMAND_BATCTL_INTERFACE .. ' add ' .. interface_name)
  
  for line in batctl:lines() do
    return Result.build(BATCTL_STATUS_FAILURE, line)
  end
  
  return Result.build(BATCTL_STATUS_SUCCESS, nil)
end

--[[
  removes $interface_name from batman-adv's
  list of managed interfaces.
--]]
function remove_interface(interface_name)
  batctl = io.popen(COMMAND_BATCTL_INTERFACE .. ' del ' .. interface_name)
  
  for line in batctl:lines() do
    return Result.build(BATCTL_STATUS_FAILURE, line)
  end

  return Result.build(BATCTL_STATUS_SUCCESS, nil)
end

--[[
  returns a Result containing an array of
  Originator objects representing all of the
  known originators in the batman-adv network.
--]]
function get_originators()
  originators = {}
  line_count = 0
  batctl = io.popen(COMMAND_BATCTL_ORIGINATORS)
  
  for line in batctl:lines() do
    line_count = line_count + 1
    
    if line_contains_error(line) then
      return Result.build(BATCTL_STATUS_FAILURE, line)
    elseif string.find(line, MESSAGE_NO_BATMAN_NODES_IN_RANGE) ~= nil then
      break
    elseif line_count > 2 then
      originators[#originators + 1] = Originator.build(
        string.match(line, '(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)%s+(%d+.%d+%a)%s+.%s*(%d+).%s+(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)%s+.%s+(%w+).:%s+(.+)')
      )
    end
  end
  
  return Result.build(BATCTL_STATUS_SUCCESS, originators)
end

--[[
  returns a Result containing the originator
  interval in units of milliseconds.
--]]
function get_originator_interval_ms()
  batctl = io.popen(COMMAND_BATCTL_ORIGINATOR_INTERVAL)
  interval_ms = 0
  
  for line in batctl:lines() do
    if line_contains_error(line) then
      return Result.build(BATCTL_STATUS_FAILURE, line)
    else
      interval_ms = string.match(line, '%d+')
    end
  end
  
  return Result.build(BATCTL_STATUS_SUCCESS, interval_ms)
end

--[[
  sets the originator interval to $interval_ms
  milliseconds.
--]]
function set_originator_interval_ms(interval_ms)
  batctl = io.popen(COMMAND_BATCTL_ORIGINATOR_INTERVAL .. ' ' .. interval_ms)
  
  for line in batctl:lines() do
    return Result.build(BATCTL_STATUS_FAILURE, line)
  end

  return Result.build(BATCTL_STATUS_SUCCESS, nil)
end

-- TODO: implement me!
function get_log_level()
  batctl = io.popen(COMMAND_BATCTL_LOG_LEVEL)
  return batctl:lines()
end

-- TODO: implement me!
function set_log_level(log_level)
  batctl = io.popen(COMMAND_BATCTL_LOG_LEVEL .. ' ' .. log_level)
  return batctl:lines()
end

-- TODO: implement me!
function get_kernel_log()
  batctl = io.popen(COMMAND_BATCTL_KERNEL_LOG)
  return batctl:lines()
end

--[[
  returns a Result containing the gateway
  mode which can be of the values
  [off, client, server].
--]]
function get_gateway_mode()
  batctl = io.popen(COMMAND_BATCTL_GATEWAY_MODE)
  
  for line in batctl:lines() do
    if line_contains_error(line) then
      return Result.build(BATCTL_STATUS_FAILURE, line)
    else
      return Result.build(BATCTL_STATUS_SUCCESS, line)
    end
  end
  
  return Result.build(BATCTL_STATUS_FAILURE, nil)
end

--[[
  sets gateway mode to $gateway_mode, where
  $gateway_mode can be of the values
  [off, client, server].
--]]
function set_gateway_mode(gateway_mode)
  batctl = io.popen(COMMAND_BATCTL_GATEWAY_MODE .. ' ' .. gateway_mode)
  
  for line in batctl:lines() do
    return Result.build(BATCTL_STATUS_FAILURE, line)
  end
  
  return Result.build(BATCTL_STATUS_SUCCESS, nil)
end

--[[
  returns a Result containing an array of
  Gateway objects representing all of the
  known gateways in the batman-adv network.
--]]
function get_gateway_list()  
  gateways = {}
  line_count = 0
  batctl = io.popen(COMMAND_BATCTL_GATEWAY_LIST)
  
  for line in batctl:lines() do
    line_count = line_count + 1
    
    if line_contains_error(line) then
      return Result.build(BATCTL_STATUS_FAILURE, line)
    elseif string.find(line, MESSAGE_NO_GATEWAYS_IN_RANGE) ~= nil then
      break
    elseif line_count > 1 then
      gateways[#gateways + 1] = Gateway.build(
        string.match(line, '(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)%s+.%s*(%d+).%s+(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)%s+.%s+(%w+).:%s+(.+)')
      )
    end
  end
  
  return Result.build(BATCTL_STATUS_SUCCESS, gateways)
end

-- TODO: implement me!
function get_local_translation_table()
  batctl = io.popen(COMMAND_BATCTL_LOCAL_TRANSLATIONS)
  return batctl:lines()
end

-- TODO: implement me!
function get_global_translation_table()
  batctl = io.popen(COMMAND_BATCTL_GLOBAL_TRANSLATIONS)
  return batctl:lines()
end

-- TODO: implement me!
function get_claim_table()
  batctl = io.popen(COMMAND_BATCTL_CLAIM_TABLE)
  return batctl:lines()
end

--[[
  returns a Result containing the packet
  aggregation setting which can be of the
  values [enable, disable, 1, 0]
--]]
function get_packet_aggregation()
  batctl = io.popen(COMMAND_BATCTL_PACKET_AGGREGATION)
  
  for line in batctl:lines() do
    if line_contains_error(line) then
      return Result.build(BATCTL_STATUS_FAILURE, line)
    else
      return Result.build(BATCTL_STATUS_SUCCESS, line)
    end
  end
  
  return Result.build(BATCTL_STATUS_FAILURE, nil)
end

--[[
  sets packet aggregation to $aggregation,
  where $aggregation can be of the values
  [enable, disable, 1, 0].
--]]
function set_packet_aggregation(aggregation)
  batctl = io.popen(COMMAND_BATCTL_PACKET_AGGREGATION .. ' ' .. aggregation)
  
  for line in batctl:lines() do
    return Result.build(BATCTL_STATUS_FAILURE, line)
  end
  
  return Result.build(BATCTL_STATUS_SUCCESS, nil)
end

--[[
  returns a Result containing the bonding
  mode setting which can be of the
  values [enable, disable, 1, 0]
--]]
function get_bonding_mode()
  batctl = io.popen(COMMAND_BATCTL_BONDING_MODE)
  
  for line in batctl:lines() do
    if line_contains_error(line) then
      return Result.build(BATCTL_STATUS_FAILURE, line)
    else
      return Result.build(BATCTL_STATUS_SUCCESS, line)
    end
  end
  
  return Result.build(BATCTL_STATUS_FAILURE, nil)
end

--[[
  sets bonding mode to $bonding, where
  $bonding can be of the values
  [enable, disable, 1, 0].
--]]
function set_bonding_mode(bonding)
  batctl = io.popen(COMMAND_BATCTL_BONDING_MODE .. ' ' .. bonding)
  
  for line in batctl:lines() do
    return Result.build(BATCTL_STATUS_FAILURE, line)
  end
  
  return Result.build(BATCTL_STATUS_SUCCESS, nil)
end

--[[
  returns a Result containing the bridge
  loop avoidance setting which can be of the
  values [enable, disable, 1, 0]
--]]
function get_bridge_loop_avoidance()
  batctl = io.popen(COMMAND_BATCTL_BRIDGE_LOOP_AVOIDANCE)
  
  for line in batctl:lines() do
    if line_contains_error(line) then
      return Result.build(BATCTL_STATUS_FAILURE, line)
    else
      return Result.build(BATCTL_STATUS_SUCCESS, line)
    end
  end
  
  return Result.build(BATCTL_STATUS_FAILURE, nil)
end

--[[
  sets bridge loop avoidance to $avoid, where
  $avoid can be of the values
  [enable, disable, 1, 0].
--]]
function set_bridge_loop_avoidance(avoid)
  batctl = io.popen(COMMAND_BATCTL_BRIDGE_LOOP_AVOIDANCE .. ' ' .. avoid)
  
  for line in batctl:lines() do
    return Result.build(BATCTL_STATUS_FAILURE, line)
  end
  
  return Result.build(BATCTL_STATUS_SUCCESS, nil)
end

--[[
  returns a Result containing the
  fragmentation mode setting which can be of
  the values [enable, disable, 1, 0]
--]]
function get_fragmentation_mode()
  batctl = io.popen(COMMAND_BATCTL_FRAGMENTATION_MODE)
  
  for line in batctl:lines() do
    if line_contains_error(line) then
      return Result.build(BATCTL_STATUS_FAILURE, line)
    else
      return Result.build(BATCTL_STATUS_SUCCESS, line)
    end
  end
  
  return Result.build(BATCTL_STATUS_FAILURE, nil)
end

--[[
  sets fragmentation mode to $fragmentation,
  where $fragmentation can be of the values
  [enable, disable, 1, 0].
--]]
function set_fragmentation_mode(fragmentation)
  batctl = io.popen(COMMAND_BATCTL_FRAGMENTATION_MODE .. ' ' .. fragmentation)
  
  for line in batctl:lines() do
    return Result.build(BATCTL_STATUS_FAILURE, line)
  end
  
  return Result.build(BATCTL_STATUS_SUCCESS, nil)
end

--[[
  returns a Result containing the isolation
  mode setting which can be of the values
  [enable, disable, 1, 0]
--]]
function get_ap_isolation_mode()
  batctl = io.popen(COMMAND_BATCTL_AP_ISOLATION_MODE)
  
  for line in batctl:lines() do
    if line_contains_error(line) then
      return Result.build(BATCTL_STATUS_FAILURE, line)
    else
      return Result.build(BATCTL_STATUS_SUCCESS, line)
    end
  end
  
  return Result.build(BATCTL_STATUS_FAILURE, nil)
end

--[[
  sets isolation mode to $isolation, where
  $isolation can be of the values
  [enable, disable, 1, 0].
--]]
function set_ap_isolation_mode(isolation)
  batctl = io.popen(COMMAND_BATCTL_AP_ISOLATION_MODE .. ' ' .. isolation)
  
  for line in batctl:lines() do
    return Result.build(BATCTL_STATUS_FAILURE, line)
  end
  
  return Result.build(BATCTL_STATUS_SUCCESS, nil)
end

--[[
  returns an iterator over the lines of text
  returned by the 'batctl s' command.
--]]
function get_statistics()
  batctl = io.popen(COMMAND_BATCTL_STATISTICS)
  return batctl:lines()
end

-- TODO: what to do with this?
function ping(destination)
  batctl = io.popen(COMMAND_BATCTL_PING .. ' ' .. destination)
  return batctl:lines()
end

-- TODO: implement me!
function traceroute(destination)
  batctl = io.popen(COMMAND_BATCTL_TRACEROUTE .. ' ' .. destination)
  return batctl:lines()
end