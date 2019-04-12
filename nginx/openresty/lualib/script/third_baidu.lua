local result
local country_id
local insert_sql = ""

local baidu = {}

function baidu:getResponse(hc,cjson,redis,key_country,ip)
 	local res3,err3 = hc:request_uri("http://apis.baidu.com/apistore/iplookupservice/iplookup?ip="..ip, {
		        method = "get",
		        headers = {
		          ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2657.3 Safari/537.36",
		          ["apikey"] = "e495cfb13bf726ceb490b7708b942002",
		        }
		    })

		-- 结果不为空
		if res3 ~= nil  then
			ngx.log(ngx.INFO, "baidu result==>>"..res3.body)
			result = cjson.decode(res3.body)
			if result["errNum"] ==0 then
				local str = result["retData"]
				local country = str["country"]
				country_id = redis:hget(key_country,country)
				local region = str["province"]
				local city = str["city"]
				local county = str["district"]
				local isp = str["carrier"]
				local ip = str["ip"]
				-- 拼接结果信息
				if type(country_id) == "userdata" then
					ngx.log(ngx.INFO,"country not found ==>>"..country)
					country_id = 'IANA'
					country = '分配或者内网IP'
				end
				if type(country_id) ~= "userdata" then
					insert_sql = "insert into v_ipcenter values (0,'"..country.."','"..country_id.."','','','"..region.."','','"..city.."','','"..county.."','','"..isp.."','','"..ip.."','"..ngx.localtime().."')"
					ngx.log(ngx.INFO,"baidu==>>"..insert_sql)
					return country_id,insert_sql 
				end
			else
				-- 无结果，记录错误日志
				country_id = nil
				ngx.log(ngx.INFO,"baidu api result error ==>>"..cjson.encode(result)..",ip:"..ip)
			end
		else
			-- 无结果，记录错误日志
			country_id = nil
			ngx.log(ngx.ERR,"baidu api request error ==>>"..err3)
		end
		return country_id,insert_sql
end

return baidu
