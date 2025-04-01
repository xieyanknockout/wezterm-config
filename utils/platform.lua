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

    -- Windows 专用检测（静默文件检查）
    local has_pwsh = false
    if is_win then
        local pwsh_paths = {[[C:\Program Files\PowerShell\7\pwsh.exe]],
                            [[C:\Program Files (x86)\PowerShell\7\pwsh.exe]],
                            wezterm.home_dir .. [[\AppData\Local\Microsoft\WindowsApps\pwsh.exe]]}
        for _, path in ipairs(pwsh_paths) do
            local file = io.open(path, "r")
            if file then
                file:close()
                has_pwsh = true
                break
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
