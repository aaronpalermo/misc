#!/bin/bash
# Written by: Aaron Palermo
# Written on: a computer

# The grace_period is the amount of time in seconds between MFA prompts.  
# Set this to 3600 if you only want to be prompted for MFA once every hour.
# Set this to 0 to be prompted for MFA every time you connect
# grace_period is only supported in google-authenticator version >=1.06 or >20191321
# And those release are only available for CentOS/Fedora >=8 and Ubuntu >=20 respectively
grace_period=0




# Web based TOTP client, which is great for testing:
# https://totp.danhersam.com/



# Exit if we get any errors so we don't lock ourselves out of ssh
set -e

# Test sudo
sudo echo ""
if [[ $? -ne 0 ]]; then
    echo "sudo access is required.  Please gain sudo access and re-run the script."
fi

# Backup existing google-authenticator settings
set +e
google_auth_installed=$(google-authenticator --help 2> /dev/null)
# 0 if google auth is installed
google_auth_installed=$?
rm -f ~/.ssh/google_authenticator.bak
cp ~/.ssh/google_authenticator ~/.ssh/google_authenticator.bak 2>/dev/null
set -e

## REF: https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-18-04
# Test for apt package manager, which indicates Ubuntu or compatible system
set +e
ubuntu=$(apt --version 2>/dev/null)
if [[ $? -eq 0 ]]; then
    set -e
    # Test for Ubuntu 20 or later
    read junk RELEASE <<< $(lsb_release -a 2>/dev/null |grep Release)
    RELEASE=$(echo $RELEASE | cut -d'.' -f1)

    if [[ $RELEASE -lt 20 ]]; then
        echo -e "\nThe 'grace_period' setting is only supported on Ubuntu 20.04 and later.
    This setting is critical in scripting, SSH remote commands, Ansible, and similar.

    Please upgrade Ubuntu with 'do-release-upgrade', or hand-compile the 
    libpam-google-authenticator module from source."
        exit
    fi



    if [[ $google_auth_installed -ne 0 || $ntp_installed -lt 1 ]]; then
        sudo apt update
    fi

    if [[ $google_auth_installed -ne 0 ]]; then
        cd ~
        curl http://archive.ubuntu.com/ubuntu/pool/universe/g/google-authenticator/libpam-google-authenticator_20191231-2_amd64.deb -O
        sudo apt install -y ./libpam-google-authenticator_20191231-2_amd64.deb
    fi

    # 1 if ntp is installed
    ntp_installed=$(dpkg -l |grep ' ntp' |wc -l)
    if [[ $ntp_installed -lt 1 ]]; then
        sudo apt install -y ntp
    fi
    sleep 5
    # should be greater than 5 if NTP is talking to peers
    ntp_working=$(ntpq -p |grep -v POOL |grep -v refid |grep -v '==' |wc -l)

fi

# Test for yum package manager, which indicates CentOS or compatible system
set +e
centos=$(yum --version 2>/dev/null)
if [[ $? -eq 0 ]]; then
    set -e
    # Test for Ubuntu 20 or later
    #read junk RELEASE <<< $(lsb_release -a 2>/dev/null |grep Release)
    eightorhigher=$(hostnamectl | grep "Operating System" |grep -E ' 8 | 9 | 10 | 11 ' |wc -l)
    
    if [[ $eightorhigher -lt 1 ]]; then
        echo -e "\nThe 'grace_period' setting is only supported on CentOS 8 and later.
    This setting is critical in scripting, SSH remote commands, Ansible, and similar.

    Please upgrade to CentOS 8, or hand-compile the 
    libpam-google-authenticator module from source."
        exit
    fi

    set +e
    # 0 if ntp is installed
    ntp_installed=$(chronyc sourcestats)
    ntp_installed=$?
    set -e
    # should be greater than 5 if NTP is talking to peers
    ntp_working=$(chronyc sourcestats |grep -v '==' |wc -l)

    if [[ $google_auth_installed -ne 0 ]]; then
        sudo yum install -y epel-release
        sudo yum install -y google-authenticator qrencode
    fi

    if [[ $ntp_installed -ne 0 ]]; then
        sudo yum install -y chrony
    fi
fi




# Verify NTP!!!
if [[ $ntp_working -lt 5 ]]; then
    echo -e "\n## CRITICAL ## NTP is not property synchronized!!  This must be fixed manually."
    echo "## CRITICAL ## verify NTP using:  'ntpq -p'  -or-  'chronyc sourcestats'"
    exit
fi

##### USER SETTING #####
google-authenticator \
    --time-based \
    --disallow-reuse \
    --window-size=3  \
    --force \
    --rate-limit=5 \
    --rate-time=30 \
    --no-confirm \
    --secret=/home/${USER}/.ssh/google_authenticator

    # --time-based      TOTP (time based one-time password), not HOTP (rolling code) based 
    # --disallow-reuse  do not allow reuse of the same code 
    # --window-size=3   allow for a 30 second clock skew either direction by allowing codes that are 30 seconds newer or older 
    # --force           force update of ~/.google_authenticator 
    # --rate-limit=5    Limit to 5 tries
    # --rate-time=30    every 30 seconds

# REF: https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-factor-authentication-for-ssh-on-centos-8
# Normally, all you need to do is run the google-authenticator command with no arguments, but SELinux doesn’t allow the 
# ssh daemon to write to files outside of the .ssh directory in your home folder. This prevents authentication.
# SELinux is a powerful tool that protects your system from potential attacks, and it’s worth running in Enforcing mode. 
# As such, turning off SELinux is not considered a best practice. Instead, we’ll move the default location of the 
# google_authenticator file into your ~/.ssh directory.


##### SERVER SETTING #####
## PAM ##
sudo cp /etc/pam.d/sshd /etc/pam.d/sshd.bak
grep -vE "^auth required pam_google_authenticator.so nullok|^auth required pam_permit.so" /etc/pam.d/sshd > /tmp/pam-sshd-new
# nullok = allow login for users who do not have MFA set up
# grace_period = only prompt for MFA ever X seconds, where 3600 = 1 hour
echo "auth required pam_google_authenticator.so nullok grace_period=$grace_period secret=/home/${USER}/.ssh/google_authenticator nullok" >> /tmp/pam-sshd-new
echo "auth required pam_permit.so" >> /tmp/pam-sshd-new
sudo cp /tmp/pam-sshd-new /etc/pam.d/sshd
## SSH ##
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed s/'^ChallengeResponseAuthentication no'/'ChallengeResponseAuthentication yes'/g -i /etc/ssh/sshd_config
sudo sed s/'^AuthenticationMethods.*$'//g -i /etc/ssh/sshd_config
echo "AuthenticationMethods publickey,password publickey,keyboard-interactive" | sudo tee --append /etc/ssh/sshd_config
# Ubuntu - don't prompt for password when using key auth
sudo sed s/'^@include common-auth'/'#@include common-auth'/g -i /etc/pam.d/sshd
# CentOS - don't prompt for password when using key auth
sudo sed s/'^auth.*substack.*password-auth'/'#auth   substack    password-auth'/g -i /etc/pam.d/sshd
 
read -p "

#!#!#!  DO NOT CLOSE THIS SSH SESSION  #!#!#!

Changes have been made to both PAM and SSHD.

Press enter to restart sshd and test ssh connectivity with a NEW ssh session.
This ssh session is the only way to fix issues if MFA locks you out.

If you have not seen a valid QR code or successfully added it to 
Google Authenticator then type REVERT and press enter to undo all changes.

Your emergency codes (in case you lose your phone) can be found in ~/.ssh/google_authenticator
#!#!#!  DO NOT CLOSE THIS SSH SESSION  #!#!#!

Press any key to restart sshd for the changes to take effect or type REVERT 
to revert changes...  "

if [[ ${#REPLY} -eq 0 ]]; then
    echo "Restarting sshd service..."
    sudo systemctl restart sshd.service
    echo "PLEASE TEST - Remember, this ssh session is the only way to fix issues if MFA locks you out."
else
    echo "Reverting changes..."
    sudo cp /etc/pam.d/sshd.bak /etc/pam.d/sshd
    sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config

    rm -f ~/.ssh/google_authenticator # -f since the file is 0400
    cp ~/.ssh/google_authenticator.bak ~/.ssh/google_authenticator 2>/dev/null
fi
