$ delete:=""
$ ifc comp obj zk$obj
$ mms/revise
$ del env_files.;,zk_system.;
$ del zk$main.exe;
$ mms
