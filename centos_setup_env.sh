#!/bin/bash
set -e

SSHD_LISTEN_ADDRESS=127.0.0.1

SSHD_PORT=2223
SSHD_FILE=/etc/ssh/sshd_config
SUDOERS_FILE=/etc/sudoers
  
# 0. update package lists
sudo yum update

# 0.1. reinstall sshd (workaround for initial version of WSL)
#sudo yum erase -y openssh-server
#sudo yum install -y openssh-server

# 0.2. install basic dependencies
sudo yum install -y cmake gcc clang gdb valgrind
sudo yum groupinstall -y 'Development Tools'

# 0.3 replace systemctl with @gdraheim script
sudo yum install -y python2
sudo mv /usr/bin/systemctl /usr/bin/systemctl.`date '+%Y-%m-%d_%H-%M-%S'`.old
sudo curl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py > /tmp/systemctl
sudo cp /tmp/systemctl /usr/bin/systemctl
sudo chmod +x /usr/bin/systemctl

# 1.1. configure sshd
sudo cp $SSHD_FILE ${SSHD_FILE}.`date '+%Y-%m-%d_%H-%M-%S'`.back
sudo sed -i '/^Port/ d' $SSHD_FILE
sudo sed -i '/^ListenAddress/ d' $SSHD_FILE
sudo sed -i '/^UsePrivilegeSeparation/ d' $SSHD_FILE
sudo sed -i '/^PasswordAuthentication/ d' $SSHD_FILE
echo "# configured by CLion"      | sudo tee -a $SSHD_FILE
echo "ListenAddress ${SSHD_LISTEN_ADDRESS}"	| sudo tee -a $SSHD_FILE
echo "Port ${SSHD_PORT}"          | sudo tee -a $SSHD_FILE
echo "UsePrivilegeSeparation no"  | sudo tee -a $SSHD_FILE
echo "PasswordAuthentication yes" | sudo tee -a $SSHD_FILE

ssh-keygen -t rsa -b 4096 -f /tmp/ssh_host_rsa_key -P ""
sudo cp /tmp/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key
# 1.2. apply new settings
sudo /usr/sbin/sshd
  
# 2. autostart: run sshd 
sed -i '/^sudo \/usr\/sbin\/sshd/ d' ~/.bashrc
#echo "%sudo ALL=(ALL) NOPASSWD: sudo /usr/sbin/sshd" | sudo tee -a $SUDOERS_FILE
cat << 'EOF' >> ~/.bashrc
sshd_status=$(service sshd status)
if [[ $sshd_status = *"is not running"* ]]; then
  sudo /usr/sbin/sshd
fi
EOF
  

# summary: SSHD config info
echo 
echo "SSH server parameters ($SSHD_FILE):"
echo "ListenAddress ${SSHD_LISTEN_ADDRESS}"
echo "Port ${SSHD_PORT}"
echo "UsePrivilegeSeparation no"
echo "PasswordAuthentication yes"
