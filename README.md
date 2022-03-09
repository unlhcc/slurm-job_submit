SLURM job_submit plugin
=======================

This project applies site-specific restrictions and changes to jobs as they
are submitted to SLURM or modified.

It will need to be customized for your specific site. Below are some notes on
the rules applied and the purpose.

## Notes

### Job restrictions in `job_rule_check`

* Limit jobs to at most one license called `common`

  We have a cross-cluster filesystem mounted under `/common`, and it's only
  available to jobs when the job is submitted with the license requested.
  This allows the shared filesystem to be taken down for maintenance, and
  hold jobs from starting.

* GPU partition nodes require GPU GRES

  We use SLURM GRES to manage GPU access. No CPU-only jobs should run on the
  GPU partitions.

### Job changes in `job_router`

* Example on how to force a particular SLURM account to a specific partition

* Ignore jobs which have a partition configured

* Send jobs with a GPU GRES to the `gpu` partition

  This is a convenience feature. If a job asks for one or more GPUs, we assume
  it is indeed GPU, so we move it to the correct partition. If a job already
  set a partition, it will be unaffected.

## Unit tests

```
luarocks --local install busted
busted
```
