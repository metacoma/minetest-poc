local socket = require 'socket'
local np = require '9p'
local pprint = require 'pprint'
local data = require 'data'

local mine9p = {}

local ORDONLY = 0
local OWRITE = 1
local ORDWR = 2
local OEXEC = 3 

local READ_BUF_SIZ = 4096



mine9p.connect = function(proto, host, port)

  if (proto ~= "tcp") then
    error(proto .. " not supported, use only tcp")
  end

  local tcp = socket:tcp() 

  if (tcp == nil) then
    error("Can't create " .. proto .. " socket")
  end

  local _, err = tcp:connect(host, port)
  
  if (err ~= nil) then
    error("connection to " .. proto .. "!" .. host .. "!" .. port .. " failed")
  end

  return tcp
end

mine9p.mount = function(target_str) 
  local ctx = mine9p
  ctx.np = np

  if (target_str == "nil" or target_str == "") then
    error("target is nil")
  end
  local t = string.split(target_str, "!")

  ctx.target = target_str
  ctx.sock = mine9p.connect(t[1], t[2], tonumber(t[3]))
  ctx.np.attach(ctx.sock, "bebebeko", "") 
  
  return ctx
end

mine9p.write = function(ctx, path, write_data) 
   local f = ctx.np:newfid()
 
   ctx.np:walk(ctx.np.rootfid, f, path)
   ctx.np:open(f, 1)
 
   local n = ctx.np:write(f, 0, data.new(write_data))    
   return n
end

mine9p.readfile = function(ctx, path) 
  local f = ctx.np:newfid()
  local data = nil
  local offset = 0

  ctx.np:walk(ctx.np.rootfid, f, path) 
  ctx.np:open(f, ORDONLY)  

  data = tostring(ctx.np:read(f, offset, READ_BUF_SIZ))

  offset = offset + #data

  while 1 do
    --print("read .. " .. offset)
    local new_data = ctx.np:read(f, offset, READ_BUF_SIZ)
    if (new_data == nil) then
      break 
    end
    data = data .. tostring(new_data)
  end
  

  return data
end

mine9p.readdir = function(ctx, path) 
  local dir = {}
  local dirdata = _9p_readdir(ctx, path)
  while 1 do
    local st = ctx.np:getstat(data.new(dirdata))   
    table.insert(dir, st)
    dirdata = string.sub(dirdata, st.size + 3) 
    if (#dirdata == 0) then
      break
    end
  end
  return dir
end

function string.split(inputstr, sep)
  if sep == nil then
          sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
          table.insert(t, str)
  end
  return t
end

function _9p_readdir(ctx, path) 
  local f = ctx.np:newfid()
  local offset = 0
  local dir, data = nil, nil

  ctx.np:walk(ctx.np.rootfid, f, path) 
  ctx.np:open(f, ORDONLY)  

  data = ctx.np:read(f, offset, READ_BUF_SIZ) 

  if (data == nil) then
    error("data == nil")
  end

  dir = tostring(data)
  offset = offset + #data

  while (true) do
    data = ctx.np:read(f, offset, READ_BUF_SIZ)

    if (data == nil) then
      break
    end
    local data_str = tostring(data)

    dir = dir .. data_str
    offset = offset + #data_str
  end

  ctx.np:clunk(f)
  return dir
end

return mine9p
