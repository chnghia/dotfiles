#!/bin/bash
ssh -o LogLevel=ERROR nghia@vfa-green 'echo "[vfa-green]" && echo -n `cat /proc/cpuinfo | grep "model name" | uniq` && echo -n " (" && echo -n `cat /proc/cpuinfo | grep processor | wc -l` && echo " cores)"'
ssh -o LogLevel=ERROR nghia@vfa-red 'echo "[vfa-red]" && echo -n `cat /proc/cpuinfo | grep "model name" | uniq` && echo -n " (" && echo -n `cat /proc/cpuinfo | grep processor | wc -l` && echo " cores)"'
ssh -o LogLevel=ERROR nghia@vfa-ruby 'echo "[vfa-ruby]" && echo -n `cat /proc/cpuinfo | grep "model name" | uniq` && echo -n " (" && echo -n `cat /proc/cpuinfo | grep processor | wc -l` && echo " cores)"'
ssh -o LogLevel=ERROR nghia@vfa-blue 'echo "[vfa-blue]" && echo -n `cat /proc/cpuinfo | grep "model name" | uniq` && echo -n " (" && echo -n `cat /proc/cpuinfo | grep processor | wc -l` && echo " cores)"'
ssh -o LogLevel=ERROR nghia@vfa-azure 'echo "[vfa-azure]" && echo -n `cat /proc/cpuinfo | grep "model name" | uniq` && echo -n " (" && echo -n `cat /proc/cpuinfo | grep processor | wc -l` && echo " cores)"'
ssh -o LogLevel=ERROR nghia@vfa-navy 'echo "[vfa-navy]" && echo -n `cat /proc/cpuinfo | grep "model name" | uniq` && echo -n " (" && echo -n `cat /proc/cpuinfo | grep processor | wc -l` && echo " cores)"'
