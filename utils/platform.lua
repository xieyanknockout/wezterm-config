local wezterm = require('wezterm')

local cached_platform = nil

local function platform()
    if cached_platform then
        return cached_platform
    end

    local target = wezterm.target_triple or ""
    local is_win = target:find("windows") ~= nil
    local is_linux = target:find("linux") ~= nil
    local is_mac = target:find("apple") ~= nil

    -- Windows 专用检测（通过文件路径查找 pwsh，避免 spawn 进程导致 UI 卡顿）
    local has_pwsh = false
    if is_win then
        local userprofile = os.getenv('USERPROFILE') or wezterm.home_dir or ''
        local pwsh_paths = {
            [[C:\Program Files\PowerShell\7\pwsh.exe]],
            [[C:\Program Files (x86)\PowerShell\7\pwsh.exe]],
            [[C:\Program Files\PowerShell\7-preview\pwsh.exe]],
            [[C:\Program Files\PowerShell\6\pwsh.exe]],
            userprofile .. [[\AppData\Local\Microsoft\WindowsApps\pwsh.exe]],
            [[C:\ProgramData\chocolatey\bin\pwsh.exe]],
        }
        for _, path in ipairs(pwsh_paths) do
            local f = io.open(path, 'r')
            if f then
                f:close()
                has_pwsh = true
                break
            end
        end

        -- winget/Store 安装：App Execution Alias 无法用 io.open 打开
        -- 通过 PATH 中的 windowsapps 条目判断 pwsh 别名是否可用
        if not has_pwsh then
            local path_env = os.getenv('PATH') or ''
            for dir in path_env:gmatch('[^;]+') do
                if dir:lower():find('windowsapps') then
                    has_pwsh = true
                    break
                end
            end
        end

        -- PATH 回退（通用兜底）
        if not has_pwsh then
            local path_env = os.getenv('PATH') or ''
            for dir in path_env:gmatch('[^;]+') do
                local f = io.open(dir .. '\\pwsh.exe', 'r')
                if f then
                    f:close()
                    has_pwsh = true
                    break
                end
            end
        end
    end

    cached_platform = {
        os = is_win and "windows" or is_linux and "linux" or is_mac and "mac" or "unknown",
        is_win = is_win,
        is_linux = is_linux,
        is_mac = is_mac,
        has_pwsh = has_pwsh
    }

    return cached_platform
end

return platform
