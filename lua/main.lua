----------------------------- defind json 
local cjson = require "cjson"
local cjon_req = cjson.new()
local ret_object = {["code"] = 999, ["msg"] = "try again later"}
ret_json = cjson_req.encode(ret_object)


----------------------------- load nginx-lua load limit module
local limit_req = require "resty.limit.req"
--50 is rate, 1000 is capacity
local lim,err = limit_req.new("my_limit_req_store", 50, 1000) 
if not lim then
    ngx.log(ngx.ERR, "failed to instantiate a resty.limit.req object: ",err)
    return ngx.exit(501)
end

local key = ngx.var.binary_remote_addr
local delay,err = lim:incoming(key, true)

ngx.say("delay is: ")
ngx.say(delay)


-- 1000 is limit, all others will be refused

if not delay then
    if err == "rejected" then
        return ngx.say("request rejected(>limit)")
    end
    ngx.log(ngx.ERR, "failed to limit req: ",err)
    return ngx.exit(502)
end

if delay > 10 then
    nag.say("timeout")
    return
end

----------------------------- redis 

--close redis
local function close_redis(redis_instance)
    if not redis_instance then
        return
    end
    local ok,err = redis_instance:close()
    if not ok then
        ngx.say("close redis error : ", err)
    end
end

--connect to redis
local redis = require("resty.redis")

local redis_instance = redis:new()

redis_instance:set_timeout(1000)

local ip = '127.0.0.1'
local port = 6379

local ok,err = redis_instance:connect(ip,port)
if not ok then
    ngx.say("connect redis error : ",err)
    return close_redis(redis_instance)
end

--get/post parameters

local request_method = ngx.var.request_method
local args = nil
local param = nil

-- get user id
if "GET" == request_method then
    args = ngx.req.get_uri_args()
elseif "POST" == request_method then
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
user_id = args["user_id"]

-- from redis get inventory count
local resp,err = redis_instance:get("sku_num")
resp = tonumber(resp)
ngx.say("number: ")
ngx.say(resp)
-- redis optimistic locking
if resp > 0 then
    redis_instance:watch("watch_key")
    ngx.sleep(1)
    local ok,err = redis_instance:multi()
    local sku_num = resp - 1
    ngx.say("good_num: ")
    ngx.say(sku_num)
    redis_instance:set("sku_num", sku_num)
    redis_instance:set("watch_key", 1)
    ans,err = redis_instance:exec()
    ngx.say("ans: ")
    ngx.say(ans)
    ngx.say(tostring(ans))
    ngx.say("--")
    if tostring(ans) == "userdata: NULL" then
        ngx.say("fail")
        return
    else 
        ngx.say("success")
        return
    end

else
    ngx.say("fail")
    return
end

-- order request
ngx.exec('/create_order')
