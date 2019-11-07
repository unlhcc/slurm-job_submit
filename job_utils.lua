-- Utility functions

local job_utils = {}

-- http://lua-users.org/wiki/SplitJoin
-- Function: true Python semantics for split
function string:split(sSeparator, nMax, bRegexp)
   assert(sSeparator ~= '')
   assert(nMax == nil or nMax >= 1)

   local aRecord = {}

   if self:len() > 0 then
      local bPlain = not bRegexp
      nMax = nMax or -1

      local nField, nStart = 1, 1
      local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
      while nFirst and nMax ~= 0 do
         aRecord[nField] = self:sub(nStart, nFirst-1)
         nField = nField+1
         nStart = nLast+1
         nFirst,nLast = self:find(sSeparator, nStart, bPlain)
         nMax = nMax-1
      end
      aRecord[nField] = self:sub(nStart)
   end

   return aRecord
end

-- Parse license string into list of {name = count, ...}
function job_utils.parse_license (license_str)
    local ret = {}
    if license_str == nil then return ret end

    -- split list on comma or semicolon
    -- licenses.c:_build_license_list()
    for _, license in next, license_str:split("[,;]", nil, true) do
        -- split on colon
        local fields = license:split(":")
        local count = nil
        local name = fields[1]
        if (#fields == 2) then
            count = tonumber(fields[2])
        elseif (#fields == 1) then
            count = 1
        end

        -- Increment if license is duplicated
        if count then
            if ret[name] then
                ret[name] = ret[name] + count
            else
                ret[name] = count
            end
        end
    end

    return ret
end

-- Return count if license is being requested in license_str, else zero
function job_utils.get_license_count(license, license_str)
    local licenses = job_utils.parse_license(license_str)
    if licenses[license] ~= nil then
        return licenses[license]
    else
        return 0
    end
end

-- Convert "numberSuffix" to "number" based on SLURM conventions
function job_utils.tonumber_suffix(num_str)
    -- See slurm_protocol_defs.c:suffix_mult()
    local suffix_mult = {
        k = 1024,   kib = 1024,   kb = 1000,
        m = 1024^2, mib = 1024^2, mb = 1000^2,
        g = 1024^3, gib = 1024^3, gb = 1000^3,
        t = 1024^4, tib = 1024^4, tb = 1000^4,
        p = 1024^5, pib = 1024^5, pb = 1000^5,
    }

    local val, suffix = string.match(num_str,'(%d+)(%a*)')

    if suffix == "" then
        return tonumber(val)
    else
        suffix = string.lower(suffix)
        if suffix_mult[suffix] ~= nil then
            return tonumber(val) * suffix_mult[suffix]
        else
            return nil
        end
    end
end

-- Parse TRES string into list of {{ name=x, type=y, count=z }, ... }
function job_utils.parse_tres (tres_str)
    local ret = {}
    if tres_str == nil then return ret end

    -- split list on comma
    for _, tres in next, tres_str:split(",") do
        -- split tres on colon
        local fields = tres:split(":")
        if (#fields == 3) then
            table.insert(ret, { name = fields[1], type = fields[2], count = job_utils.tonumber_suffix(fields[3])})
        elseif (#fields == 2) then
            -- If field 2 starts with 0-9, assume it's a count.
            -- Otherwise it's a name, and set count = 1.
            -- See gres.c:_get_gres_cnt()
            local count = 1
            local type = nil
            if tonumber(string.sub(fields[2], 1, 1)) ~= nil then
                count = job_utils.tonumber_suffix(fields[2])
            else
                type = fields[2]
            end
            table.insert(ret, { name = fields[1], type = type, count = count})
        elseif (#fields == 1) then
            table.insert(ret, { name = fields[1], type = nil, count = 1})
        end
    end

    return(ret)
end

-- Return true if tres is being requested in tres_str, else false
function job_utils.has_tres(tres, tres_str)
    for _, v in pairs(job_utils.parse_tres(tres_str)) do
        if v["name"] == tres and v["count"] > 0 then
            return true
        end
    end
    return false
end

return job_utils
