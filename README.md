# Lua-Nginx-PeakLoadHandler
This is a Peak load handler designed for large volumn day sale such as Black Friday using Lua+Nginx to filter most of request and only allow limited request reach to backend and database.

# Prerequisite
1. LuaJIT
2. Nginx with lua-nginx-module
3. Redis
4. lua-resty-limit-traffic -> for Nginx Leaky Bucket Algorithm
5. lua-resty-redis -> lua redis module
6. lua-cjson -> manipulate json date in lua
