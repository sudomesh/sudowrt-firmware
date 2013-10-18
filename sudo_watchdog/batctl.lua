#!/usr/bin/env lua

--[[

  The purpose of the script is to provide a
  wrapper for the batctl program.

--]]

COMMAND_BATCTL_INTERFACE           = 'batctl if'
COMMAND_BATCTL_ORIGINATORS         = 'batctl o'
COMMAND_BATCTL_ORIGINATOR_INTERVAL = 'batctl it'
COMMAND_BATCTL_LOG_LEVEL           = 'batctl ll'
COMMAND_BATCTL_KERNEL_LOG          = 'batctl l'
COMMAND_BATCTL_GATEWAY_MODE        = 'batctl gw'
COMMAND_BATCTL_GATEWAY_LIST        = 'batctl gwl'
COMMAND_BATCTL_LOCAL_TRANSLATIONS  = 'batctl tl'
COMMAND_BATCTL_GLOBAL_TRANSLATIONS = 'batctl tg'
COMMAND_BATCTL_INTERFACE_NEIGHBORS = 'batctl sn'
COMMAND_BATCTL_VIS_SERVER_MODE     = 'batctl vm'
COMMAND_BATCTL_VIS_DATA            = 'batctl vd'
COMMAND_BATCTL_PACKET_AGGREGATION  = 'batctl ag'
COMMAND_BATCTL_BONDING_MODE        = 'batctl b'
COMMAND_BATCTL_FRAGMENTATION_MODE  = 'batctl f'
COMMAND_BATCTL_ISOLATION_MODE      = 'batctl ap'

COMMAND_BATCTL_PING       = 'batctl p'
COMMAND_BATCTL_TRACEROUTE = 'batctl tr'
COMMAND_BATCTL_TCPDUMP    = 'batctl td'
COMMAND_BATCTL_BISECT     = 'batctl bisect'

function get_interface_settings()
  batctl = io.popen(COMMAND_BATCTL_INTERFACE)
  return batctl:lines()
end

function add_interface(interface)
  batctl = io.popen(COMMAND_BATCTL_INTERFACE .. ' add ' .. interface)
  return batctl:lines()
end

function delete_interface(interface)
  batctl = io.popen(COMMAND_BATCTL_INTERFACE .. ' del ' .. interface)
  return batctl:lines()
end

function get_originators()
  batctl = io.popen(COMMAND_BATCTL_ORIGINATORS)
  return batctl:lines()
end

function get_originator_interval()
  batctl = io.popen(COMMAND_BATCTL_ORIGINATOR_INTERVAL)
  return batctl:lines()
end

function set_originator_interval(interval_ms)
  batctl = io.popen(COMMAND_BATCTL_ORIGINATOR_INTERVAL .. ' ' .. interval_ms)
  return batctl:lines()
end

function get_log_level()
  batctl = io.popen(COMMAND_BATCTL_LOG_LEVEL)
  return batctl:lines()
end

function set_log_level(log_level)
  batctl = io.popen(COMMAND_BATCTL_LOG_LEVEL .. ' ' .. log_level)
  return batctl:lines()
end

function get_kernel_log()
  batctl = io.popen(COMMAND_BATCTL_KERNEL_LOG)
  return batctl:lines()
end

function get_gateway_mode()
  batctl = io.popen(COMMAND_BATCTL_GATEWAY_MODE)
  return batctl:lines()
end

function set_gateway_mode(gateway_mode)
  batctl = io.popen(COMMAND_BATCTL_GATEWAY_MODE .. ' ' .. gateway_mode)
  return batctl:lines()
end

function get_gateway_list()
  batctl = io.popen(COMMAND_BATCTL_GATEWAY_LIST)
  return batctl:lines()
end

function get_local_translation_table()
  batctl = io.popen(COMMAND_BATCTL_LOCAL_TRANSLATIONS)
  return batctl:lines()
end

function get_global_translation_table()
  batctl = io.popen(COMMAND_BATCTL_GLOBAL_TRANSLATIONS)
  return batctl:lines()
end

function get_interface_neighbor_table()
  batctl = io.popen(COMMAND_BATCTL_INTERFACE_NEIGHBORS)
  return batctl:lines()
end

function get_vis_server_mode()
  batctl = io.popen(COMMAND_BATCTL_VIS_SERVER_MODE)
  return batctl:lines()
end

function set_vis_server_mode(vis_mode)
  batctl = io.popen(COMMAND_BATCTL_VIS_SERVER_MODE .. ' ' .. vis_mode)
  return batctl:lines()
end

function get_vis_data(format)
  batctl = io.popen(COMMAND_BATCTL_VIS_DATA .. ' ' .. format)
  return batctl:lines()
end

function get_packet_aggregation_setting()
  batctl = io.popen(COMMAND_BATCTL_PACKET_AGGREGATION)
  return batctl:lines()
end

function set_packet_aggregation(aggregation)
  batctl = io.popen(COMMAND_BATCTL_PACKET_AGGREGATION .. ' ' .. aggregation)
  return batctl:lines()
end

function get_bonding_mode_setting()
  batctl = io.popen(COMMAND_BATCTL_BONDING_MODE)
  return batctl:lines()
end

function set_bonding_mode(bonding)
  batctl = io.popen(COMMAND_BATCTL_BONDING_MODE .. ' ' .. bonding)
  return batctl:lines()
end

function get_fragmentation_mode_setting()
  batctl = io.popen(COMMAND_BATCTL_FRAGMENTATION_MODE)
  return batctl:lines()
end

function set_fragmentation_mode(fragmentation)
  batctl = io.popen(COMMAND_BATCTL_FRAGMENTATION_MODE .. ' ' .. fragmentation)
  return batctl:lines()
end

function get_isolation_mode_setting()
  batctl = io.popen(COMMAND_BATCTL_ISOLATION_MODE)
  return batctl:lines()
end

function set_isolation_mode(isolation)
  batctl = io.popen(COMMAND_BATCTL_ISOLATION_MODE .. ' ' .. isolation)
  return batctl:lines()
end