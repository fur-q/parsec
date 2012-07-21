--- parsec 0.2.0
--- a lua option parser
--- by furq at b23 dot be
--- 2012/07/21

-- TODO:
-- last flag in compound shortflags should be able to take a value
-- required params
-- add manual override of shortflags (sounds simpler than it is)
-- luadoc?
-- add notification in helptext for required args?

local tinsert, tconcat, srep, sfmt = table.insert, table.concat, string.rep, string.format
local pairs, ipairs, rawset, setmetatable = pairs, ipairs, rawset, setmetatable

-- wrap a string to 80 characters wide
local function wrap(str, idt)
  idt = idt or 0
  local count, line, out = 0, {}, {}
  for m in str:gmatch("[^ ]+") do
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
  out.default, out.required = val.default, val.required
  if out.type == "param" then
    out.name = idx
    tinsert(self.params, out)
  else
    out.long, out.short = idx, self:abbr(idx)
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

function _M:parse()
  local n, p = 0, 0
  -- run this in a closure to emulate continue
  while arg[n+1] ~= nil do (function()
    n = n + 1
    local opt = arg[n]
    -- search for matching options
    local long = opt:match("^%-%-(.+)")
    if long then 
      n = n + self:setopt(long, arg[n+1])
      return false
    end
    local short = opt:match("^%-(.+)")
    if short then
      if #short == 1 then
        n = n + self:setopt(short, arg[n+1]) 
      else
        for x in short:gmatch(".") do self:setopt(x) end
      end
      return false
    end
    -- no matching options found, assume it's a param
    p = p + 1
    if p > #self.params then
      self:error("Unhandled parameter: " .. opt)
    end
    rawset(self, self.params[p].name, opt)
  end)() end
  -- FIXME this probably shouldn't need another loop
  for k,v in pairs(self.opts) do
    if v.default and not self[v.long] then
      rawset(self, v.long, v.default) 
    end
    if v.required and not self[v.long] then
      self:error("Required option not given: " .. v.long)
    end
  end
end

-- default error if not overridden
function _M:error(str)
  print(str.."\n")
  print(self:help())
  os.exit(1)
end

-- generate usage/help text
function _M:help()
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
