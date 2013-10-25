#!/usr/bin/env lua

require("batctl")

-- get an array of batman-adv managed interfaces
result = get_interface_settings()
if result.status == BATCTL_STATUS_SUCCESS then
  print("batman-adv currently managing " .. #result.data .. " interfaces.")
  for key, iface in pairs(result.data) do
    print(iface.name .. ': ' .. iface.status)
  end
else
  print("error! " .. result.data)
end

-- get an array of all known batman-adv network originators
result = get_originators()
if result.status == BATCTL_STATUS_SUCCESS then
  print("\nthere are " .. #result.data .. " originators known to the network.")
  for key, orig in pairs(result.data) do
    print(orig.address .. ' last seen ' .. orig.last_seen_ms .. 'ms ago')
  end
else
  print("error! " .. result.data)
end

-- get the originator interval
result = get_originator_interval_ms()
if result.status == BATCTL_STATUS_SUCCESS then
  print("\noriginator interval is: " .. result.data)
else
  print("error! " .. result.data)
end

-- get the gateway mode
result = get_gateway_mode()
if result.status == BATCTL_STATUS_SUCCESS then
  print("\ngateway mode is: " .. result.data)
else
  print("error! " .. result.data)
end

-- get packet aggregation
result = get_packet_aggregation()
if result.status == BATCTL_STATUS_SUCCESS then
  print("\npacket aggregation is: " .. result.data)
else
  print("error! " .. result.data)
end

-- get bonding mode
result = get_bonding_mode()
if result.status == BATCTL_STATUS_SUCCESS then
  print("\nbonding mode is: " .. result.data)
else
  print("error! " .. result.data)
end

-- get fragmentation mode
result = get_fragmentation_mode()
if result.status == BATCTL_STATUS_SUCCESS then
  print("\nfragmentation mode is: " .. result.data)
else
  print("error! " .. result.data)
end

-- get isolation mode
result = get_isolation_mode()
if result.status == BATCTL_STATUS_SUCCESS then
  print("\nisolation mode is: " .. result.data)
else
  print("error! " .. result.data)
end