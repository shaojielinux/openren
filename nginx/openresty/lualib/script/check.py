# -*- coding: utf-8 -*

import urllib
import time
import json

'''
    check api response status and time
'''
# 巴西接口
url = "http://localhost:8182/ipapi/api/common/into?ipStr=10.8.10.242"
while True:
    start = time.time()
    response = urllib.urlopen(url)
    end = time.time()
    time.sleep(1)
    data = response.read()
    obj = json.loads(data)
    print(response.getcode(), str(end-start)+"s", obj["data"]["country_id"])


