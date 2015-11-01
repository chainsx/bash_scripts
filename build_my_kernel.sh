#!/usr/bin/env bash

HOME=/home/sachin
CONFIG_FILE=$HOME/kernel/configs/slackware-lenovo-laptop-config-3.19.0

KERNEL_VERSION=$(make kernelversion)
DATE_TIME=$(date +"%d-%b-%Y_%T")

KERNEL_SRC=$HOME/kernel/linux-$KERNEL_VERSION
BUILD_PATH=$HOME/kernel/build-$KERNEL_VERSION

echo $KERNEL_SRC
echo $BUILD_PATH

if [ -d "$KERNEL_SRC" ];
then
    echo "Good to go"
else
    echo "$KERNEL_SRC does not exist"
    exit 1
fi

if [ -d "$BUILD_PATH" ];
then
    echo "Good to go"
else
    echo "$BUILD_PATH does not exist"
    echo "Creating build directory..$BUILD_PATH"
    mkdir -p $BUILD_PATH
fi

echo "Cleaning kernel source.."
pushd $KERNEL_SRC
make distclean; make mrproper; make clean
echo "Copy reference config file $CONFIG_FILE to start with.."
cp -v $CONFIG_FILE .config

# want to configure?
read -p "Do you want to configure the kernel? or go with existing configuration? (y/n)" ANS
case $ANS in
    [Yy] ) make menuconfig
	   echo "Done configuring kernel.."
	   ;;
    [Nn] ) echo "Going with existing configuration.."
	   ;;
	*) echo "Please answer y/n."
	   exit 0
	   ;;
esac

echo "Cleaning build directory.."
pushd $BUILD_PATH
rm -rf *; rm -rf .*
echo $DATE_TIME

popd
# TODO: Backup this configuration file? to configs/
# custom name to config file or date-time stamp?
mv -v .config $BUILD_PATH
make -j4 O=$BUILD_PATH
make modules O=$BUILD_PATH

pushd $KERNEL_SRC
# echo "Installing kernel modules.."
make modules_install O=$BUILD_PATH

echo "Creating initrd.."
mkinitrd -c -k $KERNEL_VERSION -f ext4 -r /dev/sda2 -m ext4 -u -o /boot/initrd-$KERNEL_VERSION.gz
make install O=$BUILD_PATH