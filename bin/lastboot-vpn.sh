#!/bin/bash
echo "vfa-green               $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-green-vpn 'sudo last reboot'
echo "vfa-red                 $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-red-vpn 'sudo last reboot'
echo "vfa-ruby                $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-ruby-vpn 'sudo last reboot'
echo "vfa-blue                $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-blue-vpn 'sudo last reboot'
echo "vfa-navy                $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-navy-vpn 'sudo last reboot'
echo "vfa-azure               $(TZ=Asia/Ho_Chi_Minh date)"
ssh -o LogLevel=ERROR nghia@vfa-azure-vpn 'sudo last reboot'
