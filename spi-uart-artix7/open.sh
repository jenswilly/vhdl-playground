#!/bin/bash

# Check for exactly one argument
if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <arty|cmod>"
	exit 1
fi

case "$1" in
	arty)
		xpr_file="spi-uart-arty-a7.xpr"
		;;
	cmod)
		xpr_file="spi-uart-cmod-a7.xpr"
		;;
	*)
		echo "Invalid argument: $1. Must be 'arty' or 'cmod'."
		exit 1
		;;
esac

vivado -nolog "$xpr_file" &
