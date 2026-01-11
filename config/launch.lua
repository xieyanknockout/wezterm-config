local platform = require('utils.platform')()

-- 读取 SSH 配置文件中的主机
local function get_ssh_hosts()
   local hosts = {}
   local ssh_config_path = os.getenv('USERPROFILE') .. '/.ssh/config'

   -- 尝试读取 SSH config 文件
   local file = io.open(ssh_config_path, 'r')
   if not file then
      return hosts
   end

   local current_host = nil
   for line in file:lines() do
      -- 去除首尾空白
      line = line:match('^%s*(.-)%s*$')
      -- 跳过注释和空行
      if not line:match('^#') and line ~= '' then
         local key, value = line:match('^%s*(%w+)%s+(.+)$')
         if key then
            key = key:lower()
            if key == 'host' then
               -- Host * 是通配符，跳过
               if value ~= '*' then
                  current_host = value
               else
                  current_host = nil
               end
            elseif key == 'hostname' and current_host then
               table.insert(hosts, {
                  label = 'SSH: ' .. current_host,
                  args = { 'ssh', current_host },
               })
            end
         end
      end
   end
   file:close()

   return hosts
end

-- 读取 known_hosts 中的主机
local function get_known_hosts()
   local hosts = {}
   local known_hosts_path = os.getenv('USERPROFILE') .. '/.ssh/known_hosts'

   local file = io.open(known_hosts_path, 'r')
   if not file then
      return hosts
   end

   local seen = {}
   for line in file:lines() do
      -- 跳过注释和空行
      if not line:match('^#') and line ~= '' then
         -- 提取主机名（第一列），跳过哈希标记的行
         local host = line:match('^([%w%.%-]+)')
         if host and not seen[host] then
            seen[host] = true
            table.insert(hosts, {
               label = 'SSH: ' .. host,
               args = { 'ssh', host },
            })
         end
      end
   end
   file:close()

   return hosts
end

local options = {
   default_prog = {},
   launch_menu = {},
}

if platform.is_win then
   options.default_prog = { 'powershell' }
   options.launch_menu = {
      { label = 'PowerShell 5', args = { 'powershell' } },
      { label = '命令提示符', args = { 'cmd' } },
   }
   if platform.has_pwsh then
    options.default_prog = { 'pwsh' }
    options.launch_menu = {
       { label = 'PowerShell 7', args = { 'pwsh' } },
       { label = 'PowerShell 5', args = { 'powershell' } },
       { label = '命令提示符', args = { 'cmd' } },
    }
   end

   -- 添加 WSL 和 SSH 主机到快速启动菜单
   local ssh_hosts = get_ssh_hosts()
   local known_hosts = get_known_hosts()

   -- 合并所有远程主机（WSL + SSH）
   local all_hosts = {}
   table.insert(all_hosts, { label = 'WSL: Ubuntu', args = { 'wsl' } })

   local seen = {}
   for _, host in ipairs(ssh_hosts) do
      if not seen[host.label] then
         table.insert(all_hosts, host)
         seen[host.label] = true
      end
   end
   for _, host in ipairs(known_hosts) do
      if not seen[host.label] then
         table.insert(all_hosts, host)
         seen[host.label] = true
      end
   end

   -- 添加本机选项（PowerShell 和 WSL）
   table.insert(options.launch_menu, { label = 'WSL: Ubuntu', args = { 'wsl' } })

   -- 添加分隔符和远程 SSH 主机
   local has_remote_hosts = false
   for _, host in ipairs(all_hosts) do
      if host.label:match('^SSH:') then
         if not has_remote_hosts then
            table.insert(options.launch_menu, { label = '─────────────────────' })
            has_remote_hosts = true
         end
         table.insert(options.launch_menu, host)
      end
   end
elseif platform.is_mac then
   options.default_prog = { '/opt/homebrew/bin/fish', '-l' }
   options.launch_menu = {
      { label = 'Bash', args = { 'bash', '-l' } },
      { label = 'Fish', args = { '/opt/homebrew/bin/fish', '-l' } },
      { label = 'Nushell', args = { '/opt/homebrew/bin/nu', '-l' } },
      { label = 'Zsh', args = { 'zsh', '-l' } },
   }
elseif platform.is_linux then
   options.default_prog = { 'fish', '-l' }
   options.launch_menu = {
      { label = 'Bash', args = { 'bash', '-l' } },
      { label = 'Fish', args = { 'fish', '-l' } },
      { label = 'Zsh', args = { 'zsh', '-l' } },
   }
end

return options
