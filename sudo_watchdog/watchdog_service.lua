#!/usr/bin/env lua

require("batctl")

for line in add_interface('bat0') do
  print(line)
end