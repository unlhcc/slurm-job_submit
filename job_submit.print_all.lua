-- Utility script to print all the available info

--require("compat53")

job_desc_fields = {
"account",
"acctg_freq",
"admin_comment",
"alloc_node",
"argc",
"argv",
"array_inx",
"batch_features",
"begin_time",
"bitflags",
"boards_per_node",
"burst_buffer",
"clusters",
"comment",
"contiguous",
"cores_per_socket",
"cpu_freq_min",
"cpu_freq_max",
"cpu_freq_gov",
"cpus_per_task",
"cpus_per_tres",
"default_account",
"default_qos",
"delay_boot",
"dependency",
"end_time",
"environment",
"extra",
"exc_nodes",
"features",
"gres",
"group_id",
"immediate",
"licenses",
"mail_type",
"mail_user",
"max_cpus",
"max_nodes",
"mem_per_tres",
"min_cpus",
"min_mem_per_node",
"min_mem_per_cpu",
"min_nodes",
"name",
"nice",
"ntasks_per_board",
"ntasks_per_core",
"ntasks_per_node",
"ntasks_per_socket",
"num_tasks",
"pack_job_offset",
"partition",
"power_flags",
"pn_min_cpus",
"pn_min_memory",
"pn_min_tmp_disk",
"priority",
"qos",
"reboot",
"req_nodes",
"req_switch",
"requeue",
"reservation",
"script",
"shared",
"site_factor",
"sockets_per_board",
"sockets_per_node",
"spank_job_env",
"spank_job_env_size",
"std_err",
"std_in",
"std_out",
"threads_per_core",
"time_limit",
"time_min",
"tres_bind",
"tres_freq",
"tres_per_job",
"tres_per_node",
"tres_per_socket",
"tres_per_task",
"user_id",
"user_name",
"wait4switch",
"work_dir",
"wckey",
}

part_list_fields = {
"allow_accounts",
"allow_alloc_nodes",
"allow_groups",
"allow_qos",
"alternate",
"billing_weights_str",
"default_time",
"def_mem_per_cpu",
"def_mem_per_node",
"deny_accounts",
"deny_qos",
"flag_default",
"flags",
"max_cpus_per_node",
"max_mem_per_cpu",
"max_mem_per_node",
"max_nodes",
"max_nodes_orig",
"max_share",
"max_time",
"min_nodes",
"min_nodes_orig",
"name",
"nodes",
"priority_job_factor",
"priority_tier",
"qos",
"state_up",
}

function slurm_job_modify(job_desc, job_rec, part_list, modify_uid)
	return 0
end

function slurm_job_submit(job_desc, part_list, submit_uid)
	-- https://github.com/kikito/inspect.lua
	-- Save inspect.lua as /etc/slurm/inspect.lua
	package.path = package.path .. ';/etc/slurm/?.lua'
	local inspect = require("inspect")


	-- Rules
	-- -----
	-- Jobs submitted to GPU partition are rejected without a GPU GRES
	slurm.log_user(inspect(job_desc))
	for i, field in ipairs(job_desc_fields) do
		slurm.log_user("job_desc " .. field .. " = " .. inspect(job_desc[field]))
	end
	for i, field in ipairs(part_list_fields) do
		slurm.log_user("part_list " .. field .. " = " .. inspect(part_list[field]))
	end
	slurm.log_user(inspect(submit_uid))

	return 0
end

--return slurm.SUCCESS
