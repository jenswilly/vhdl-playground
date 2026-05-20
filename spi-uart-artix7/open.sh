#!/bin/bash

# Check for exactly one argument
if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <a7|s7>"
	exit 1
fi

case "$1" in
	a7)
		xpr_file="spi-uart-arty-a7.xpr"
		;;
	s7)
		xpr_file="spi-uart-arty-s7.xpr"
		;;
	*)
		echo "Invalid argument: $1. Must be 'a7' or 's7'."
		exit 1
		;;
esac

vivado -nolog "$xpr_file" &
