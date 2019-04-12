--
-- ip 服务接口
-- 1.geo中获取
-- 2.redis中获取
-- 3.数据库中查询
-- 4.调用第三方接口
--

local request_method = ngx.var.request_method
local args
if "GET" == request_method then
    args = ngx.req.get_uri_args()
elseif "POST" == request_method then
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
local ip = args["ipStr"]
local cjson = require "cjson.safe"
local conf = require "script.geodbconfig"

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

-- 查询本地库
local ip_table = conf.lua_string_split(",", ip);
local geodb = conf.geodb
local res = {}
for _, v in pairs(ip_table) do
    res[v] = geodb:search_ipv4(v)
end
local c = res[ip]
if c ~= nil then
	local country = c["country"]
	if country ~= nil then
		local cname = country["names"]["en"]
		local code = country["iso_code"]
		if cname ~= nil and code ~= nil and code ~= "-" then
			ngx.say(cjson.encode({
				code = 0,
				error = 0,
				data = {
						country=cname,
			        	country_id=code,
			        	area="",
			        	area_id="",
			        	region="",
			        	region_id="",
			        	city="",
			        	city_id="",
			        	isp="",
			        	isp_id="",
			        	ip=ip
					}    
				}))
			ngx.log(ngx.INFO,"geo mmdb,ip:"..ip..",code:"..code)
			return
		end	
	end
end

local redis_db = require "script.init_redis"
local mysql = require "script.init_mysql"
local db = mysql:getConn()
local redis = redis_db:getConn()

-- 先查缓存
if redis then
	country_id = redis:hget(key_ip,ip)
	if type(country_id) == "userdata" then -- hget 数据为空,类型为userdata
		-- 查询数据库
		local get_sql = "select ip,country_id from v_ipcenter where ip ='"..ip.."' limit 1"
		local res3, err3, errno3, sqlstate3 = db:query(get_sql)
		for i,v in ipairs(res3) do 
			ngx.log(ngx.INFO,'mysql query ==>>'..v["country_id"])
			country_id = v['country_id']
		end
		if country_id ~= nil and type(country_id) ~= "userdata" then
			redis:hset(key_ip,ip,country_id)
		end
	end
	ngx.log(ngx.INFO,"country_id type is ==>>"..type(country_id)..",ip: "..ip)
	if country_id ~= nil and type(country_id) ~= "userdata" then
		local en_name,name_err = redis:hget(key_code..country_id,field_en_name)
		ngx.log(ngx.INFO,"en_name type is ==>>"..type(en_name)..",country_id:"..country_id..",ip:"..ip)
		if type(en_name) ~= "userdata" then
			result = result_prefix..en_name..result_middle..country_id..result_suffix
		else
			result = result_prefix..country_id..result_middle..country_id..result_suffix
		end
		ngx.say(result)
		return redis_db:close_db(redis)
	end
	country_id = nil
end

result = {
		code=0,
		error=0,
		data={
				country="United States of America",
				country_id="US",
				area="",
				area_id="",
				region="",
				region_id="",
				city="",
				city_id="",
				county="",
				county_id="",
				isp="",
				isp_id="",
				ip=ip
		}
	}
	ngx.say(cjson.encode(result))
return