local data = require 'data'
local np = require '9p'

local ORDONLY = 0
local OWRITE = 1
local ORDWR = 2
local OEXEC = 3 

local READ_BUF_SIZ = 4096

function _9p_readdir(ctx, path) 
  local f = ctx:newfid()
  local offset = 0
  local dir, data = nil, nil

  ctx:walk(ctx.rootfid, f, path) 
  ctx:open(f, ORDONLY)  

  data = ctx:read(f, offset, READ_BUF_SIZ) 
  dir = tostring(data)
  --pprint(data)
  offset = offset + #data

  while (true) do
    data = ctx:read(f, offset, READ_BUF_SIZ)

    if (data == nil) then
      break
    end
    dir = dir .. tostring(data)
    offset = offset + #(tostring(data))
  end

  print("Read " .. #dir .. " bytes")
  ctx:clunk(f)
  return dir
end

function readdir(ctx, path) 
  local dir = {}
  local dirdata = _9p_readdir(ctx, path)
  while 1 do
    local st = ctx:getstat(data.new(dirdata))   
    table.insert(dir, st)
    dirdata = string.sub(dirdata, st.size + 3) 
    if (#dirdata == 0) then
      break
    end
  end
  return dir
end
