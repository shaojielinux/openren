local result
local country_id
local insert_sql = "insert into v_ipcenter values " 

-- 调用后端第三方查询ip服务
local taobao = {}
function taobao:getResponse(hc,cjson,ip)
	local res2,err2  = hc:request_uri("http://ip.taobao.com/service/getIpInfo.php?ip="..ip, {
        method = "get",
        headers = {
          ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2657.3 Safari/537.36",
        }
      }) 
    if res2 ~= nil  then
		result = cjson.decode(res2.body)
		if result ~=nil and result["code"] ==0 then
			local str = result["data"]
			local country = str["country"]
			country_id = str["country_id"]
			local area = str["area"]
			local area_id = str["area_id"]
			local region = str["region"]
			local region_id = str["region_id"]
			local city = str["city"]
			local city_id = str["city_id"]
			local county = str["county"]
			local county_id = str["county_id"]
			local isp = str["isp"]
			local isp_id = str["isp_id"]
			local ip = str["ip"]
			if country_id ~= nil then
				insert_sql = 'insert into v_ipcenter values  (0,"'..country..'","'..country_id..'","","","'..region..'","'..region_id..'","","","","","","","'..ip..'","'..ngx.localtime()..'")'
				ngx.log(ngx.INFO,"taobao==>>"..insert_sql)
				return country_id,insert_sql,country
			end
		else
			country_id = nil
			ngx.log(ngx.INFO,"taobao api result error ==>>"..cjson.encode(result)..",ip:"..ip)
		end 
	end
	return country_id,insert_sql
end

return taobao
