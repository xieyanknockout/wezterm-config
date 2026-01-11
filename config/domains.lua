return {
   -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
   ssh_domains = {
     {
       name = '政协生产',
       username = 'root',
       remote_address = '172.21.82.143',
     },
   },

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   unix_domains = {},

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
   wsl_domains = {
      {
         name = 'WSL:Ubuntu',
         distribution = 'Ubuntu',
         username = 'root',
         default_cwd = '/root',
         default_prog = { 'zsh', '-l' },
      },
   },
}
