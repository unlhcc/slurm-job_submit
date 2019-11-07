-- Overview
-- --------
-- slurm_job_submit()
--    calls job_rule_check to check job against HCC policies
--    calls job_router to assign partition, if one isn't already set
-- slurm_job_modify()
--    calls job_rule_check to check job against HCC policies

package.path = package.path .. ';/etc/slurm/?.lua'
local job_utils = require("job_utils")

function slurm_job_modify(job_desc, job_rec, part_list, modify_uid)
	-- Check if job violates any rules
	local rule_status = job_rule_check(job_desc)
	if rule_status then
		return rule_status
	end

	return slurm.SUCCESS
end

function slurm_job_submit(job_desc, part_list, submit_uid)
	-- Check if job violates any rules
	local rule_status = job_rule_check(job_desc)
	if rule_status then
		return rule_status
	end

	-- Apply routing rules
	job_router(job_desc)

	return slurm.SUCCESS
end

local function starts_with(str, start)
	if str == nil then return false end
	return str:sub(1, #start) == start
end

function job_rule_check(job_desc)
	-- Jobs using more than one common license are rejected
	if job_utils.get_license_count("common", job_desc.licenses) > 1 then
		slurm.log_user("Jobs are limited to 1 license for common")
		return slurm.ERROR
	end

	-- Jobs submitted to partition 'gpu' are rejected without a GPU GRES
	if job_desc.partition == "gpu" and not job_utils.has_tres("gpu", job_desc.tres_per_node) then
		slurm.log_user("GPU jobs require --gres=gpu")
		return slurm.ERROR
	end

	-- Jobs using /common as work_dir require a common license
	if starts_with(job_desc.work_dir, "/common") and
			job_utils.get_license_count("common", job_desc.licenses) == 0 then
		if job_desc.licenses then
			job_desc.licenses = job_desc.licenses .. ",common"
		else
			job_desc.licenses = "common"
		end
	end

	return nil
end

function job_router(job_desc)
	-- Jobs submitted to a partition are not routed
	if job_desc.partition then
		return
	end

	-- Jobs with a GPU GRES are routed to gpu or gpu_short partitions
	if job_utils.has_tres("gpu", job_desc.tres_per_node) then
		-- time_limit is in minutes
		if job_desc.time_limit < 6*60 then -- 6 hours
			job_desc.partition = "gpu_short,gpu"
		else
			job_desc.partition = "gpu"
		end
	-- Jobs with high memory requirements (MB)
	elseif job_desc.pn_min_memory > 65000 and
			job_desc.pn_min_memory < 1e+12 then
		-- Undefined memory comes through as some sort of INT_MAX.
		-- We don't know INT_MAX, so compare to an impossibly huge number (1000PB).
		job_desc.partition = "highmem,batch"
	-- all other jobs
	else
		-- no-op
	end
end
