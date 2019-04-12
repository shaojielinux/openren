
local result
local country_id
local insert_sql = "insert into v_ipcenter values " 

-- 调用后端第三方查询ip服务
local ipinfodb = {}

function ipinfodb:getResponse(hc,cjson,ip)
	local res2,err2  = hc:request_uri("http://api.ipinfodb.com/v3/ip-city/?key=dcfe6d9ea2cf1588c1d1a94e1eb96e09018e22feff528c8230d22d1806eac11e&format=json&ip="..ip, {
        method = "get",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2657.3 Safari/537.36",
        }
      }) 
    if res2.body ~= nil  then
		result = cjson.decode(res2.body)
		if result ~=nil and result["statusCode"] == "OK" then
			local country = result["countryName"]
			country_id = result["countryCode"]
			local area = result["area"]
			local area_id = result["area_id"]
			local region = result["regionName"]
			local region_id = result["region_code"]
			local city = result["cityName"]
			local city_id = result["city_id"]
			local county = result["county"]
			local county_id = result["county_id"]
			local isp = result["isp"]
			local isp_id = result["isp_id"]
			local ip = result["ipAddress"]
			if country_id ~= nil then
				insert_sql = 'insert into v_ipcenter values  (0,"'..country..'","'..country_id..'","","","","","","","","","","","'..ip..'","'..ngx.localtime()..'")'
				ngx.log(ngx.INFO,"ipinfodb==>>"..insert_sql)
				return country_id,insert_sql,country
			end
		else
			country_id = nil
			ngx.log(ngx.INFO,"ipinfodb api result error ==>>"..cjson.encode(result)..",ip:"..ip)
		end
	end
	return country_id,insert_sql 
end

return ipinfodb