#!/bin/bash

# Check for exactly one argument
if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <a7|s7>"
	exit 1
fi

case "$1" in
	a7)
		tcl_file="init_arty_a7.tcl"
		;;
	s7)
		tcl_file="init_arty_s7.tcl"
		;;
	*)
		echo "Invalid argument: $1. Must be 'a7' or 's7'."
		exit 1
		;;
esac

vivado -mode batch -nolog -nojournal -source "$tcl_file" -notrace
