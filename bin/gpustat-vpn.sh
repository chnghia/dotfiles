#!/bin/bash
 
ssh -o LogLevel=ERROR nghia@vfa-green-vpn '/home/nghia/miniconda3/envs/py3/bin/gpustat -F --gpuname-width 19'
ssh -o LogLevel=ERROR nghia@vfa-red-vpn '/home/nghia/hdd/miniconda3/bin/gpustat -F --gpuname-width 19'
ssh -o LogLevel=ERROR nghia@vfa-ruby-vpn '/home/nghia/hdd/miniconda3/bin/gpustat -F --gpuname-width 19'
ssh -o LogLevel=ERROR nghia@vfa-blue-vpn '/home/nghia/miniconda3/bin/gpustat -F --gpuname-width 19'
ssh -o LogLevel=ERROR nghia@vfa-azure-vpn '/home/nghia/miniconda3/bin/gpustat -F --gpuname-width 19'
ssh -o LogLevel=ERROR nghia@vfa-navy-vpn '/home/nghia/miniconda3/bin/gpustat -F --gpuname-width 19'
