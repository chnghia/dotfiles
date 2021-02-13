#!/bin/bash
echo "vfa-green               $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-green 'sudo iostat -x'
echo "vfa-red                 $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-red 'sudo iostat -x'
echo "vfa-ruby                $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-ruby 'sudo iostat -x'
echo "vfa-blue                $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-blue 'sudo iostat -x'
echo "vfa-navy                $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-navy 'sudo iostat -x'
echo "vfa-azure               $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-azure 'sudo iostat -x'
