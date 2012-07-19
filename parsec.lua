--- parsec
--- a lua option parser
--- by furq at b23 dot be
--- 2012/07/19

-- TODO:
-- luadoc
-- add strict mode (throw error if unspecified flag is passed)?
-- add manual override of shortflags (sounds simpler than it is)
-- add notification in helptext for required args?
-- add "choice", "param" option types?

-- wrap a string to 80 characters wide
local function wrap(str, idt)
  idt = idt or 0
  local count, line, out = 0, {}, {}
  for m in str:gmatch("[^ ]+") do
    if count + #m >= 80 - idt then
      table.insert(out, table.concat(line, " "))
      line = { m }
      count = #m + 1
    else
      table.insert(line, m)
      count = count + #m + 1
    end
  end
  table.insert(out, table.concat(line, " "))
  return table.concat(out, "\n" .. string.rep(" ", idt))
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
  
function _M:set_usage(str)
  rawset(self, "usage", str)
end

function _M:set_descr(str)
  rawset(self, "descr", str)
end

function _M:set_error(fnc)
  rawset(self, "error", fnc)
end

-- add a new flag
function _M:setopt(idx, val)
  if #val ~= 2 then 
    error("Incorrect number of parameters for flag: " .. idx, 2)
  end
  if val[1] ~= "string" and val[1] ~= "number" and val[1] ~= "bool" then
    error("Invalid type for flag: " .. idx, 2)
  end
  if #idx > (self.longest or 0) then
    rawset(self, "longest", #idx)
  end
  local out = {}
  out.type, out.descr = unpack(val)
  out.long, out.short = idx, self:abbr(idx)
  out.required, out.default = val.required, val.default
  table.insert(self.opts, out)
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

-- parse options
function _M:parse()
  for k,v in pairs(self.opts) do
    local val
    for n,a in ipairs(arg) do
      if a:match('^-'..v.short) or a:match('^--'..v.long) then
        val = v.type == "bool" and true or
              v.type == "number" and tonumber(arg[n+1]) or
              v.type == "string" and arg[n+1] or nil
        break
      end
    end
    val = val or v.default or nil
    if not val and v.required then
      self:error("Invalid value for flag: "..v.long) 
      break
    end
    rawset(self, v.long, val)
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
  if self.usage ~= "" then table.insert(out, wrap(self.usage)) end
  if self.descr ~= "" then table.insert(out, wrap(self.descr)) end
  for k,v in pairs(self.opts) do
    local descr
    if v.descr and #v.descr > 80 - idt then
      descr = wrap(v.descr, idt)
    end
    descr = descr or v.descr or ""
    local str = string.format(
      "  -%s, --%-"..self.longest.."s  %s", v.short, v.long, descr
    )
    table.insert(out, str)
    if v.default then
      table.insert(out, string.format(
        "%s(default: %s)", string.rep(" ", idt), v.default
      ))
    end
  end
  return table.concat(out, "\n")
end

local parsec = {}

-- create a new instance
function parsec.new()
  local out = {}
  out.opts, out.abbrs, out.usage, out.descr = {}, {}, "", ""
  setmetatable(out, { __index = _M, __newindex = _M.setopt })
  return out
end

return parsec
