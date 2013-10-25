#!/usr/bin/env lua

require("batctl")

-- add an interface to batman-adv
result = add_interface('wlan0')
if result.status == BATCTL_STATUS_SUCCESS then
  print("added wlan0 to batman-adv interface list")
else
  print("error! " .. result.data)
end

-- get an array of batman-adv managed interfaces
-- format >> interface_name : status
result = get_interface_settings()
if result.status == BATCTL_STATUS_SUCCESS then
  print("batman-adv currently managing " .. #result.data .. " interfaces.")
  for k, v in pairs(result.data) do
    print(v)
  end
else
  print("error! " .. result.data)
end

-- set the originator interval
result = set_originator_interval(1337)
if result.status == BATCTL_STATUS_SUCCESS then
  print("originator interval has been set to 1337")
else
  print("error! " .. result.data)
end

-- get the originator interval
result = get_originator_interval()
if result.status == BATCTL_STATUS_SUCCESS then
  print("originator interval is: " .. result.data)
else
  print("error! " .. result.data)
end

-- set gateway mode
result = set_gateway_mode('off')
if result.status == BATCTL_STATUS_SUCCESS then
  print("gateway mode has been turned off")
else
  print("error! " .. result.data)
end

-- get the gateway mode
result = get_gateway_mode()
if result.status == BATCTL_STATUS_SUCCESS then
  print("gateway mode is: " .. result.data)
else
  print("error! " .. result.data)
end

-- set packet aggregation
result = set_packet_aggregation('enable')
if result.status == BATCTL_STATUS_SUCCESS then
  print("packet aggregation has been enabled")
else
  print("error! " .. result.data)
end

-- get packet aggregation
result = get_packet_aggregation()
if result.status == BATCTL_STATUS_SUCCESS then
  print("packet aggregation is: " .. result.data)
else
  print("error! " .. result.data)
end

-- set bonding mode
result = set_bonding_mode('disable')
if result.status == BATCTL_STATUS_SUCCESS then
  print("bonding mode has been disabled")
else
  print("error! " .. result.data)
end

-- get bonding mode
result = get_bonding_mode()
if result.status == BATCTL_STATUS_SUCCESS then
  print("bonding mode is: " .. result.data)
else
  print("error! " .. result.data)
end

-- set fragmentation mode
result = set_fragmentation_mode('enable')
if result.status == BATCTL_STATUS_SUCCESS then
  print("fragmentation mode has been enabled")
else
  print("error! " .. result.data)
end

-- get fragmentation mode
result = get_fragmentation_mode()
if result.status == BATCTL_STATUS_SUCCESS then
  print("fragmentation mode is: " .. result.data)
else
  print("error! " .. result.data)
end

-- set isolation mode
result = set_isolation_mode('disable')
if result.status == BATCTL_STATUS_SUCCESS then
  print("isolation mode has been disabled")
else
  print("error! " .. result.data)
end

-- get isolation mode
result = get_isolation_mode()
if result.status == BATCTL_STATUS_SUCCESS then
  print("isolation mode is: " .. result.data)
else
  print("error! " .. result.data)
end

-- remove an interface from batman-adv
result = remove_interface('wlan0')
if result.status == BATCTL_STATUS_SUCCESS then
  print("batman-adv is no longer managing interface wlan0")
else
  print("error! " .. result.data)
end