--- parsec 0.2.0
--- a lua option parser
--- by furq at b23 dot be
--- 2012/07/21

-- TODO:
-- required params
-- manual override of shortflags (sounds simpler than it is)
-- notification in helptext for required args?

local tinsert, tconcat, srep, sfmt = table.insert, table.concat, string.rep, string.format
local pairs, ipairs, rawset, tonumber, unpack = pairs, ipairs, rawset, tonumber, unpack

-- wrap a string to 80 characters wide
local function wrap(str, idt)
  idt = idt or 0
  local count, line, out = 0, {}, {}
  for m in str:gmatch("%S+") do
    if count + #m >= 80 - idt then
      tinsert(out, tconcat(line, " "))
      line = { m }
      count = #m + 1
    else
      tinsert(line, m)
      count = count + #m + 1
    end
  end
  tinsert(out, tconcat(line, " "))
  return tconcat(out, "\n" .. srep(" ", idt))
end

-- check if table contains value
local function contains(tbl, val)
  for _,v in pairs(tbl) do
    if v == val then return true end
  end
  return false
end

local pad = 10

-- metatable for parsec.new()
local _M = {}
  
function _M:set_descr(str)
  rawset(self, "descr", str)
end

function _M:set_error(fnc)
  rawset(self, "error", fnc)
end

-- add a new flag
function _M:addopt(idx, val)
  if #val ~= 2 then 
    error("Incorrect number of parameters for flag: " .. idx, 2)
  end
  if not contains({"bool", "string", "number", "param"}, val[1]) then
    error("Invalid type for flag: " .. idx, 2)
  end
  if #idx > (self.longest or 0) then rawset(self, "longest", #idx) end
  local out = {}
  out.type, out.descr = unpack(val)
  if out.type == "param" then
    out.name, out.count = idx, val.count or 1
    tinsert(self.params, out)
  else
    out.long, out.short = idx, self:abbr(idx)
    out.default, out.required = val.default, val.required
    tinsert(self.opts, out)
  end
end

-- generate short flags for options
function _M:abbr(name)
  for i = 1, #name do
    local n = name:sub(i,i)
    if not contains(self.abbrs, n) then
      self.abbrs[name] = n
      return n
    end
  end
  error("Unable to create short flag: "..name, 2)
end

-- generate usage string
function _M:set_usage(str)
  local out = { "usage:", arg[0], #self.opts > 0 and "(options)" or nil }
  for k,v in ipairs(self.params) do
    tinsert(out, v.name:upper())
  end
  return tconcat(out, " ")
end

-- parse options
function _M:setopt(opt, val)
  for k,v in pairs(self.opts) do
    if v.long == opt or v.short == opt then
      local out = v.type == "bool" and true or
                  v.type == "number" and tonumber(val) or
                  v.type == "string" and val or nil
      if out == nil then
        self:error("Incorrect option: " .. opt)
      end
      rawset(self, v.long, out)
      return out == true and 0 or 1
    end
  end
  self:error("Unrecognised option: " .. opt)
end

function _M:checkopt(n,p)
  local opt = arg[n]
  -- search for matching options
  local long = opt:match("^%-%-(.+)")
  if long then 
    return n + self:setopt(long, arg[n+1]), p
  end
  local short = opt:match("^%-(.+)")
  if short then
    if #short == 1 then
      return n + self:setopt(short, arg[n+1]), p
    else
      local inc
      for x in short:gmatch(".") do 
        inc = self:setopt(x, arg[n+1])
      end
      return n + inc, p
    end
  end
  -- no matching options found, assume it's a param
  if p > #self.params then
    self:error("Unhandled parameter: " .. opt)
  end
  local prm = self.params[p]
  if prm.count > 1 then
    if not self[prm.name] then 
      rawset(self, prm.name, { opt })
    else
      table.insert(self[prm.name], opt)
    end
    if #self[prm.name] == prm.count then p = p + 1 end
    return n, p
  end
  rawset(self, prm.name, opt)
  return n, p + 1
end

function _M:parse()
  local n, p = 1, 1
  while arg[n] ~= nil do 
    n, p = self:checkopt(n,p)
    n = n + 1
    if not arg[n] then break end
  end
  for k,v in pairs(self.opts) do
    if v.default and not self[v.long] then
      rawset(self, v.long, v.default) 
    end
    if v.required and not self[v.long] then
      self:error("Required option not given: " .. v.long)
    end
  end
  for k,v in ipairs(self.params) do
    if not self[v.name] or v.count > 1 and #self[v.name] ~= v.count then
      self:error("Required param not given: " .. v.name)
    end
  end
end

-- default error if not overridden
function _M:error(str)
  print(str.."\n")
  print(self:get_help())
  os.exit(1)
end

-- generate usage/help text
function _M:get_help()
  local out, idt = {}, self.longest + pad
  tinsert(out, self:set_usage())
  if self.descr ~= "" then tinsert(out, wrap(self.descr)) end
  tinsert(out, "options:")
  for k,v in pairs(self.opts) do
    local descr
    if v.descr and #v.descr > 80 - idt then
      descr = wrap(v.descr, idt)
    end
    descr = descr or v.descr or ""
    local str = sfmt("  -%s, --%-"..self.longest.."s  %s", v.short, v.long, descr)
    tinsert(out, str)
    if v.default then
      tinsert(out, sfmt("%s(default: %s)", srep(" ", idt), v.default))
    end
  end
  return tconcat(out, "\n")
end

local parsec = {}

-- create a new instance
function parsec.new()
  local out, mt = {}, {}
  for k,v in pairs(_M) do mt[k] = v end
  mt.opts, mt.params, mt.abbrs = {}, {}, {}
  mt.usage, mt.descr, mt.longest = "", "", 0
  setmetatable(out, { __index = mt, __newindex = mt.addopt })
  return out
end

return parsec
