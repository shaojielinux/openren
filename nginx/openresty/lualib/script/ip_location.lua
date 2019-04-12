--
-- ip 服务地理位置接口
-- 1.geo中获取
--

local request_method = ngx.var.request_method
local args
if "GET" == request_method then
    args = ngx.req.get_uri_args()
elseif "POST" == request_method then
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
local headers=ngx.req.get_headers()  
-- 有参数从参数中获取，不传参数，根据请求获取
local ip= args["ipStr"] or headers["X-REAL-IP"] or headers["X_FORWARDED_FOR"] or ngx.var.remote_addr or "0.0.0.0" 
local cjson = require "cjson.safe"
local confcity = require "script.geocityconfig"
local callback = args["callback"]
local result 
-- 查询本地库
local ip_table = confcity.lua_string_split(",", ip);
local citydb = confcity.geodb
local res = {}
for _, v in pairs(ip_table) do
    res[v] = citydb:search_ipv4(v)
end
local c = res[ip]
if c ~= nil and c["country"] ~= nil and c["country"]["iso_code"] ~= nil then
	local country = c["country"]
	local country_names = country["names"]
	local city_names = c["city"]["names"]
	local location = c["location"]
	local continent_names = c["continent"]["names"]
	local iso_code = c["country"]["iso_code"]
	local result = {}
	if country_names ~= nil and iso_code ~= nil then
			result = cjson.encode({
				error = 0,
				ip = ip,
				iso_code = iso_code,
				country = country_names,
				city = city_names,
				location = location,
				continent = continent_names
				})
		if callback ~= nil then
			ngx.say(callback.."("..result..")")
		else
			ngx.say(result)
		end
		ngx.log(ngx.INFO,"geo city mmdb,ip:"..ip..",code:"..iso_code)
		return
	end	
else 
	-- 取不到城市信息，优先取国家信息
	local conf = require "script.geodbconfig"
	local geodb = conf.geodb
	for _, v in pairs(ip_table) do
		ngx.log(ngx.ERR,"ipnew==>>"..v)
	    res[v] = geodb:search_ipv4(v)
	end
	local c = res[ip]
	local code = "unknown"
	if c ~= nil and c["country"] ~= nil and c["country"]["iso_code"] ~= nil then
		code = c["country"]["iso_code"]
	end
	result = cjson.encode({
					error = 1,
					ip = ip,
					iso_code = code,
					country = "",
					city = "",
					location = "",
					continent = ""
					})
	if callback ~= nil then
		ngx.say(callback.."("..result..")")
	else
		ngx.say(result)
	end	
	ngx.log(ngx.ERR,"geo city can't find this ip,ip:"..ip)
	return 
end
