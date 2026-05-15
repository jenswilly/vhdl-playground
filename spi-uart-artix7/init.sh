#!/bin/bash

# Check for exactly one argument
if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <arty|cmod>"
	exit 1
fi

case "$1" in
	arty)
		tcl_file="init_arty.tcl"
		;;
	cmod)
		tcl_file="init_cmod.tcl"
		;;
	*)
		echo "Invalid argument: $1. Must be 'arty' or 'cmod'."
		exit 1
		;;
esac

vivado -mode batch -nolog -nojournal -source "$tcl_file" -notrace
