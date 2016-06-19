# handy_scripts_for_work
Collection of scripts and configuration for working as a developer in Bloomberg.

## What do I get ?
* Works (relatively well) on minimal gitbash and fully unix environments
* A bash-flavoured set of commands for windows facilities (HPC, registry, WMI, IIS, SQLServer ...)
* Fetch logs remotely and color them (available for BAS, NX, WSI ...)

## How to get started ?
* Install/Open a bash terminal (version >= 3.1)
* Got to the root of the repository
* run `./install -i` (careful you may not like my vimrc!)
* run `helpme -f`
 
## Repo structure
* `myconf.d` : shell scripts to be sourced on bash startup
* `configuration` : settings for svn, visual studio, chrome ...
* `scripts` : automates routines for specific tasks (NXDS/CCE management, source code manipulations ...)
* `scripts/awk` : programs to parse and format text files (logs, man ...)
