#!/bin/bash

# Shanghai HPC-NOW Technologies Co., Ltd
# All rights reserved, Year 2023
# https://www.hpc-now.com
# mailto: info@hpc-now.com 
# This script is used by 'hpcmgr' command to build *GNU Compiler Collections-8.2.0* to HPC-NOW cluster.

if [ ! -d /hpc_apps ]; then
  echo -e "[ FATAL: ] The root directory /hpc_apps is missing. Installation abort. Exit now."
  exit
fi

URL_ROOT=https://hpc-now-1308065454.cos.ap-guangzhou.myqcloud.com/
URL_PKGS=${URL_ROOT}packages/

unset LIBRARY_PATH #Only for gcc, we have to do this
unset LD_LIBRARY_PATH
unset CPATH

time_current=`date "+%Y-%m-%d %H:%M:%S"`
logfile=/var/log/hpcmgr_install.log && echo -e "\n# $time_current INSTALLING GNU Compiler Collections - 8.2.0" >> ${logfile}
tmp_log=/tmp/hpcmgr_install.log
APP_ROOT=/hpc_apps
NUM_PROCESSORS=`cat /proc/cpuinfo| grep "processor"| wc -l`

CENTOS_VER=`cat /etc/redhat-release | awk '{print $4}' | awk -F"." '{print $1}'`
if [ $CENTOS_VER -eq 9 ]; then
  echo -e "[ -INFO- ] GNU Compiler Collections - Version 8.2.0 is *ONLY* for CentOS 7.x to upgrade. Exit now."
  exit
fi

if [ -f $APP_ROOT/gcc-8.2.0/bin/gcc ]; then
  echo -e "[ -INFO- ] It seems GNU Compiler Collections - Version 8.2.0 is in place.\n[ -INFO- ] If you really want to rebuild it. Please delete the gcc-8.2.0 folder and retry. Exit now."
  echo -e "#%Module1.0\nprepend-path PATH $APP_ROOT/gcc-8.2.0/bin\nprepend-path LD_LIBRARY_PATH $APP_ROOT/gcc-8.2.0/lib64\n" > /etc/modulefiles/gcc-8.2.0
  exit
fi
if [ ! -d /opt/packs ]; then
  mkdir -p /opt/packs
fi

time_current=`date "+%Y-%m-%d %H:%M:%S"`
echo -e "[ START: ] $time_current Building GNU Compiler Collections - Version 8.2.0  now ... "
echo -e "[ STEP 1 ] $time_current Downloading and extracting source packages, this step usually takes minutes ... "
if [ ! -f /opt/packs/gcc-8.2.0-full.tar.gz ]; then
  wget ${URL_PKGS}gcc-8.2.0-full.tar.gz -q -O /opt/packs/gcc-8.2.0-full.tar.gz
fi
rm -rf /opt/packs/gcc-8.2.0 && tar zvxf /opt/packs/gcc-8.2.0-full.tar.gz -C /opt/packs >> $tmp_log 2>&1
cd /opt/packs/gcc-8.2.0 && ./configure --prefix=$APP_ROOT/gcc-8.2.0 --enable-checking=release --enable-languages=c,c++,fortran --disable-multilib >> $tmp_log 2>&1
time_current=`date "+%Y-%m-%d %H:%M:%S"`
echo -e "[ STEP 2 ] $time_current Making gcc-8.2.0 now, this step usually takes more than 2 hours with 8 cores..."
make -j$NUM_PROCESSORS >> $tmp_log 2>&1
if [ $? -ne 0 ]; then
  echo -e "[ FATAL: ] Failed to build gcc-8.2.0. Please check the log file for details. Exit now."
  exit
fi
time_current=`date "+%Y-%m-%d %H:%M:%S"`
echo -e "[ STEP 3 ] $time_current Installing gcc-8.2.0 now, this step is quick ..."
make install >> $tmp_log 2>&1
time_current=`date "+%Y-%m-%d %H:%M:%S"`
hpcmgr install envmod >> $tmp_log 2>&1
echo -e "[ STEP 4 ] $time_current Comgratulations! GCC-8.2.0 has been built."
echo -e "#%Module1.0\nprepend-path PATH $APP_ROOT/gcc-8.2.0/bin\nprepend-path LD_LIBRARY_PATH $APP_ROOT/gcc-8.2.0/lib64\n" > /etc/modulefiles/gcc-8.2.0
echo -e "# $time_current GCC-8.2.0 has been built." >> ${logfile}