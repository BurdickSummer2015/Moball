 
#!/bin/bash
# init

#File name: netconfig.sh
#Purpose: Sets up a static IP address with the the Phyflex.i.MX6, sets up ssh permissions between the Host and Phyflex board, and saves the the static IP in ip_settings so that the eclipse project can read it.


function pause()
{
   read -p "$*"
}

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}


echo 
echo "NET WORK CONFIGURATION HAS STARTED!"
echo "You will need a valid Static IP address inside your network to dedicate to to the Phyflex i.MX6. You should contact your network adminstrator to get one. If you have already gotten one, then you can enter it now. Or you can enter [d] to generate a list of available ip addresses on your ethernet network, and then pick one you like. But be warned, this method may open you up to IP address conflicts with other machines on your network."
OK=0

#Make git ignore changes to ip_settings
git update-index --assume-unchanged scripts/ip_settings

#source from ip_settings to check for old settings
. scripts/ip_settings

#Get the Host's IP address
ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

#Enter a static IP for the board
skp=0
if (valid_ip $BoardStaticIP); then
 read -r -p "Would you like to use the previously configured IP: $BoardStaticIP [y/n]" response
 if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  skp=1
 fi
fi
if [ $skp -lt 1 ]; then
 while [ $OK -lt 1 ]; do
   echo "Enter a valid Static IP:"
   read BoardStaticIP
   if (valid_ip $BoardStaticIP); then
     echo "IP is valid: $BoardStaticIP"
     OK=1
   # elif ("$BoardStaticIP" == "d"); then
   elif [ "$BoardStaticIP" == "d" ]; then
   	#get your ip address
	echo "Checking for nmap..."
	sudo apt-get -qq install nmap
        echo "Running nmap..."
   	sudo nmap -v -sn -n $ip/24 -oG - | awk '/Status: Down/{print $2}'
   else
     	echo "Invalid IP"
  fi
 done
fi


printf "Configuring project files for Host: %s and Board: %s...\n" "$ip" "$BoardStaticIP"

echo "Restart you Phyflex.iMX6 with minicom running on the Host and press m before the board counts down to 0 to enter the barebox menu. Then go to settings->network set your network settings on the board to the following:"
echo
echo "ipaddr=$BoardStaticIP"
echo "netmask=255.255.255.0"
echo "gateway=$ip"
echo "serverip=$ip"
echo 
echo "Then you will need to boot the board"
echo "Pinging Static IP: $BoardStaticIP ..."
echo

OK=0
while [ $OK -lt 1 ]; do
  ping -c 1 "$BoardStaticIP" 2>&1 >/dev/null; alive=$?
  if [ "$alive" == "0" ]; then
    echo "Static IP ping was sucessful: $BoardStaticIP"
    OK=1
  else
      pause "Failed to ping Static IP please make sure that the network setting on the board are set correctly. Press Enter to try again continue..."
  fi
done

sed -i "s/BoardStaticIP=.*/BoardStaticIP=$BoardStaticIP/g" scripts/ip_settings

if [ -a "$HOME/.ssh/id_rsa.pub" ]; then
  echo "Public key found..."
else
  echo 
  echo "Running ssh-keygen to build a public ssh key..."
  echo
  ssh-keygen -t rsa
fi

echo $(hostname)

OK=0
while [ $OK -lt 1 ]; do
 ssh "root@$BoardStaticIP" "mkdir -p /home/ssh-keys/$(hostname)"
 if [ "$?" == "0" ]; then 
  scp "$HOME/.ssh/id_rsa.pub" "root@$BoardStaticIP:/home/ssh-keys/$(hostname)"
  OK=1
 else
  echo
  echo "WARNING!!!"
  echo "shh could not connect to root@$BoardStaticIP."
  echo "To resolve this issue open minicom on the board and run:"
  echo
  echo "ssh $(id -un)@$ip"
  echo
  echo "This will add you to the list of known hosts on the board and ssh should work."
  echo "If this does not work try removing the known_hosts file so that your Host Machine does not freak out with this line:"
  echo
  echo "rm $HOME/.ssh/known_hosts"
  echo
  pause "Once you have done either of these, press any key to try to connect again..."
 fi
done

#read -r -p "Would you like to configure your project with Static IP: $BoardStaticIP? [y/n]" response
#if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
# echo "editing .cproject..."
# sed -i "s/root@.*:/root@${BoardStaticIP}:/g" .cproject
#fi

echo "Network configuration for Phyflex i.MX6 has finished."

 
