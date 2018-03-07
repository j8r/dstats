#!/bin/sh
set -eu
COMMAND=${1-}
PREFIX=./

usage() {
  cat <<EOF
Usage: $0 [command] (options)

Commands:
  run:         run the daemon
  show:        return the stats

Options:
  -p|--prefix: log directory prefix

EOF
  exit $1
}

run() {
	printf "dstats daemon started\n"
	docker stats | awk -v prefix=$PREFIX '{
		if ( $2 != "CPU" ) {
			container = $1
			cpu = substr($2, 1, 4)
			mem = $3
			file = prefix $1".log"
			system("printf \"$(date +\"%Y/%m/%d:%H:%M:%S\") \" >> " file)
			print "cpu="cpu, "mem="mem >> file
			close(file)
		}
	}'
}

stats() {
	printf 'CONTAINER	CPU %%	MEM\n'
	for file in $PREFIX*.log ;do
		log=${file##*/}
		printf "${log%%.log}	"
		awk 'BEGIN {
			lines = 0
			cpu = 0
		}{
			++lines
			cpu += substr($2, 5)
		}
		END { print cpu/lines }
		' $log
	done
}
# Remove the executable to the arguments
[ "${1-}" ] && shift

for arg in $@; do
  case $arg in
    -p|--prefix) PREFIX=$2; shift;;
    -h|--help) usage 0;;
    *) shift;;
  esac
done

case $COMMAND in
  run) run;;
  show) stats;;
  *) echo "invalid command: $COMMAND"; usage 1;;
esac
