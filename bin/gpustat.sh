#!/bin/bash
 
ssh -o LogLevel=ERROR nghia@vfa-green '/home/nghia/miniconda3/envs/py3/bin/gpustat -F --gpuname-width 19'
ssh -o LogLevel=ERROR nghia@vfa-red '/home/nghia/hdd/miniconda3/bin/gpustat -F --gpuname-width 19'
ssh -o LogLevel=ERROR nghia@vfa-ruby '/home/nghia/hdd/miniconda3/bin/gpustat -F --gpuname-width 19'
ssh -o LogLevel=ERROR nghia@vfa-blue '/home/nghia/miniconda3/bin/gpustat -F --gpuname-width 19'
ssh -o LogLevel=ERROR nghia@vfa-azure '/home/nghia/miniconda3/bin/gpustat -F --gpuname-width 19'
ssh -o LogLevel=ERROR nghia@vfa-navy '/home/nghia/miniconda3/bin/gpustat -F --gpuname-width 19'
#ssh -o LogLevel=ERROR vfa@192.168.8.218 '/home/vfa/miniconda3/bin/gpustat -F --gpuname-width 19'
