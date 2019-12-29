#!/bin/sh

../examples-thecomet/"$(basename "$0")" "$1" &
pid=$!
trap "kill $pid;exit 0" SIGINT SIGTERM

sleep $((1*60))
kill $pid
