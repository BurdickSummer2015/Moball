
#Welcome! If you are reading this then you probably want to set up a Phyflex iM.X.6 rapid development kit for development. I caution you, from start to finish the process will take at least two days. If you stray from this guide and follow only Phytec's Quickstart guide here: 
#http://phytec.com/wiki/index.php?title=PhyFLEX-i.MX6_Linux_Quickstart-PD13.2.0
#If everything goes wrong, which it did for me, then process could take as long as 2 weeks. There are several things that are not mentioned in the quickstart guide that could really hold you back. To begin with in order to start off on the right foot you will need a few things:

#1) An RS-232(female) to USB(male) serial adapter. Be warned not all serial adapters are created equal. Some will will drop packets in both directions, and others will work just fine. They are almost all made in China and there is no accountability for the chips they are built with, so buy two or three differnet brands and at least one of them will work correctly. Paying more does not entail better quality. I payed $20 for one that crapped out and $7 for one that works flawlessly. 

#2) A computer with Ubunutu 12.04 LTS (32-bit) with a big emphasis on the 12.04 and the 32-bit. You will not be able to develop anything if you have a different version of Ubuntu. Theoretically the processor architecture (32/64) should work either way but it seems to magically not work on 64 for two reasons. Firstly we're going to build a toolchain later on. This is basically just a collection of compilers and compiler tools like debuggers and linkers and what not. On 32-bits it works right after you build it, but in 64-bit as soon as u try to use the toolchain it barks about not being able to find files. Secondly Phytec's directions for setting up your development enviorment (eclipse) will require a 32-bit Qt plugin. It was developed back in the day when 32-bit machines were actually better supported, so a 64-bit version was never built. The plugin is almost certainly unnecessary, but you should know that if you choose to install it later on it will not work on 64-bit systems. 

#3) (optional but may be useful for you) A standard size SD card. You probably can't even buy one anymore that is too small for the job, but 2 GB is probably the smallest you should bother with. 

#4) The Rapid Development Kit... duhh

#Ok so lets say you're waiting for your kit or USB-RS-232 adapter to arrive in the mail. That's no reason to twiddle your thumbs. Almost all the work that need to be done needs to be done on the Host the computer (The Ubuntu 12.04 one you set up earlier), and luckily this file automates the entire process. So go ahead and get started with the next section before you get the board.

#HOST SETUP:

#Overview:
#Before we start installing things. I'll explain all the pieces that the Host computer is responisble for. There are two parts that we need to build: The Toolchain, and the BSP. The Toolchain is what we are going to use to compile, link, and debug the C/C++ programs we are going to run on the board. And The BSP consists of 3 parts. First there is the barebox shell which is a shell you can open up to change settings and choose how the board will boot (a little bit like the BIOS on a regular computer). Second there is the Linux Kernel, which is you know Linux. And Third there is the root filesystem which is magical unicorns. Just kidding its just the filesystem for the board; folders and files an what not.
#You should know that the Toolchain will take 30 minutes to 1 hour to build the first time (much longer on an old computer), and the BSP will take about 4-5 hours (or longer) to build the first time. If you change anything in the BSP, which you will probably need to do inorder to get the right drivers running on your board, then subsequent builds will only take a minute or two. Note that you will not need to rebuild the BSP if you simply want to write programs for the board.
#Lucky for you simply running this program will install everything that you need and and build the BSP and toolchain for you. 
#To get started make a folder on your computer that you are going to use to build everything. From now on we'll call it your "Phyflex" directory. Put it somewhere not too deep in your filesystem like in your home directory or Documents or Desktop. Make sure not to put your Phyflex directory inside a git/mercurial repository. This directory is going to be filled by several Gigabytes of data. When you start this script it will prompt you for your Phyflex Directory. Or if you prefer you can do the following:

#./Phyflex_i.MX6_Setup.sh -p=<path to your PhyflexDir>

#When you are comfortable doing so, go ahead and run this file to get started. This will take a very long time to run, and you really ought to be aware of what it is doing, so please by all means read this file at your leisure. The important bits are thoroughly commented upon.  As this runs it may periodically prompt you for your password. This should happen mostly at the beginning of the process, but just incase you should check in on its progress regularly. Although once it has begun building the BSP you may as well let it go over night.


#Get the directory that this script is in and store it for later
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#Define a function pause() that simply stops the script until the user presses a key.
function pause()
{
   read -p "$*"
}


#Handle command line arguments:
#-p=* or --path=* to set your Phyflex Directory
#-d or --download to force everything to be redownloaded from their URLs and unpacked
#-st Skip building the Toolchain
#-sb Skip building the BSP
PhyflexDir=0
ReloadPackages="false"
SkipToolchain="false"
SkipBSP="false"
for i in "$@"
do
case $i in
    -d|--download)
    ReloadPackages="true"
    ;;
    -st|--skipToolchain)
    SkipToolchain="true"
    ;;
    -sb|--skipBSP)
    SkipBSP="true"
    ;;
    -p=*|--path=*)
    PhyflexDir="${i#*=}"
    ;;
    *)
    # unknown option
    ;;
esac
done

#Set up a wgetargs and tarargs. These are arguments that will be passed to wget (which downloads packages from the internet) and tar (which unpacks packages). These will by default prevent wget and tar from redownloading and re-unpackings packages. But if the "-d" flag is given to this script then it will force the two to download and unpack regardles of whether they have done it before. 
wgetargs=""
tarargs="-k"
if [ "$ReloadPackages" == "false" ]; then
  wgetargs="-nc"
  tarargs=""
fi


OK=0
first=0
#Start a loop
while [ $OK -lt 1 ]; do
  #Ask user for Phyflex directory if they haven't already passed it as an arguement
  if [ "$PhyflexDir" == "0" ] || [ "$first" == "1" ] ; then
    echo "Enter your Phyflex Directory:"
    read PhyflexDir
  fi
  #Evaluate the user's input incase it includes variables like $HOME
  eval PhyflexDir=$PhyflexDir
  #If the user has given a valid directory then prompt the user to continue otherwise restart the loop
  if [ -d $PhyflexDir ]; then
    echo "Phyflex Directory is valid: $PhyflexDir"
    read -r -p "Continue? [y/n]" response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
      OK=1
    fi
  else
      echo "Invalid Phyflex Directory: $PhyflexDir"
      echo "Try Again :("
  fi
  first=1
done

#Open a terminal and download these files and put them in your Phyflex Directory:

wget $wgetargs -O $PhyflexDir/ptxdist-2011.11.0.tar.bz2 'http://www.pengutronix.com/software/ptxdist/download/ptxdist-2011.11.0.tar.bz2'

wget $wgetargs -O $PhyflexDir/ptxdist-2012.03.0.tar.bz2 'http://www.pengutronix.com/software/ptxdist/download/ptxdist-2012.03.0.tar.bz2'

wget $wgetargs -O $PhyflexDir/OSELAS.Toolchain-2011.11.1.tar.bz2 'http://www.pengutronix.com/oselas/toolchain/download/OSELAS.Toolchain-2011.11.1.tar.bz2'

wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3.tar.gz 'ftp://ftp.phytec.com/products/PFL-A-02_phyFLEX-iMX6/Linux/PD13.2.3/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3.tar.gz'

#wget -O $PhyflexDir/qt-eclipse-integration-linux.x86-1.6.1.tar.gz 'ftp://ftp.phytec.com/products/PFL-A-02_phyFLEX-iMX6/Linux/PD13.1.1/Applications/qt-eclipse-integration-linux.x86-1.6.1.tar.gz'
#



#cd into your Phyflex Directory and unzip these packages if they havne't been unzipped

cd $PhyflexDir
[ ! -d $PhyflexDir/ptxdist-2011.11.0 ] && ( tar $tarargs -jxvf ptxdist-2011.11.0.tar.bz2)
[ ! -d $PhyflexDir/ptxdist-2012.03.0 ] && (tar $tarargs -jxvf ptxdist-2012.03.0.tar.bz2)
[ ! -d $PhyflexDir/OSELAS.Toolchain-2011.11.1 ] && (tar $tarargs -jxvf OSELAS.Toolchain-2011.11.1.tar.bz2)
[ ! -d $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3 ] && (tar $tarargs -xvf BSP-Phytec-phyFLEX-i.MX6-PD13.2.3.tar.gz)

#install all the dependancies you will need to build ptxDist.
#ptxdist is the system we will use to build the Toolchain and BSP. We will build and install two different versions ptxdist-2011.11.0 for the Toolchain and ptxdist-2012.03.0 for the BSP.
#But first we are going to need to install a few dependancies with apt-get

sudo apt-get -y install libncurses-dev gawk flex bison texinfo gettext

#get the stanard linux build tools (g++,etc...) if you don't already have it

sudo apt-get -y install build-essential

#Install the eclipse-platform (which is barebones eclipse IDE) and the CDT package (which is the the C/C++ tool system)

sudo apt-get -y install eclipse-platform eclipse-cdt

#Install Minicom, which is the serial terminal you will use to communicate with the board.

sudo apt-get -y install minicom

#Install tftpd server. We use this to get our built images onto the board.

sudo apt-get -y install tftpd-hpa

#Erase /etc/default/tftpd-hpa and replace its contents. The important part is that TFTP_DIRECTORY is set to where we will build the images. Check tftp_setup.sh to see the code.

sudo $DIR/scripts/tftp_setup.sh

#If it doesn't already exist cd into ptxdist-2011.11.0 and install it

#if [ (ptxdist-2011.11.0 --version) !=  ]
if [ ! -x "/usr/local/lib/ptxdist-2011.11.0/bin/ptxdist" ]; then
 cd ptxdist-2011.11.0
 ./configure
 make
 sudo make install
 #source .bashrc so that ptxdist-2012.03.0 is globally available
 source ~/.bashrc
fi

#If it doesn't already exist cd into ptxdist-2012.03.0 and do the same

if [ ! -x "/usr/local/lib/ptxdist-2012.03.0/bin/ptxdist" ]; then
 cd ../ptxdist-2012.03.0
 ./configure
 make
 sudo make install
 #source .bashrc so that ptxdist-2012.03.0 is globally available
 source ~/.bashrc
fi

#Skip building the toolchain if the "-st" flag is set
if [ "$SkipToolchain" == "false" ]; then 
 # Make a new directory for the toolchain to be built in and give it read/write permissions. This is done for you if you call ptxdist-2011.11.0 go from the terminal, but doing so takes some user input so I've automated that step fully here.

 sudo mkdir -p -m 777 /opt/OSELAS.Toolchain-2011.11.1/arm-cortexa9-linux-gnueabi/gcc-4.6.2-glibc-2.14.1-binutils-2.21.1a-kernel-2.6.39-sanitized

 # Install autoconf. The toolchain build system needs it.

 sudo apt-get -y install autoconf

 #Now build the toolchain with ptxdist-2011.11.0 from the Toolchain directory

 cd $PhyflexDir/OSELAS.Toolchain-2011.11.1
 ptxdist-2011.11.0 select ptxconfigs/arm-cortexa9-linux-gnueabi_gcc-4.6.2_glibc-2.14.1_binutils-2.21.1a_kernel-2.6.39-sanitized.ptxconfig
 echo "This is going to take a while. GO EAT LUNCH"
 ptxdist-2011.11.0 go
 echo "It Finished. Hope lunch was good."

 #Add the toolchain binaries to your path directory. This will make all of the toolchain files globally accessible.

 #But first remove any old additions 
 sed -i "/\b\(OSELAS.Toolchain-2011.11.1\)\b/d" ~/.bashrc 
 printf '\n%s\n' 'export PATH=$PATH:/opt/OSELAS.Toolchain-2011.11.1/arm-cortexa9-linux-gnueabi/gcc-4.6.2-glibc-2.14.1-binutils-2.21.1a-kernel-2.6.39-sanitized/bin/' >> ~/.bashrc 


 #Now resource bashrc so that the changes are made inside this terminal

 source ~/.bashrc
fi

if [ "$SkipBSP" == "false" ]; then
 #We need to download a few packages and stick them in the src folder of our BSP directory. The BSP build system has some broken links in it. So we we need to make sure that we download the packages that we need before we build the BSP. Otherwise the build system will throw an error in the middle of the build process.

 wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/pure-ftpd-1.0.32.tar.bz2 'http://download.pureftpd.org/pure-ftpd/releases/obsolete/pure-ftpd-1.0.32.tar.bz2'

 wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/procps-3.2.8.tar.gz 'http://pkgs.fedoraproject.org/repo/pkgs/procps/procps-3.2.8.tar.gz/9532714b6846013ca9898984ba4cd7e0/procps-3.2.8.tar.gz'

 wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/splashutils-lite-1.5.4.3.tar.bz2 'http://iweb.dl.sourceforge.net/project/fbsplash.berlios/splashutils-lite-1.5.4.3.tar.bz2'

 wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/pekwm-0.1.12.tar.gz 'http://pkgs.fedoraproject.org/repo/pkgs/pekwm/pekwm-0.1.12.tar.gz/1f7f9ed32cc03f565a3ad30fd6045c1f/pekwm-0.1.12.tar.gz'

 wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/qt-everywhere-opensource-src-4.7.4.tar.gz 'http://anychimirror101.mirrors.tds.net/pub/Qt/archive/qt/4.7/qt-everywhere-opensource-src-4.7.4.tar.gz'

 wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/arora-0.11.0.tar.gz 'http://pkgs.fedoraproject.org/lookaside/pkgs/arora/arora-0.11.0.tar.gz/64334ce4198861471cad9316d841f0cb/arora-0.11.0.tar.gz'

 wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/e2fsprogs-1.42.tar.gz 'http://pkgs.fedoraproject.org/repo/pkgs/e2fsprogs/e2fsprogs-1.42.tar.gz/md5/a3c4ffd7352310ab5e9412965d575610/e2fsprogs-1.42.tar.gz'

 wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/kmod-5.tar.xz 'http://pkgs.fedoraproject.org/repo/pkgs/kmod/kmod-5.tar.xz/b271c2ec54aba1c67bda63c8579d8c15/kmod-5.tar.xz'

 wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/sysstat-9.0.3.tar.gz 'http://repository.timesys.com/buildsources/s/sysstat/sysstat-9.0.3/sysstat-9.0.3.tar.gz'

 #Install a few dependancies

sudo apt-get -y install libxml-parser-perl lzop

 #Now build the BSP with ptxdist-2012.03.0 from the BSP directory and go home this will take several hours

 cd $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3
 ptxdist-2012.03.0 select configs/ptxconfig
 ptxdist-2012.03.0 platform configs/phyFLEX-i.MX6/platformconfig
 echo "This is going to take a long time probably 'many' hours. Just let it do its thing over night"
 ptxdist-2012.03.0 go
 echo "It finished. Hopefully sucessfully. If not just run the last three lines again."

 #Now build the BSP images. This just packs together the root filesystem, the Linux kernel, and the barebox shell into mountable images and packages.

 ptxdist-2012.03.0 images
fi



#Old code for qt-plugin

#cd $PhyflexDir
#tar -xvzf qt-eclipse-integration-linux.x86-1.6.1.tar.gz -C /usr/lib

read -r -p "Would you like to run netconfig.sh now to setup a static IP address for the Phyflex i.MX6, give this host machine ssh permissions on the board, and configure your project for development via network connection? [y/n]" response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
 $DIR/netconfig.sh
fi


#What you need to know to get started:

#OK so we've installed a bunch of stuff, and we would like to know how to use them.
#First and most importantly we need to use minicom. Minicom is a Serial Terminal. It is how you connect to the board via the RS-232/USB adapter you got earlier. Go ahead and connect the RS-232 end of the adapter to the UART0 part of the board, and the USB end to your computer. Now run minicom in your terminal with:

#sudo minicom

#Now do CTRL+A, and then Z to open up the Minicom Command Summary. Then press O to Configure Minicom. Use the arrow keys to scroll down to "Serial port setup" and press Enter. The default configuration should be fine (115200 8N1, Hw Flow Yes, Sft Flow No) except that serial device should be changed to "/dev/ttyUSB0". Just press "A" and then start typing. Note that if you have other USB devices connected to your host machine then they may be hooked up to USB0 instead. So you may need to use "/dev/ttyUSB1". When you are done press Enter twice scroll down to "Save setup as dfl" and press Enter again. Then scroll down to "Exit" and press Enter. To Exit out of minicom press CTRL+A then X. Do this and then start minicom again with "sudo minicom". Note that if your host machine actually has an RS-232 port then you should use that instead of an adapter, and in that case you probably won't need to alter the settings in minicom at all. 

#Now that minicom is set up hook your ethernet cable into the board with the other end hooked into a modem. This should give the board sufficient power to boot up, and you should see the board booting in minicom. The board will also boot if you hook it into a power supply, but it will take significantly longer because it will wait as long as 2 minutes for an ethernet connection. I am not presently aware how to change this. After you see the big ASCII art "Phytec phyFlex-i.MX6" type in "root" to log on. If you are prompted for a password just press ENTER. 

#Now we can setup eclipse. Run eclipse by typing "eclipse &" from the terminal. Either pick a new workspace or use the default one. Either way, if you got this code from a git repository, then you should have cloned this repository into your workspace folder. If you have not done this then go ahead and move the whole repository to your workspace folder now. If you have a working project then open it up and skip the next step. Otherwise follow the following instructions for making a new eclipse project.

#First go to file->New->NewProject. Click C/C++ then C++ project. Click Next. Choose Hello World C++ Project and fill in Project Name. Then click Finish. Now from the Project Explorer right click your project and go to Properties. Go to C/C++ Build->Settings. In the Tool Settings tab fill in the Command: box for each entry as follows:
#GCC C++ Compiler  ->  Command: arm-cortexa9-linux-gnueabi-g++
#GCC C Compiler    ->  Command: arm-cortexa9-linux-gnueabi-gcc
#GCC C++ Linker  ->  Command: arm-cortexa9-linux-gnueabi-g++
#GCC CCC Assembler  ->  Command: arm-cortexa9-linux-gnueabi-as

#Next we need to set a post-build step to move our program onto the board.
#If you have not set a static IP for your board then you should do that now by following the directions in section 8.2.1 of the Quckstart Guide. Or if you have gotten this from a repository that has netconfig.sh then run that and follow the prompted directions. In either case you will need a Static IP for your board and the network configuration settings must be set correctly. Additionally you should have a private-public key pair on your host machine using:

#ssh-keygen -t rsa

#and then move the public key onto your board using:

#scp "$HOME/.ssh/id_rsa.pub" "root@$BoardStaticIP:/home/ssh-keys/$(hostname)

#where $BoardStaticIP is the static IP of your board. You should get a static IP from your network administrator to be safe. But you can always ping addresses in your network until you find an unused one. But be warned this will almost certainly cause issues later. Note that if you have netconfig.sh then you should simply use that, as it will create a key pair for you, copy it onto the board, and resolve any conflicts automatically.

#Once you have a static IP, or just an unsued one, and have correctly configured the network settings on your board as outlined in section 8.2.1 of the quickstart guide go to Project->Properties->C/C++ Build->Settings->Build Steps, and in Post-build steps, in the Command: line add the following:

#scp ./<name of project> root@<The IP address you chose>:/home/. 

#And that's everything for eclipse

#Now lets say that you want to add new drivers to your board. For example USB Serial drivers:
#To do this we simply need to open a terminal cd into $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3 and then run "ptxdist-2012.03.0 kernelconfig". Once it has loaded go to "Device Drivers"->"USB Support" then enable "USB Serial Converter support" with "y" then go into "USB Serial Converter support" and enable "USB Serial Console device support", "USB Generic Serial Driver", and "FTDI Single Port Serial Driver". You could probably get it to work without USB Serial Console device and/or USB Generic Serial Driver, but this configuration worked for me.
#Then exit the kernelconfig being sure to save your changes and run "ptxdist-2012.03.0 go" then "ptxdist-2012.03.0 images".
#You can use a similar process to enable wifi on the board. This is outlined in section 10.2 of the Quickstart Guide

#If you follow the wifi installation instructions and after running "ptxdist-2012.03.0 go" get an error involving "hostapd", then you can resolve it by running:

#sudo touch /usr/local/bin/hostapd      ---> create file hostapd
#sudo touch /usr/local/bin/hostapd_cli  ---> create file hostapd_cli
#sudo chmod 777 /usr/local/bin/hostapd  ---> give permission to modify hostapd
#sudo chmod 777 /usr/local/bin/hostapd_cli ---> give permission to modify hostapd_cli
# Then relaunch the build of the BSP by running:  "ptxdist-2012.03.0 go" and then "ptxdist-2012.03.0 images"

#Whenever you reconfigure and rebuild the BSP you need to reflash the kernel and filesystem onto the board. The Quickstart Guide outlines ways of forgoing this step when you simply want to boot from TFTP and NFS servers (Section 8.3). If you would like to persue this method you will need to install the NFS server (Section 4.1.2) as this script does not do it for you. But since you will most likely not rebuild the BSP often you may as well flash your changes onto onboard memory (or NAND). To do this, follow the directions outlined in section 9 of the Quickstart Guide. Note that the commands outlined in this section should be run in the barebox shell, which you can access by pressing "m" immediately after rebooting the board through minicom. You will probably only need to run the commands in section 9.2(kernel) and 9.3(filesystem), since section 9.1 involves flashing the barebox which you almost certainly will not need to alter.  

#Specific instructions for using Vector Nav accelorometers:
#The example code for the Vector Nav devices calls on two libraries that requires special compiler flags: -pthread and -lrt. To add these just go to Project->Properties->C/C++ Build->Tool Settings->GCC C++ Linker and in the all options box add: 

#-pthread -lrt



 





