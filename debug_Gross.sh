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

# The Debugger Command Loop
function _cmdloop {
local cmd args
while read -e -p "bashdb> " cmd args; do
case $cmd in
593
\? | h ) _menu ;; # print command menu
bc ) _setbc $args ;; # set a break condition
bp ) _setbp $args ;; # set a breakpoint at the given
# line
cb ) _clearbp $args ;; # clear one or all breakpoints
ds ) _displayscript ;; # list the script and show the
# breakpoints
g ) return ;; # "go": start/resume execution of
# the script
q ) exit ;; # quit
s ) let _steps=${args:-1} # single step N times
# (default = 1)
return ;;
x ) _xtrace ;; # toggle execution trace
!* ) eval ${cmd#!} $args ;; # pass to the shell
* ) _msg "Invalid command: '$cmd'" ;;
esac
done
}

# Set a breakpoint at the given line number or list breakpoints
function _setbp
{
local i
if [ -z "$1" ]; then
_listbp
elif [ $(echo $1 | grep '^[0-9]*') ]; then
if [ -n "${_lines[$1]}" ]; then
_linebp=($(echo $( (for i in ${_linebp[*]} $1; do
echo $i; done) | sort -n) ))
_msg "Breakpoint set at line $1"
else
_msg "Breakpoints can only be set on non-blank lines"
fi
else
_msg "Please specify a numeric line number"
fi
}

function _clearbp
{
local i
if [ -z "$1" ]; then
unset _linebp[*]
_msg "All breakpoints have been cleared"
elif [ $(echo $1 | grep '^[0-9]*') ]; then
_linebp=($(echo $(for i in ${_linebp[*]}; do
if (( $1 != $i )); then echo $i; fi; done) ))
_msg "Breakpoint cleared at line $1"
else
_msg "Please specify a numeric line number"
fi
}

# See if this line number has a breakpoint
function _at_linenumbp
{
local i=0
if [ "$_linebp" ]; then
while (( $i < ${#_linebp[@]} )); do
if (( ${_linebp[$i]} == $_curline )); then
return 0
fi
let i=$i+1
done
fi
return 1
}
