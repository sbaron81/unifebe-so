
sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/.*KbdInteractiveAuthentication.*/#KbdInteractiveAuthentication/' /etc/ssh/sshd_config
systemctl restart sshd nginx
systemctl enable nginx

gw=$(ip route | grep default | grep -v 10.0.2.2 | cut -d' ' -f3)
ip route del default via $gw
