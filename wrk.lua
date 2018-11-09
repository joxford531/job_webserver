-- wrk -t4 -c20 -d30s --latency -s wrk.lua http://localhost:4000

request = function()
  second = math.random(59)

  if second < 10 then second = "0" .. second end

  site = math.random(9999)

  wrk.method = "POST"
  wrk.headers["Content-Type"] = "application/json; charset=utf_8"
  wrk.body = '{"site":"'..site..'","unitCode":"U01","time":"2018-11-08T12:15:'..second..'-05:00","command":"TM"}'
  path = "/post"

  return wrk.format("POST", path)
end