-- local ip = ngx.var.arg_ipStr

local request_method = ngx.var.request_method
local args
if "GET" == request_method then
    args = ngx.req.get_uri_args()
elseif "POST" == request_method then
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
local ip = args["ipStr"]
-- local shared_data = ngx.shared.shared_data 
local redis_db = require "script.init_redis"
local cjson = require "cjson"
local mysql = require "script.init_mysql"
local ipapi = require "script.third_ipapi"
local taobao = require "script.third_taobao"
local baidu = require "script.third_baidu"
local http = require "resty.http"
local freegeoip = require "script.third_freegeoip"
local nekudo = require "script.third_nekudo"
local ipinfodb = require "script.third_ipinfodb"

local db = mysql:getConn()
local redis = redis_db:getConn()
local hc = http:new()

local result_prefix = '{"code":0,"data":{"country":"'
local result_middle = '","country_id":"'
local result_suffix = '","area":"","area_id":"","region":"","region_id":"","city":"","city_id":"","county":"","county_id":"","isp":"","isp_id":"","ip":"'..ip..'"},"error":0}'
local key_taobao = "zeasn:common:ip:taobao" -- 淘宝ip是否可用
local result
local country_id
local insert_sql = "" 
local key_country = "zeasn:common:country:zh" -- 根据国家名称反查国家编码
local key_ip = "zeasn:common:data:ip"
local key_code = "zeasn:common:country_code:"
local field_zh_name = "zh"
local field_en_name = "en"

local function close_http(hc)  
    if not hc then  
        return  
    end  
    --释放连接(连接池实现)  
    local pool_max_idle_time = 10000 --毫秒  
    local pool_size = 100 --连接池大小  
    local ok, err = hc:set_keepalive(pool_max_idle_time, pool_size)  
    if not ok then  
        ngx.log(ngx.ERR,"set http keepalive error : ")  
    end  
end
-- 先查缓存
if redis then
	country_id = redis:hget(key_ip,ip)
	if type(country_id) == "userdata" then -- hget 数据为空,类型为userdata
		-- 查询数据库
		local ts=string.reverse(ip)
		local a,b=string.find(ts,'%p')
		local m=string.len(ts)-a+1
		local ip_like=string.sub(ip,1,m)
		local get_sql = "select ip,country_id from v_ipcenter where ip like '"..ip_like.."%' limit 1"
		local res3, err3, errno3, sqlstate3 = db:query(get_sql)
		for i,v in ipairs(res3) do 
			ngx.log(ngx.INFO,'mysql query ==>>'..v["country_id"])
			country_id = v['country_id']
		end
	end
	ngx.log(ngx.INFO,"country_id type is ==>>"..type(country_id)..",ip: "..ip)
	if type(country_id) ~= "userdata" then
		-- local zh_name,name_err = redis:hget(key_code..country_id,field_zh_name)
		local en_name,name_err = redis:hget(key_code..country_id,field_en_name)
		ngx.log(ngx.INFO,"en_name type is ==>>"..type(en_name))
		redis:hset(key_ip,ip,country_id)
		if type(en_name) ~= "userdata" then
			result = result_prefix..en_name..result_middle..country_id..result_suffix
			ngx.say(result)
			return redis_db:close_db(redis)
		end
	end
	country_id = nil
end


-- 调用后端第三方查询ip服务
local ran = math.random(1,11)

if ran < 3 then  -- 使用taobao的概率大一些
	country_id,insert_sql = taobao:getResponse(hc,cjson,ip)
elseif ran < 5 then
	country_id,insert_sql = freegeoip:getResponse(hc,cjson,ip)
-- elseif ran == 4 then 
--    country_id,insert_sql = baidu:getResponse(hc,cjson,redis,key_country,ip)
elseif ran < 7 then
	country_id,insert_sql = ipapi:getResponse(hc,cjson,ip)
elseif ran < 9 then
	country_id,insert_sql = nekudo:getResponse(hc,cjson,ip)
else
	country_id,insert_sql = ipinfodb:getResponse(hc,cjson,ip)
end

if country_id ~= nil then
	-- 新增到库
	local res3, err3, errno3, sqlstate3 = db:query(insert_sql)
	ngx.log(ngx.INFO,insert_sql)
	if not res3 then
		ngx.log(ngx.ERR,"insert sql error,err:"..err3..",errno:"..errno3..",sqlstats:"..sqlstate3)
	else
		-- 写入缓存
		redis:hset(key_ip,ip,country_id)
		local en_name,name_err = redis:hget(key_code..country_id,field_en_name)
		result = result_prefix..en_name..result_middle..country_id..result_suffix
		ngx.say(result)	
		ngx.log(ngx.INFO,"==>>ip:"..ip..",code:"..country_id)
		-- return 
	end
end
-- 默认返回值
if country_id == nil then
	result = '{"code":0,"data":{"country":"United States of America","country_id":"US","area":"","area_id":"","region":"","region_id":"","city":"","city_id":"","county":"","county_id":"","isp":"","isp_id":"","ip":"'..ip..'"},"error":0}'
	ngx.say(cjson.encode(result))
end

mysql:close_db(db)
redis_db:close_db(redis)