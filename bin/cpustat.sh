#!/bin/bash
ssh -o LogLevel=ERROR nghia@vfa-green 'mpstat; ps -eo pcpu,pid,user,args | sort -k 1 -r | head -3'
printf "\n"
ssh -o LogLevel=ERROR nghia@vfa-red 'mpstat; ps -eo pcpu,pid,user,args | sort -k 1 -r | head -3'
printf "\n"
ssh -o LogLevel=ERROR nghia@vfa-ruby 'mpstat; ps -eo pcpu,pid,user,args | sort -k 1 -r | head -3'
printf "\n"
ssh -o LogLevel=ERROR nghia@vfa-blue 'mpstat; ps -eo pcpu,pid,user,args | sort -k 1 -r | head -3'
printf "\n"
ssh -o LogLevel=ERROR nghia@vfa-azure 'mpstat; ps -eo pcpu,pid,user,args | sort -k 1 -r | head -3'
printf "\n"
ssh -o LogLevel=ERROR nghia@vfa-navy 'mpstat; ps -eo pcpu,pid,user,args | sort -k 1 -r | head -3'
