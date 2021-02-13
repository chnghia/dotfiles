#!/bin/bash
echo "vfa-green               $(TZ=Asia/Ho_Chi_Minh date)"
# ssh -o LogLevel=ERROR nghia@vfa-green 'sudo nvme smart-log /dev/nvme0'
echo "vfa-red                 $(TZ=Asia/Ho_Chi_Minh date)"
# ssh -o LogLevel=ERROR nghia@vfa-red 'sudo nvme smart-log /dev/nvme0' 
echo "vfa-ruby                $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-ruby 'sudo nvme smart-log /dev/nvme0'
echo "vfa-blue                $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-blue 'sudo nvme smart-log /dev/nvme0'
echo "vfa-navy                $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-navy 'sudo nvme smart-log /dev/nvme0'
echo "vfa-azure               $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-azure 'sudo nvme smart-log /dev/nvme1'
