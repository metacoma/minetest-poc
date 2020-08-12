local mine9p = require 'mine9p'
local auth = false


function print_dir(ctx, path) 
  local dir_content = ctx:readdir(path)

  for _, file in pairs(dir_content) do
    print(file.name)
  end
  
end

function remote_exec(ctx, cmd)
  ctx:write("/chan/exec", cmd)
end

function remote_mount(ctx, source, target, auth)
  if (auth == true) then
    error("Auth is not currently supported")
  end

  local remote_shell_cmd = string.format("{ ns | grep 'mount %s %s' >/dev/null || { test -d %s || mkdir -p %s; mount -A %s %s; } }\n", target, source, target, target, source, target)
  remote_exec(ctx, remote_shell_cmd) 

  return target
end

local m9 = mine9p.mount("tcp!192.168.1.132!1025")

--remote_mount(m9, "tcp!192.168.1.133!6666", "/tmp/9gridchan") 
--remote_exec(m9, "ns")
--print_dir(m9, target)
print_dir(m9, "./")
local file = m9:readfile("./makemk.sh")
print(file)
