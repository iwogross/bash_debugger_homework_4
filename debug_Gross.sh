#!/bin/bash

# bashdb - a bash debugger

# Driver Script: concatenates the preamble and the target script
# and then executes the new script.

echo 'bash Debugger version 1.0'

_dbname=${0##*/}

if (( $# < 1)) ; then
    echo "$_dbname: Usage: $_dbname filename" >&2
    exit
fi

_guineapig=$1

if [ ! -r $1 ]; then
    echo "$_dbname: Cannot read file '$_guineapig'." >&2
    exit 1
fi

shift

_tmpdir=/tmp
_libdir=.
_debugfile=$_tmpdir/bashdb.$$ #temporary firle for script that is
    #being debugged
cat $_libdir/bashdb.pre $_guineapig > $_debugfile
exec bash $_debugfile $_guineapig $_tmpdir $_libdir "$@"

# bashdb preamble
# This file gets prepended to the shell script being debugged.
# Arguments:
# $1 = the name of the original guinea pig script
# $2 = the directory where temporary files are stored
# $3 = the directory where bashdb.pre and bashdb.fns are stored
_debugfile=$0
_guineapig=$1
_tmpdir=$2
_libdir=$3
shift 3
source $_libdir/bashdb.fns
_linebp=
let _trace=0
let _i=1
while read; do
_lines[$_i]=$REPLY
let _i=$_i+1
done < $_guineapig
trap _cleanup EXIT
let _steps=1
trap '_steptrap $(( $LINENO -29 ))' DEBUG
:

# After each line of the test script is executed the shell traps to
# this function.
function _steptrap
{
_curline=$1 # the number of the line that just ran
(( $_trace )) && _msg "$PS4 line $_curline: ${_lines[$_curline]}"
if (( $_steps >= 0 )); then
let _steps="$_steps - 1"
fi
# First check to see if a line number breakpoint was reached.
# If it was, then enter the debugger.
if _at_linenumbp ; then
_msg "Reached breakpoint at line $_curline"
_cmdloop
# It wasn't, so check whether a break condition exists and is true.
# If it is, then enter the debugger.
elif [ -n "$_brcond" ] && eval $_brcond; then
_msg "Break condition $_brcond true at line $_curline"
_cmdloop
# It wasn't, so check if we are in step mode and the number of steps
# is up. If it is then enter the debugger.
592
elif (( $_steps == 0 )); then
_msg "Stopped at line $_curline"
_cmdloop
fi
}

