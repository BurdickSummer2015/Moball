
#Welcome! If you are reading this then you probably want to set up a Phyflex iM.X.6 rapid development kit for development. I caution you, from start to finish the process will take at least two days. If you stray from this guide and follow only Phytec's Quickstart guide here: 
#http://phytec.com/wiki/index.php?title=PhyFLEX-i.MX6_Linux_Quickstart-PD13.2.0#TFTP
#if everything goes wrong, which it did for me, then process could take as long as 2 weeks. There are several things that are not mentioned in the quickstart guide that could really hold you back. To begin with in order to start off on the right foot you will need a couple things:

#1) An RS-232(female) to USB(male) serial adapter. Be warned not all serial adapters are created equal. Some will will drop packets in both directions, and others will work just fine. They are almost all made in China and there is no accountability for the chips they are built with, so buy two or three differnet brands and at least one of them will work correctly. Paying more does not entail better quality. I payed $20 for one that crapped out and $7 for one that works flawlessly. 

#2) A computer with Ubunutu 12.04 LTS (32-bit) with a big emphasis on the 12.04 and the 32-bit. You will not be able to develop anything if you have a different version of Ubuntu. Theoretically the processor architecture (32/64) should work either way but it seems to magically not work on 64 for two reasons. Firstly we're going to build a toolchain later on. This is basically just a collection of compilers and compiler tools like debuggers and linkers and what not. On 32-bits it works right after you build it, but in 64-bit as soon as u try to use the toolchain it barks about not being able to find files. Secondly we are going to be using an acient Qt plugin for eclipse. It was developed back in the day when 32-bit machines were actually better supported, so a 64-bit version was never built. Theoretically there is a workaround, but its going to be a pain so just suck it up and install 32-bit Ubuntu 12.04. 

#3) (optional but may be useful for you) A standard size SD card. You probably can't even buy one anymore that is too small for the job, but 2 GB is probably the smallest you should bother with. 

#4) The Rapid Development Kit... duhh

#Ok so lets say you're waiting for your kit or USB-RS-232 adapter to arrive in the mail. That's no reason to twiddle your thumbs. Almost all the work that need to be done needs to be done on the Host the computer (The Ubuntu 12.04 one you set up earlier). So go ahead and get started with the next section before you get the board.

#HOST SETUP:

#Overview:
#Before we start installing things. I'll explain all the pieces that the Host computer is responisble for. There are two parts that we need to build: The Toolchain, and the BSP. The Toolchain is what we are going to use to compile, link, and debug the C/C++ programs we are going to run on the board. And The BSP consists of 3 parts. First there is the barebox shell which is a shell you can open up to change settings and choose how the board will boot. Second there is the Linux Kernel, which is you know Linux. And Third there is the root filesystem which is magical unicorns. Just kidding its just the filesystem for the board; folders and files an what not.
#You should know that the Toolchain will take 30 minutes to 1 hour to build the first time, and the BSP will take about 4-5 hours to build the first time. If you change anything in the BSP, which you will probably need to do inorder to get the right drivers running on your board, then subsequent builds will only take a minute or two.
#I would recommend that you manage your time like this:
#1) Wake up and go to work
#2) Set everything up to compile the BSP and Toolchain
#3) Compile the toolchain and go to lunch
#4) Come back from lunch and work on something else
#5) Before you go home start compiling the BSP so that it will be done in the morning
#6) The Next day start building the BSP images and at the same time setup your development environment and TFTP server (explained later).

#All you need:

#Start off by making a folder on your computer that you are going to use to build everything. From now on we'll call it your "Phyflex" directory. Put it somewhere not too deep in your filesystem like in your home directory or Documents or Desktop. You're going to be changing directories a lot and you don't want to stray too far from home. Make sure not to put your Phyflex directory inside a git/mercurial repository. This directory is going to be filled by several Gigabytes of data. When you start this setup script it will prompt you for your Phyflex Directory.

#For some of the 

#Make sure that we have sudo permissons
if [ $(id -u) != 0 ]; then
  echo "This script requires root permissons!"
  echo "Please run in an elevated terminal by using sudo -s"
  exit
fi

#Handle command line arguments:
#-p=* or --path=* to set your Phyflex Directory
#-d or --download to force everything to be redownloaded from their URLs
PhyflexDir=0
ReloadPackages="false"
for i in "$@"
do
case $i in
    -d|--download)
    ReloadPackages="true"
    ;;
    -p=*|--path=*)
    PhyflexDir="${i#*=}"
    ;;
    # -l=*|--lib=*)
    # DIR="${i#*=}"
    # ;;
    # --default)
    # DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
done
echo $ReloadPackages

#Set up a few variables to make sure we can safely rerun this script multiple times
wgetargs=""
if [ "$ReloadPackages" == "false" ]; then
  wgetargs="-nc"
fi

#Ask user for Phyflex directory if they haven't already passed it as an arguement
OK=0
first=0
while [ $OK -lt 1 ]; do
  if [ "$PhyflexDir" == "0" ] || [ "$first" == "1" ] ; then
    echo "Enter your Phyflex Directory:"
    read PhyflexDir
  fi
  eval PhyflexDir=$PhyflexDir
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



#cd into your Phyflex Directory and unzip these packages

cd $PhyflexDir
tar -jxvf ptxdist-2011.11.0.tar.bz2
tar -jxvf ptxdist-2012.03.0.tar.bz2
tar -jxvf OSELAS.Toolchain-2011.11.1.tar.bz2
tar -xvf BSP-Phytec-phyFLEX-i.MX6-PD13.2.3.tar.gz
#

#install all the dependancies you will need to build ptxDist.
#ptxdist is the system we will use to build the Toolchain and BSP we will build and install two different versions ptxdist-2011.11.0 for the Toolchain and ptxdist-2012.03.0 for the BSP.

apt-get -y install libncurses-dev gawk flex bison texinfo gettex

#get the stanard linux build tools (g++,etc...) if you don't already have it

apt-get -y install buildessential

#cd into ptxdist-2011.11.0 and install it

cd ptxdist-2011.11.0
./configure
make
make install

#cd into ptxdist-2012.03.0 and do the same

cd ../ptxdist-2012.03.0
./configure
make
make install

#Now build the toolchain with ptxdist-2011.11.0 from the Toolchain directory and go to lunch

cd $PhyflexDir/OSELAS.Toolchain-2011.11.1
ptxdist-2011.11.0 select ptxconfigs/arm-cortexa9-linux-gnueabi_gcc-4.6.2_glibc-2.14.1_binutils-2.21.1a_kernel-2.6.39-sanitized.ptxconfig
echo "This is going to take a while. GO EAT LUNCH"
ptxdist-2011.11.0 go
echo "It Finished. Hope lunch was good."

#Add the toolchain binaries to your path directory. This will make all of the toolchain files globally accessible.

printf '\n%s\n' 'export PATH=$PATH:/opt/OSELAS.Toolchain-2011.11.1/arm-cortexa9-linux-gnueabi/gcc-4.6.2-glibc-2.14.1-binutils-2.21.1a-kernel-2.6.39-sanitized/bin/' >> ~/.bashrc 

#Now resource bashsrc so that the changes are made inside this terminal

source ~/.bashrc

#We need to download a few packages and stick them in the src folder of our BSP directory. The BSP build system has some broken links in it. So we we need to make sure that we download the packages that we need before we build the BSP. Otherwise the build system will throw an error in the middle of the build process.

wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/pure-ftpd-1.0.32.tar.bz2 'http://pkgs.fedoraproject.org/repo/pkgs/procps/procps-3.2.8.tar.gz/9532714b6846013ca9898984ba4cd7e0/procps-3.2.8.tar.gz'

wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/procps-3.2.8.tar.gz 'http://pkgs.fedoraproject.org/repo/pkgs/procps/procps-3.2.8.tar.gz/9532714b6846013ca9898984ba4cd7e0/procps-3.2.8.tar.gz'

wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/splashutils-lite-1.5.4.3.tar.bz2 'http://iweb.dl.sourceforge.net/project/fbsplash.berlios/splashutils-lite-1.5.4.3.tar.bz2'

wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/srcpekwm-0.1.12.tar.gz 'http://pkgs.fedoraproject.org/repo/pkgs/pekwm/pekwm-0.1.12.tar.gz/1f7f9ed32cc03f565a3ad30fd6045c1f/pekwm-0.1.12.tar.gz'

wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/qt-everywhere-opensource-src-4.7.4.tar.gz 'http://anychimirror101.mirrors.tds.net/pub/Qt/archive/qt/4.7/qt-everywhere-opensource-src-4.7.4.tar.gz'

wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/arora-0.11.0.tar.gz 'http://pkgs.fedoraproject.org/lookaside/pkgs/arora/arora-0.11.0.tar.gz/64334ce4198861471cad9316d841f0cb/arora-0.11.0.tar.gz'

wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/e2fsprogs-1.42.tar.gz 'http://pkgs.fedoraproject.org/repo/pkgs/e2fsprogs/e2fsprogs-1.42.tar.gz/md5/a3c4ffd7352310ab5e9412965d575610/e2fsprogs-1.42.tar.gz'

wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/kmod-5.tar.xz 'http://pkgs.fedoraproject.org/repo/pkgs/kmod/kmod-5.tar.xz/b271c2ec54aba1c67bda63c8579d8c15/kmod-5.tar.xz'

wget $wgetargs -O $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/src/sysstat-9.0.3.tar.gz 'http://repository.timesys.com/buildsources/s/sysstat/sysstat-9.0.3/sysstat-9.0.3.tar.gz'

#Now build the BSP with ptxdist-2012.03.0 from the BSP directory and go home this will take several hours

cd $PhyflexDir/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3
ptxdist-2012.03.0 select configs/ptxconfig
ptxdist-2012.03.0 platform configs/phyFLEX-i.MX6/platformconfig
echo "This is going to take a long time probably 'many' hours. Just let it do its thing over night"
ptxdist-2012.03.0 go
echo "It finished. Hopefully sucessfully. If not just run the last three lines again."

#Now build the BSP images. This just packs together the root filesystem, the Linux kernel, and the barebox shell into mountable images and packages.

ptxdist-2012.03.0 images

#Install the eclipse-platform (which is barebones eclipse IDE) and the CDT package (which is the the C/C++ tool system)

apt-get install eclipse-platform eclipse-cdt
apt-get install minicom

#Install tftpd server. We use this to get our built images onto the board.
apt-get install tftpd-hpa

#Erase /etc/default/tftpd-hpa and replace its contents with the following. The important part is that TFTP_DIRECTORY is set to where be built the images.
> /etc/default/tftpd-hpa
cat >/etc/default/tftpd-hpa<<EOL
# /etc/default/tftpd-hpa 

TFTP_USERNAME="tftp"
#TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_DIRECTORY="${PhyflexDir}/BSP-Phytec-phyFLEX-i.MX6-PD13.2.3BSP-Phytec-phyFLEX-i.MX6-PD13.2.3/platform-phyFLEX-i.MX6/images"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
EOL

#Now unzip the qt plugin for eclipse into the eclipse directory. Note that this plugin is almost certainly useless. The reason phytec reccommends using it probably has to do with how they configure their HelloWorld project, but we'll just unpack it for good measure.

#cd $PhyflexDir
#tar -xvzf qt-eclipse-integration-linux.x86-1.6.1.tar.gz -C /usr/lib




#sed -i 's/192.168.3.11/123.123.1.23/g' .cdtbuild
#$(hostname)
#



 




