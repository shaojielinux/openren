--
-- redis配置文件
--

local redis = {}
local re = require "resty.redis"
local reconf = require "script.env_config"
local dns = require "script.dns_resolver"

function redis:getConn()
	local db = re:new()
	db:set_timeout(2000)
	local ok, err = db:connect(dns:_get_addr(reconf.redis_host), reconf.redis_port)
	if not ok then
		ngx.log(ngx.ERR,"redis connection error :"..err)
		close_db(db)
	end
	return db
end

function redis:close_db(db)
	db:set_keepalive(10000,50) 
	if not db then
		 ngx.log(ngx.ERR,"redis keepalive err ")
	end
end

return redis
