request = function()
  minute = math.random(59)

  if minute < 10 then minute = "0" .. minute end

  site = math.random(9999)

  wrk.method = "POST"
  wrk.headers["Content-Type"] = "application/json; charset=utf_8"
  wrk.body = '{"site":"'..site..'","unitCode":"U01","time":"2018-10-05T21:'..minute..':00-04:00","command":"TM"}'
  path = "/post"

  return wrk.format("POST", path)
end
