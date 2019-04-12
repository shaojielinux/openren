--
-- 
-- User: leandre
-- Date: 16/5/14
-- Time: 21:32
--

local _M = {}

_M.filepath = "/apps/openresty/lualib/script/GeoLite2-Country.mmdb";

_M.geodb = nil;

function _M:load_db()
    if (self.geodb == nil) then
        local mmdb = require "script.mmdb"
        self.geodb = mmdb.open(self.filepath)
    end
end

function _M.lua_string_split(split_char, str)
    local sub_str_tab = {}
    local i = 0
    local j = 0
    while true do
        j = string.find(str, split_char, i + 1)
        if j == nil then
            table.insert(sub_str_tab, string.sub(str, i + 1))
            break
        end
        table.insert(sub_str_tab, string.sub(str, i + 1, j - 1))
        i = j
    end
    return sub_str_tab
end

_M:load_db()

return _M;
