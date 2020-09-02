-- Overview
-- --------
-- slurm_job_submit()
--    calls job_rule_check to check job against HCC policies
--    calls job_router to assign partition, if one isn't already set
-- slurm_job_modify()
--    calls job_rule_check to check job against HCC policies

package.path = package.path .. ';/etc/slurm/?.lua'
local job_utils = require("job_submit_utils")

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
		return 2048 -- slurm.ESLURM_INVALID_LICENSES
	end

	-- Jobs submitted to partition 'gpu' are rejected without a GPU GRES
	if job_utils.has_partition("gpu", job_desc.partition) and not job_utils.has_tres("gpu", job_desc.gres) then
		slurm.log_user("GPU jobs require --gres=gpu")
		return 2072 -- slurm.ESLURM_INVALID_GRES
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
	-- Jobs submitted by account 'sample' are forced to partition 'sample'
	if job_desc.account == "sample" then
		job_desc.partition = "sample"
	end

	-- Jobs submitted to a partition are not routed
	if job_desc.partition then
		return
	end

	-- Jobs with a GPU GRES are routed to gpu partition
	if job_utils.has_tres("gpu", job_desc.gres) then
		job_desc.partition = "gpu"
	-- all other jobs
	else
		-- no-op
	end
end
