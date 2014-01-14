#!/usr/bin/env lua

require("socket")
require("ssl")
require("string")
json = require("dkjson-min")

config_file_path = "/etc/nodeconf/config.json"

config = nil

--[[

  This program is in its early stages.

  The idea is that it will be auto-started on nodes
  when they boot after being flashed with the sudomesh
  firmware.

  The purpose of the script is to:

    1. Locate a node configuration server on the LAN
       connected to the ethernet interface using
       DNS-SD (using the mdnsd daemon).

    2. Connect to the node configuration server
       using SSL and verifying that it is trusted.

    3. Announce the node's MAC address to the server

    4. Await configuration from the server in the form
       of one or more ipkg packages.

    5. Verify and install the ipkg packages.

    6. Report install success / failure to the server.

    7. Disable autostart of this script and reboot.

--]]


function sanitize_filename(filename)
  return string.gsub(filename, "[^-%a%d_\.]", '')
end

function fail(err_msg)
  print("[Error] "..err_msg)
  os.exit(-1);
end

function connect(ip, port)

  -- TLS/SSL client parameters (omitted)
  local params

  local conn = socket.tcp()
  conn:connect(ip, port)

  local params = {
    mode = "client",
    protocol = "tlsv1",
  --  capath = "/etc/ssl/certs",
    cafile = "/etc/nodeconf/certs/ca_root.crt",
  -- key = "/etc/certs/clientkey.pem",
  --  certificate = "/etc/certs/client.pem",
    verify = "peer",
    options = "all"
  }

  -- TLS/SSL initialization
  conn = ssl.wrap(conn, params)
  conn:dohandshake()

  return conn
end

function load_config()
  local f = io.open(config_file_path)
  local data = f:read("*all")
  config = json.decode(data)
  io.close()
end

-- run command
-- first returned value is exit_status:
--   true if exit code is 0, false otherwise
-- second returned value is combined stdout and stderr output
function run_command(cmd)
  local output
  local cmdp
  local exit_code

  -- this trickery does two things:
  -- 1. output stderr to stdout
  -- 2. output exit code to stdout
  cmd = cmd.." 2>&1; echo $?"

  cmdp = io.popen(cmd, 'r')
  output = cmdp:read('*all')
  cmdp:close()

  -- actually only gets the last digit of exit code
  -- but that's good enough
  exit_code = string.match(output, ".*(%d+)[\r\n]")
  if exit_code ~= '0' then
    return false, output
  else
    return true, output
  end
end

-- called when a configure msg and its associated
-- file has been successfully received
function configure_receive_completed(c, msg, file_path)
  local cmd
  local cmdp
  local output
  local success

  -- TODO implement this. It needs to actually run the cmd
  print("Received the file: " .. msg.data.file_name)
  if not msg.data.run_cmd then
    return nil
  end

  cmd = string.gsub(msg.data.run_cmd, "<file>", file_path)

  success, output = run_command(cmd)

  reply = {
    type = 'node_status',
    data = {
      status = "success",
      cmd_output = output
    }
  }

  if not success then
    reply.data.status = "error"
    c:send(json.encode(reply).."\n")
    return false
  end

  cmd = msg.data.post_cmd
  success, output = run_command(cmd)

  reply.data.cmd_output = output

  if not success then
    reply.data.status = "error"
    c:send(json.encode(reply).."\n")
    return false
  end

  c:send(json.encode(reply).."\n")  
  c:close()
end

-- keep receiving and handling received data
function handle_receive(c)
  local state = 'WAITING'
  local left_to_receive
  local receive_bytes
  local line
  local data
  local msg
  local err
  local file_path
  local file = nil
  
  while true do
    if state == 'WAITING' then
      line, err = c:receive("*l")
      if line == nil then
        if err ~= 'closed' then
          io.stderr:write("Socket error: " .. err)
        end
        return true
      end

      msg = json.decode(line)
      if msg == nil then
        io.stderr:write("Received invalid json")
        return true
      end

      if msg.type == 'configure' then
         print("configure message received")
         file_name = sanitize_filename(msg.data.file_name)
         left_to_receive = msg.data.file_size
         -- sanity check, configuration should 
         -- not be more than two megabytes
         if (left_to_receive > (1024 * 1024 * 2)) or (left_to_receive < 1) then
           return true
         end

         file_path = config.client.download_path .. '/' .. file_name
         file, err = io.open(file_path, 'w+b')
         if not file then
           io.stderr:write("Could not create file: \"" .. file_path .. "\" Error: " .. err)
           return true
         end
         state = 'RECEIVING_FILE'
      else
        io.stderr.write("Unknown message type")
      end

    elseif state == 'RECEIVING_FILE' then
      receive_bytes = 8192
      if left_to_receive < receive_bytes then
        receive_bytes = left_to_receive
      end
      data, err, partial = c:receive(left_to_receive)

      if data == nil then
         if partial then
           file:write(partial)
           left_to_receive = 0
         end
         file:close()
         configure_receive_completed(c, msg, file_path)
         state = 'WAITING'
      end
      left_to_receive = left_to_receive - string.len(data)
      file:write(data)
      if left_to_receive <= 0 then
        file:close()
        configure_receive_completed(c, msg, file_path)
        state = 'WAITING'
      end
    else
      io.stderr:write("Got into unknown state: "..state)
      return false
    end
  end
end

function begin_connection(ip, port)

  local c
  local cont

  print("connecting to "..ip..":"..port)
  c = connect(ip, port)

  if not c then
     print("Failed to connect")
     conn:close()
     return false
  end

  -- send node info to server
  local node_info_msg = build_node_info_msg()
  c:send(node_info_msg)

  -- begin handling incoming data
  while true do 
    ret = handle_receive(c)
    if ret == false then
      break
    end
  end

  c:close()
  return true
end

function sleep(n)
  os.execute("sleep " .. tonumber(n))
end

function find_server_and_connect()

  local mdns
  local line
  local hostname
  local ip
  local port
  local res

-- keep trying to connect
  while true do
    mdns = io.popen(config.utils.mdnssd_min..' '..config.client.service_type, 'r')

    while true do
      line = mdns:read("*line")
      if line == nil then
        break
      end
      hostname, ip, port = string.match(line, "(.+)%s+(.+)%s+(.+)")
  --    print("host: "..hostname.." | ip: "..ip.." | port: "..port)
      if hostname ~= nil and ip ~= nil and port ~= nil then
        res = begin_connection(ip, port)
        if res == true then
          mdns:close()
          return true
        end
      end
    end
    mdns:close()
    print("Could not connect. Sleeping for 5 seconds")
    sleep(5)
  end

  return false
end

function get_node_mac()

  local f
  local line

  f = io.popen("cat /sys/class/ieee80211/`ls /sys/class/ieee80211/|head -n 1`/macaddress", 'r')
  line = f:read("*line")
  f:close()
  if line == nil then
    return false
  end

  mac = string.match(line, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)")

  return mac
end


function get_system_type()

  local f
  local line

  f = io.popen("cat /proc/cpuinfo | grep 'system type'", 'r')
  line = f:read("*line")
  f:close()
  if line == nil then
    f = io.popen("cat /proc/cpuinfo | grep 'model name'", 'r')
    line = f:read("*line")
      f:close()
      if line == nil then
         return false
      end
  end

  system_type = string.match(line, ":%s+(.+)")

  -- remove multiple spaces
  system_type = string.gsub(system_type, "%s+", " ")

  return system_type
end

-- build json identifying this node
function build_node_info_msg() 

  local o = {
    type = 'node_appeared',
    data = {
      mac_addr = get_node_mac(),
      system_type = get_system_type()
    }
  }

  return json.encode(o).."\n"
end

load_config()

--mac_addr = get_node_mac()
--print("MAC: "..mac_addr)

--system_type = get_system_type()
--print("System: "..system_type)

find_server_and_connect()



