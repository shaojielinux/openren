
local result
local country_id
local insert_sql = "" 

-- 调用后端第三方查询ip服务
local ipapi = {}

function ipapi:getResponse(hc,cjson,ip)
	local res2,err2  = hc:request_uri("http://ip-api.com/json/"..ip, {
        method = "get",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2657.3 Safari/537.36",
        }
      }) 
    if res2 ~= nil  then
		result = cjson.decode(res2.body)
		if result ~=nil and result["status"] == "success" then
			local country = result["country"]
			country_id = result["countryCode"]
			local area = result["area"]
			local area_id = result["area_id"]
			local region = result["region"]
			local region_id = result["region_id"]
			local city = result["city"]
			local city_id = result["city_id"]
			local county = result["county"]
			local county_id = result["county_id"]
			local isp = result["isp"]
			local isp_id = result["isp_id"]
			local ip = result["query"]
			if country_id ~= nil then
				insert_sql = 'insert into v_ipcenter values  (0,"'..country..'","'..country_id..'","","","","","","","","","","","'..ip..'","'..ngx.localtime()..'")'
				ngx.log(ngx.INFO,"ipapi==>>"..insert_sql)
				return country_id,insert_sql,country
			end
		else
			country_id = nil
			ngx.log(ngx.INFO,"ipai api result error ==>>"..cjson.encode(result)..",ip:"..ip)
		end
	end
	return country_id,insert_sql 
end

return ipapi