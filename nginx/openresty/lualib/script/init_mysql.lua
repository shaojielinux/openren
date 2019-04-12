--
-- mysql 配置文件
--


local mysql = {}
local sql = require "resty.mysql"
local dbconf = require "script.env_config"
local dns = require "script.dns_resolver"



function mysql:getConn()
	local props = {  
	    host = dns:_get_addr(dbconf.db_host),  
	    port = dbconf.db_port,  
	    database = dbconf.db_database,  
	    user = dbconf.db_user,  
	    password = dbconf.db_password  
	}
	local db = sql:new()
	db:set_timeout(2000)
	local res, err, errno, sqlstate = db:connect(props)
	if not res then
		ngx.log(ngx.ERR,"mysql connection error :"..err)
		close_db(db)
	end
	return db
end

function mysql:close_db(db)
	db:set_keepalive(10000,50) 
	if not db then
		 ngx.log(ngx.ERR,"mysql keepalive err")
	end
end

return mysql
