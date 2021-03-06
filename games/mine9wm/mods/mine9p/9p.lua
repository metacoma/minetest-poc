--[[
Copyright (c) 2014-2020 Iruatã M.S. Souza <iru.muzgo@gmail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the Author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
]]


local data = require'data'

local np = {}

-- message types
local Tversion = 100
local Rversion = 101
local Tauth    = 102
local Rauth    = 103
local Tattach  = 104
local Rattach  = 105
local Rerror   = 107
local Tflush   = 108
local Rflush   = 109
local Twalk    = 110
local Rwalk    = 111
local Topen    = 112
local Ropen    = 113
local Tcreate  = 114
local Rcreate  = 115
local Tread    = 116
local Rread    = 117
local Twrite   = 118
local Rwrite   = 119
local Tclunk   = 120
local Rclunk   = 121
local Tremove  = 122
local Rremove  = 123
local Tstat    = 124
local Rstat    = 125
local Twstat   = 126
local Rwstat   = 127
local Tmax     = 128

local HEADSZ   = 7
local FIDSZ    = 4
local QIDSZ    = 13
local IOHEADSZ = 24  -- io (Twrite/Rread) header size, i.e. minimum msize

local map = {}
map[100] = "Tversion"
map[101] = "Rversion"
map[102] = "Tauth"
map[103] = "Rauth"
map[104] = "Tattach"
map[105] = "Rattach"
map[107] = "Rerror"
map[108] = "Tflush"
map[109] = "Rflush"
map[110] = "Twalk"
map[111] = "Rwalk"
map[112] = "Topen"
map[113] = "Ropen"
map[114] = "Tcreate"
map[115] = "Rcreate"
map[116] = "Tread"
map[117] = "Rread"
map[118] = "Twrite"
map[119] = "Rwrite"
map[120] = "Tclunk"
map[121] = "Rclunk"
map[122] = "Tremove"
map[123] = "Rremove"
map[124] = "Tstat"
map[125] = "Rstat"
map[126] = "Twstat"
map[127] = "Rwstat"
map[128] = "Tmax"


local client_pos = {
  x = 10,
  y = 40,
  z = 10,
} 

local client_entity = nil

local tcp_servers = {}
local servers = 0

local function get_new_server_pos()   
  local new_pos = {}
  local delta = 15
  minetest.log("tcp servers count " .. #tcp_servers)
  if (servers == 0) then
      new_pos = {
        x = client_pos.x + delta,
        y = client_pos.y,
        z = client_pos.z + delta,
      } 
    else 
      new_pos = {
        x = -client_pos.x, 
        y = client_pos.y,
        z = -client_pos.z 
      } 
  end
  servers = servers + 1
   
  return new_pos
end

packet_queue = {} 

packet_count = 0

  

function show_packet() 
  if (#packet_queue == 0) then
    return
  end
   
  local packet = packet_queue[1] 

  local packet_entity = minetest.add_entity(packet["from_pos"], "mine9p:Nine9Packet")

  packet_entity:get_luaentity():set_dest(packet["peername"])

  packet_entity:set_acceleration(vector.direction(packet["from_pos"], packet["to_pos"]))
  local texture = "mine9p_" .. packet["packet_name"] .. ".png"
  packet_entity:set_properties({
    textures = { texture, texture, texture, texture, texture, texture },
    base_texture = texture
  }) 

  table.remove(packet_queue, 1)

end

function add_packet_to_show_queue(ctx, type) 

  local peername = ctx.connection:getpeername()
  local server_entity = tcp_servers[peername]

  local from_pos = client_pos
  local to_pos = server_entity:get_pos()
  
  packet_count = packet_count + 1

  local packet_name = map[type]

  if (packet_name:sub(1,1) == "R") then
    from_pos = server_entity:get_pos()
    to_pos = client_pos
    peername = "client"
  end

  minetest.log("QUEUE packet to  " .. peername .. " type " .. packet_name .. " from: " .. dump(from_pos) .. " to: " .. dump(to_pos))

  table.insert(packet_queue, {
    from_pos = from_pos,
    to_pos = to_pos,
    packet_name = packet_name,
    peername = peername
  }) 

  minetest.after(packet_count, show_packet)
end

function np.newfid(conn)
  local f = conn.fidfree

  if f then
    conn.fidfree = f.next
  else
    f = {
      fid = conn.nextfid,
      qid = nil,
      next = conn.fidactive,
    }
    
    conn.nextfid = conn.nextfid + 1;
    conn.fidactive = f
  end

  return f
end

local function freefid(conn, f)
  f.next = conn.fidfree
  conn.fidfree = f
end

local function tag(conn)
  local t = conn.curtag
  conn.curtag = (conn.curtag + 1) % 0xFFFF
  return t
end

-- Returns a 9P number in table format. Offset and size in bytes
local function num9p(offset, size)
  return {offset*8, size*8, 'number', 'le'}
end

local function putstr(to, s)
  if #s > #to - 2 then
    return 0
  end

  local p = to:segment()
  p:layout{
    len = num9p(0, 2),
    s   = {2, #s, 's'},
  }

  p.len = #s
  p.s = s
  return 2 + #s
end

local function getstr(from)
  local p = from:segment():layout{len = num9p(0, 2)}
  p:layout{str = {2, p.len, 's'}}

  return p.str or ""
end

local function readmsg(ctx, type)
  local rawsize, rawrest

  if (ctx.connection ~= nil) then
      add_packet_to_show_queue(ctx, type)
      rawsize = ctx.connection:receive(4)
    else
      rawsize = io.read(4)
  end

  local bsize = data.new(rawsize):segment()
  local size = bsize:layout{size = num9p(0, 4)}.size

  if (ctx.connection ~=  nil) then
    rawrest = ctx.connection:receive(size - 4)
    else
    rawrest = io.read(size - 4)
  end

  local buf = data.new(rawsize .. rawrest):segment()

  local p = buf:layout{
    size = num9p(0, 4),
    type = num9p(4, 1)
  }

  if p.type ~= type then
    if p.type == Rerror then
      error(getstr(p:segment(HEADSZ)))
    else
      error("Wrong response type " .. p.type .. ", expected " .. type)
    end
  end

  return buf
end

local function writemsg(connection, buf)
  if (connection ~= nil) then
    connection:send(tostring(buf)) 
  else
    io.write(tostring(buf))
    io.output():flush()
  end
  
end

local LQid = data.layout{
  type    = num9p(0, 1),
  version = num9p(1, 4),
  path    = num9p(5, 8),
}

local function getqid(from)
  if #from < QIDSZ then
    return nil
  end

  local p = from:segment():layout(LQid)
  local qid = {}

  qid.type    = p.type
  qid.version = p.version
  qid.path    = p.path

  return qid
end

local function putqid(to, qid)
  if #to < QIDSZ then
    return nil
  end

  local p = to:segment():layout(LQid)
  p.type    = qid.type
  p.version = qid.version
  p.path    = qid.path
  return to
end

local Lstat = data.layout{
  size   = num9p(0,  2),
  type   = num9p(2,  2),
  dev    = num9p(4,  4),
  qid    = num9p(8,  QIDSZ),
  mode   = num9p(21, 4),
  atime  = num9p(25, 4),
  mtime  = num9p(29, 4),
  length = num9p(33, 8),
}

function np.getstat(connection, seg)
  return getstat(seg)
end


function getstat(seg)
  local p = seg:segment():layout(Lstat)
  local st = {}

  st.size   = p.size
  st.type   = p.type
  st.dev    = p.dev
  st.qid    = getqid(seg:segment(8))
  if not st.qid then
    return nil
  end

  st.mode   = p.mode
  st.atime  = p.atime
  st.mtime  = p.mtime
  st.length = p.length
  st.name   = getstr(seg:segment(41))
  st.uid    = getstr(seg:segment(41 + 2 + #st.name))
  st.gid    = getstr(seg:segment(41 + 2 + #st.name + 2 + #st.uid))
  st.muid   = getstr(seg:segment(41 + 2 + #st.name + 2 + #st.uid + 2 + #st.gid))

  return st
end

local function putstat(to, st)
  local p = to:segment():layout(Lstat)

  p.size = st.size
  p.type = st.type
  p.dev  = st.dev

  if not putqid(to:segment(8), st.qid) then
    return nil
  end

  p.mode   = st.mode
  p.atime  = st.atime
  p.mtime  = st.mtime
  p.length = st.length
  putstr(to:segment(41), st.name)
  putstr(to:segment(41 + 2 + #st.name), st.uid)
  putstr(to:segment(41 + 2 + #st.name + 2 + #st.uid), st.gid)
  putstr(to:segment(41 + 2 + #st.name + 2 + #st.uid + 2 + #st.gid), st.muid)

  return to
end

local function putheader(to, type, size, tag)
  local Lheader = data.layout{
    size = num9p(0, 4),
    type = num9p(4, 1),
    tag  = num9p(5, 2),
  }

  local p = to:segment():layout(Lheader)

  p.size = HEADSZ + size
  p.type = type
  p.tag  = tag
  return p.size
end


local function doversion(conn, msize)
  local LXversion = data.layout{msize = num9p(HEADSZ, 4)}

  local buf = data.new(19)
  buf:layout(LXversion)
  buf.msize = msize or 8192+IOHEADSZ

  local n = putstr(buf:segment(HEADSZ + 4), "9P2000")
  n = putheader(buf, Tversion, 4 + n, tag(conn))
  writemsg(conn.connection, buf)

  local buf = readmsg(conn, Rversion)
  buf:layout(LXversion)

  if buf.msize < IOHEADSZ then
    error("short msize")
  end

  return buf.msize
end

local function doattach(conn, uname, aname)
  local LTattach = data.layout{
    fid  = num9p(HEADSZ,          FIDSZ),
    afid = num9p(HEADSZ + FIDSZ,  4),
  }

  local tx = conn.txbuf:segment()
  tx:layout(LTattach)

  local fid = conn:newfid()
  tx.fid  = fid.fid
  tx.afid = -1
  local n = putstr(tx:segment(HEADSZ + FIDSZ + FIDSZ), uname)
  n = n + putstr(tx:segment(HEADSZ + FIDSZ + FIDSZ + n), aname)
  
  n = putheader(tx, Tattach, FIDSZ + FIDSZ + n, tag(conn))
  writemsg(conn.connection, tx:segment(0, n))

  local rx = readmsg(conn, Rattach)

  fid.qid = getqid(rx:segment(HEADSZ))
  if not fid.qid then
    error("attach: overflow copying qid")
  end

  return fid
end

function np.attach(connection, uname, aname, msize, endpoint)
  local conn = np
  conn.curtag = 0xFFFF

  conn.fidfree   = nil
  conn.fidactive = nil
  conn.nextfid   = 0
  conn.connection = connection

  if (client_entity == nil) then
    client_entity = minetest.add_entity(client_pos, "mine9p:Nine9Client") 
    client_entity:set_nametag_attributes({
      Colorspec = {a = 255, r = 255, g = 13, b = 14},
      text = "minetest",
    }) 

    local node_metadata_ref = minetest.get_meta(client_pos) 
    local r = node_metadata_ref:from_table({ 
      fields = {
        name = "client"
      } 
    }) 

  end
  
  local peername = conn.connection:getpeername()

  if (tcp_servers[peername] == nil) then
    local server_pos = get_new_server_pos() 
    tcp_servers[peername] = minetest.add_entity(server_pos, "mine9p:Nine9Server")

    tcp_servers[peername]:set_nametag_attributes({
      Colorspec = {a = 255, r = 255, g = 13, b = 14},
      text = peername,
    }) 
    local node_metadata_ref = minetest.get_meta(server_pos) 
    local r = node_metadata_ref:from_table({ 
      fields = {
        name = peername
      } 
    }) 

    assert(r == true)


    
    local test = minetest.get_meta(server_pos)
    minetest.log(dump(server_pos) .. " " .. dump(test:to_table()))
  end
  --show_packet(conn, Tattach)
  add_packet_to_show_queue(conn, Tattach)

  -- WHY IT'S NOT WORKING???
  -- if (sock ~= nil) then
    --conn.socket = socket.tcp() 
    --conn.socket:connect(endpoint["host"], endpoint["port"])
    --printf("connect to tcp!" .. endpoint["host"] .. "!" .. endpoint["port"] .."\n") 
       
     -- io.close(io.stdin)
     -- io.close(io.stdout)

     -- posix.dup2(sock, 0)
     -- posix.dup2(sock, 1)

     -- posix.dup2(0, sock)
     -- posix.dup2(1, sock)
     -- print("Remap!")
  -- end


  local msize = doversion(conn, msize)
  conn.txbuf = data.new(msize)

  conn.rootfid = doattach(conn, uname, aname)
  return conn
end


local function breakpath(path)
  local t = {}
  local k = 1
  local i = 1

  while i < #path do
    local s, es = string.find(path, "[^/]+", i)
    t[k] = string.sub(path, s, es)
    k = k + 1
    i = es + 1
  end
  return t
end

-- path == nil clones ofid to nfid
function np.walk(conn, ofid, nfid, path)
  local LTwalk = data.layout{
    fid    = num9p(HEADSZ,                  FIDSZ),
    newfid = num9p(HEADSZ + FIDSZ,          FIDSZ),
    nwname = num9p(HEADSZ + FIDSZ + FIDSZ,  2),
  }

  local tx = conn.txbuf:segment()
  tx:layout(LTwalk)
  tx.fid    = ofid.fid
  tx.newfid = nfid.fid

  local n = 0
  if path then
    local names = breakpath(path)
    tx.nwname = #names
    for i = 1, #names do
      n = n + putstr(tx:segment(HEADSZ + FIDSZ + FIDSZ + 2 + n), names[i])
    end
  else
    tx.nwname = 0
  end

  n = putheader(tx, Twalk, FIDSZ + FIDSZ + 2 + n, tag(conn))
  writemsg(conn.connection, tx:segment(0, n))
  add_packet_to_show_queue(conn, Twalk)

  local rx = readmsg(conn, Rwalk)
  rx:layout{nwqid = num9p(HEADSZ, 2)}

  -- clone succeeded
  if rx.nwqid == 0 and not path then
    nfid.qid = ofid.qid
    return
  end

  -- walk succeeded
  if rx.nwqid == tx.nwname then
    nfid.qid = getqid(rx:segment(HEADSZ + 2 + (rx.nwqid-1)*QIDSZ))
    return
  end

  error("file '" .. path .. "' not found")
end

function np.clone(conn, ofid, nfid)
  np.walk(conn, ofid, nfid)
end

function np.open(conn, fid, mode)
  local tx = conn.txbuf:segment():layout{
    fid  = num9p(HEADSZ,          FIDSZ),
    mode = num9p(HEADSZ + FIDSZ,  1),
  }

  tx.fid  = fid.fid
  tx.mode = mode

  local n = putheader(tx, Topen, 5, tag(conn))
  writemsg(conn.connection, tx:segment(0, n))
  add_packet_to_show_queue(conn, Topen)

  local rx = readmsg(conn, Ropen)

  fid.qid = getqid(rx:segment(HEADSZ))
  if not fid.qid then
    error("overflow copying qid")
  end
end

function np.create(conn, fid, name, perm, mode)
  local tx = conn.txbuf:segment()
  local n = putstr(tx:segment(11), name)
  
  tx:layout{
    fid  = num9p(HEADSZ,                  FIDSZ),
    perm = num9p(HEADSZ + FIDSZ + n,      4),
    mode = num9p(HEADSZ + FIDSZ + n + 4,  1),
  }

  tx.fid  = fid.fid
  tx.perm = perm
  tx.mode = mode

  local n = putheader(tx, Tcreate, n + 9, tag(conn))
  writemsg(conn.connection, tx:segment(0, n))
  add_packet_to_show_queue(conn, Tcreate)

  local rx = readmsg(conn, Rcreate)


  fid.qid = getqid(rx:segment(HEADSZ))
  if not fid.qid then
    error("overflow copying qid")
  end
end
                   
function np.read(conn, fid, offset, count)
  local tx = conn.txbuf:segment():layout{
    fid    = num9p(HEADSZ,              FIDSZ),
    offset = num9p(HEADSZ + FIDSZ,      8),
    count  = num9p(HEADSZ + FIDSZ + 8,  4),
  }

  tx.fid    = fid.fid
  tx.offset = offset
  tx.count  = count

  local n = putheader(tx, Tread, FIDSZ + 8 + 4, tag(conn))
  writemsg(conn.connection, tx:segment(0, n))
  add_packet_to_show_queue(conn, Tread)

  local rx = readmsg(conn, Rread)
  rx:layout{count = num9p(HEADSZ, 4)}
  return rx:segment(HEADSZ + 4, rx.count)
end

function np.write(conn, fid, offset, seg)
  local tx = conn.txbuf:segment():layout{
    fid    = num9p(HEADSZ,              FIDSZ),
    offset = num9p(HEADSZ + FIDSZ,      8),
    count  = num9p(HEADSZ + FIDSZ + 8,  4),
  }

  tx.fid    = fid.fid
  tx.offset = offset
  tx.count  = #seg

  local n = putheader(tx, Twrite, FIDSZ + 8 + 4 + #seg, tag(conn))
  writemsg(conn.connection, tx:segment(0, n - #seg))
  writemsg(conn.connection, seg:segment(0, #seg))
  add_packet_to_show_queue(conn, Twrite)

  local rx = readmsg(conn, Rwrite)
  rx:layout{count = num9p(HEADSZ, 4)}
  return rx.count
end

local function clunkrm(conn, type, fid)
  local tx = conn.txbuf:segment():layout{fid = num9p(HEADSZ, FIDSZ)}
  tx.fid = fid.fid

  local n = putheader(tx, type, FIDSZ, tag(conn))
  writemsg(conn.connection, tx:segment(0, n))
  add_packet_to_show_queue(conn, Tclunk)

  readmsg(conn, type+1)
  freefid(conn, fid)
end

function np.clunk(conn, fid)
  return clunkrm(conn, Tclunk, fid)
end

function np.remove(conn, fid)
  return clunkrm(conn, Tremove, fid)
end

function np.stat(conn, fid)
  local tx = conn.txbuf:segment():layout{fid = num9p(HEADSZ, FIDSZ)}
  tx.fid = fid.fid

  local n = putheader(tx, Tstat, FIDSZ, tag(conn))
  writemsg(conn.connection, tx:segment(0, n))
  add_packet_to_show_queue(conn, Tstat)
  
  local rx = readmsg(conn, Rstat)
  return getstat(rx:segment(HEADSZ + 2))
end

function np.wstat(conn, fid, st)
  local tx = conn.txbuf:segment():layout{
    fid    = num9p(HEADSZ,          FIDSZ),
    stsize = num9p(HEADSZ + FIDSZ,  2),
  }

  tx.fid    = fid.fid
  tx.stsize = st.size + 2

  local n = putheader(tx, Twstat, FIDSZ + 2 + tx.stsize, tag(conn))
  writemsg(conn.connection, tx:segment(0, n - tx.stsize))
  add_packet_to_show_queue(conn, Twstat)

  local seg = conn.txbuf:segment(n - tx.stsize)

  if not putstat(seg, st) then
    error("tx buffer too small")
  end

  writemsg(conn.connection, seg:segment(0, tx.stsize))
  return readmsg(conn, Rwstat)
end


return np
