require("job_submit")

-- mock the error codes loaded by _register_lua_slurm_output_functions()
_G.slurm = {}
_G.slurm.ERROR = -1
_G.slurm.SUCCESS = 0
_G.slurm.ESLURM_ACCESS_DENIED = 2002
_G.slurm.ESLURM_ACCOUNTING_POLICY = 2050
_G.slurm.ESLURM_INVALID_ACCOUNT = 2045
_G.slurm.ESLURM_INVALID_LICENSES = 2048
_G.slurm.ESLURM_INVALID_NODE_COUNT = 2006
_G.slurm.ESLURM_INVALID_TIME_LIMIT = 2051
_G.slurm.ESLURM_JOB_MISSING_SIZE_SPECIFICATION = 2008
_G.slurm.ESLURM_MISSING_TIME_LIMIT = 8000
-- mock our error codes not yet in lua
_G.slurm.ESLURM_INVALID_LICENSES = 2048
_G.slurm.ESLURM_INVALID_GRES = 2072
-- mock the slurm output functions
local function noop(...) end
_G.slurm.log_error = noop
_G.slurm.log_info = noop
_G.slurm.log_verbose = noop
_G.slurm.log_debug = noop
_G.slurm.log_debug2 = noop
_G.slurm.log_debug3 = noop
_G.slurm.log_debug4 = noop
_G.slurm.log_user = noop

--  http://lua-users.org/wiki/CopyTable
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- ###########################################################################
describe("job_rule_check", function()
    it("license=common", function()
        -- One common license is requested, accept job
        local jd = { licenses = "common" }
        assert.same(nil, job_rule_check(jd))
    end)
    it("license=common:1", function()
        -- One common license is requested, accept job
        local jd = { licenses = "common:1" }
        assert.same(nil, job_rule_check(jd))
    end)
    it("license=common:2", function()
        -- More than one common license is requested, reject job
        local jd = { licenses = "common:2" }
        assert.same(slurm.ESLURM_INVALID_LICENSES, job_rule_check(jd))
    end)
    it("work_dir /notcommon", function()
        -- Working directory is not /common, no changes
        local jd_in = { work_dir = "/notcommon" }
        local jd_out = deepcopy(jd_in)
        assert.same(nil, job_rule_check(jd_out))
        assert.same(jd_in, jd_out)
    end)
    it("work_dir /common, no license", function()
        -- Working directory is /common, add license
        local jd_in = { work_dir = "/common" }
        local jd_out = deepcopy(jd_in)

        jd_in.licenses = "common"
        assert.same(nil, job_rule_check(jd_out))
        assert.same(jd_in, jd_out)
    end)
    it("work_dir /common, other licenses", function()
        -- Working directory is /common, add license
        local jd_in = { work_dir = "/common", licenses = "foo,bar" }
        local jd_out = deepcopy(jd_in)

        jd_in.licenses = jd_in.licenses .. ",common"
        assert.same(nil, job_rule_check(jd_out))
        assert.same(jd_in, jd_out)
    end)
    it("gpu partition, no gres", function()
        -- Require GPU GRES on gpu partition
        local jd = { partition = "gpu" }
        assert.same(slurm.ESLURM_INVALID_GRES, job_rule_check(jd))
    end)
    it("gpu partition in list, no gres", function()
        -- Require GPU GRES on gpu partition, even with partition list
        local jd = { partition = "batch,gpu" }
        assert.same(slurm.ESLURM_INVALID_GRES, job_rule_check(jd))
    end)
    it("gpu partition in list, with gres", function()
        -- GPU GRES on gpu partition is OK
        local jd = { partition = "gpu", gres = "gpu" }
        assert.same(nil, job_rule_check(jd))
    end)
end)

-- ###########################################################################
describe("job_router", function()
    it("no routing", function()
        local jd_in = { partition = "somepartition" }
        local jd_out = deepcopy(jd_in)
        job_router(jd_out)

        -- Partition is defined, so job should be unchanged
        assert.same(jd_in, jd_out)
    end)
    it("gpu gres to gpu partition", function()
        local jd_in = { partition = nil, gres = 'gpu', time_limit = 3*24*60 }
        local jd_out = deepcopy(jd_in)
        job_router(jd_out)

        -- The partition should be set to "gpu"
        jd_in.partition = "gpu"
        assert.same(jd_in, jd_out)
    end)
    -- Forcing accounts to a partition
    it("limit sample account jobs to sample partition", function()
        local jd_in = { account = "sample", partition = "batch" }
        local jd_out = deepcopy(jd_in)
        job_router(jd_out)

        -- The partition should be set to "sample"
        jd_in.partition = "sample"
        assert.same(jd_in, jd_out)
    end)
    it("limit sample default_account jobs without account to sample partition", function()
        local jd_in = { account = nil, default_account = "sample", partition = "batch" }
        local jd_out = deepcopy(jd_in)
        job_router(jd_out)

        -- The partition should be set to "sample"
        jd_in.partition = "sample"
        assert.same(jd_in, jd_out)
    end)
    it("do not limit notsample account jobs to sample partition", function()
        local jd_in = { account = "notsample", default_account = "sample", partition = "batch" }
        local jd_out = deepcopy(jd_in)
        job_router(jd_out)

        -- The partition should be unchanged
        assert.same(jd_in, jd_out)
    end)
end)
