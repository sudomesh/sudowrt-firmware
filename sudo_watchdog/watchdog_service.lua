#!/usr/bin/env lua

require("batctl")

for line in get_interface_settings() do
  print(line)
end