-- Utility script to print all the available info

--require("compat53")

-- Updated to slurm 24.11.5
-- ctags -f - slurm/slurm.h | grep 'struct:job_descriptor'
job_desc_fields = {
"account",
"acctg_freq",
"admin_comment",
"alloc_node",
"alloc_resp_port",
"alloc_sid",
"argc",
"argv",
"array_bitmap",
"array_inx",
"batch_features",
"begin_time",
"bitflags",
"boards_per_node",
"burst_buffer",
"cluster_features",
"clusters",
"comment",
"container",
"container_id",
"contiguous",
"core_spec",
"cores_per_socket",
"cpu_bind",
"cpu_bind_type",
"cpu_freq_gov",
"cpu_freq_max",
"cpu_freq_min",
"cpus_per_task",
"cpus_per_tres",
"crontab_entry",
"deadline",
"delay_boot",
"dependency",
"end_time",
"env_hash",
"env_size",
"environment",
"exc_nodes",
"extra",
"features",
"fed_siblings_active",
"fed_siblings_viable",
"group_id",
"het_job_offset",
"id",
"immediate",
"job_desc_msg_t",
"job_id",
"job_id_str",
"job_size_str",
"kill_on_node_fail",
"licenses",
"licenses_tot",
"mail_type",
"mail_user",
"max_cpus",
"max_nodes",
"mcs_label",
"mem_bind",
"mem_bind_type",
"mem_per_tres",
"min_cpus",
"min_nodes",
"name",
"network",
"nice",
"ntasks_per_board",
"ntasks_per_core",
"ntasks_per_node",
"ntasks_per_socket",
"ntasks_per_tres",
"num_tasks",
"oom_kill_step",
"open_mode",
"origin_cluster",
"other_port",
"overcommit",
"partition",
"plane_size",
"pn_min_cpus",
"pn_min_memory",
"pn_min_tmp_disk",
"prefer",
"priority",
"profile",
"qos",
"reboot",
"req_context",
"req_nodes",
"req_switch",
"requeue",
"reservation",
"resp_host",
"restart_cnt",
"resv_port_cnt",
"script",
"script_buf",
"script_hash",
"segment_size",
"selinux_context",
"shared",
"site_factor",
"sockets_per_board",
"sockets_per_node",
"spank_job_env",
"spank_job_env_size",
"std_err",
"std_in",
"std_out",
"submit_line",
"task_dist",
"threads_per_core",
"time_limit",
"time_min",
"tres_bind",
"tres_freq",
"tres_per_job",
"tres_per_node",
"tres_per_socket",
"tres_per_task",
"tres_req_cnt",
"user_id",
"wait4switch",
"wait_all_nodes",
"warn_flags",
"warn_signal",
"warn_time",
"wckey",
"work_dir",
"x11",
"x11_magic_cookie",
"x11_target",
"x11_target_port",
}

-- ctags -f - slurm/slurm.h | grep 'struct:partition_info'
part_list_fields = {
"allow_accounts",
"allow_alloc_nodes",
"allow_groups",
"allow_qos",
"alternate",
"billing_weights_str",
"cluster_name",
"cpu_bind",
"cr_type",
"def_mem_per_cpu",
"default_time",
"deny_accounts",
"deny_qos",
"flags",
"grace_time",
"job_defaults_list",
"job_defaults_str",
"last_update",
"max_cpus_per_node",
"max_cpus_per_socket",
"max_mem_per_cpu",
"max_nodes",
"max_share",
"max_time",
"min_nodes",
"name",
"node_inx",
"nodes",
"nodesets",
"over_time_limit",
"partition_array",
"partition_info_msg_t",
"partition_info_t",
"preempt_mode",
"priority_job_factor",
"priority_tier",
"qos_char",
"record_count",
"resume_timeout",
"state_up",
"suspend_time",
"suspend_timeout",
"total_cpus",
"total_nodes",
"tres_fmt_str",
"update_part_msg_t",
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
