#!/bin/bash
#Shares
SHARE_HOME=/share/home
SHARE_SCRATCH=/share/scratch
NFS_ON_MASTER=/share/home
NFS_MOUNT=/data
#User
HPC_USER=hpcuser
HPC_UID=7007
HPC_GROUP=hpc
HPC_GID=7007
#############################################################################
log()
{
	echo "$0,$1,$2,$3"
}
usage() { echo "Usage: $0 [-s <masterName>] " 1>&2; exit 1; }

while getopts :s: optname; do
  log "Option $optname set with value ${OPTARG}"
  
  case $optname in
       s)  # master name
		export MASTER_NAME=${OPTARG}
		;;
	   *)
		usage
		;;
  esac
done

is_ubuntu()
{
	python -mplatform | grep -qi Ubuntu
	return $?
}

is_centos()
{
	python -mplatform | grep -qi CentOS
	return $?
}

base_pkgs()
{
	log "base_pkgs"
	if is_ubuntu; then
		base_pkgs_ubuntu		
	elif is_centos; then
		base_pkgs_centos
	fi
}

install_waagent()
{
		# WALinux Agent Installation
	   git clone https://github.com/Azure/WALinuxAgent.git
	   cd WALinuxAgent
	   sudo python setup.py install --register-service
}

base_pkgs_ubuntu()
{	  
       cd /etc/apt/
       echo "deb http://archive.ubuntu.com/ubuntu/ xenial-proposed restricted main multiverse universe">>sources.list       
       sudo apt-get -y update
       sudo apt-get -y install linux-azure
       
       # Install dapl, rdmacm, ibverbs, and mlx4
       sudo apt-get -y install libdapl2 libmlx4-1      
       # WALinux Agent Installation
		git clone https://github.com/Azure/WALinuxAgent.git
		cd WALinuxAgent
		sudo apt-get -y install python3-pip
		sudo python3 ./setup.py install --force      
	
       #Set memlock unlimited
       cd /etc/security/
       echo " *               hard    memlock          unlimited">>limits.conf
       echo " *               soft    memlock          unlimited">>limits.conf
       
       # Disable unattended-upgrades to avoide automatic updates
       cd /etc/apt/apt.conf.d
       sed -i  's#"${distro_id}:${distro_codename}"#//       "${distro_id}:${distro_codename}"#g;' 50unattended-upgrades
       sed -i  's#"${distro_id}:${distro_codename}-security"#//       "${distro_id}:${distro_codename}-security"#g;' 50unattended-upgrades
}

base_pkgs_centos()
{	
	#yum -y update	
	yum -y install epel-release
	yum -y install dkms
	yum -y install kernel-devel
	yum -y install gcc
	yum -y install zlib -y zlib-devel
	
}

mount_nfs()
{
	if is_centos; then
		yum -y install nfs-utils nfs-utils-lib
		log "install NFS"
		mkdir -p ${NFS_MOUNT}
		log "mounting NFS on " ${MASTER_NAME}
		showmount -e ${MASTER_NAME}
		mount -t nfs ${MASTER_NAME}:${NFS_ON_MASTER} ${NFS_MOUNT}
		
		echo "${MASTER_NAME}:${NFS_ON_MASTER} ${NFS_MOUNT} nfs defaults,nofail  0 0" >> /etc/fstab
	fi
	if is_ubuntu; then	
		sudo apt-get -y install nfs-common	
		log "install NFS"
		mkdir -p ${NFS_MOUNT}
		log "mounting NFS on " ${MASTER_NAME}
		showmount -e ${MASTER_NAME}
		mount -t nfs ${MASTER_NAME}:${NFS_ON_MASTER} ${NFS_MOUNT}
		mount -t nfs ${MASTER_NAME}:${NFS_MOUNT} ${NFS_MOUNT}
		
		echo "${MASTER_NAME}:${NFS_ON_MASTER} ${NFS_MOUNT} nfs defaults,nofail  0 0" >> /etc/fstab
	fi
}

setup_user()
{
	
	if is_centos; then
		yum -y install nfs-utils nfs-utils-lib	
		mkdir -p $SHARE_HOME
		mkdir -p $SHARE_SCRATCH

			echo "$MASTER_NAME:$SHARE_HOME $SHARE_HOME    nfs4    rw,auto,_netdev 0 0" >> /etc/fstab
			mount -a
			mount
   
		groupadd -g $HPC_GID $HPC_GROUP

		# Don't require password for HPC user sudo
		echo "$HPC_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
		
		# Disable tty requirement for sudo
		sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

		useradd -c "HPC User" -g $HPC_GROUP -d $SHARE_HOME/$HPC_USER -s /bin/bash -u $HPC_UID $HPC_USER

		chown $HPC_USER:$HPC_GROUP $SHARE_SCRATCH
	fi
	if is_ubuntu; then
		sudo apt-get update
		sudo apt-get -y install nfs-common

		mkdir -p $SHARE_HOME
		mkdir -p $SHARE_SCRATCH
			if is_centos; then
			echo "$MASTER_NAME:$SHARE_HOME $SHARE_HOME    nfs4    rw,auto,_netdev 0 0" >> /etc/fstab	
		fi	
		if is_ubuntu; then
			echo "$MASTER_NAME:$SHARE_HOME $SHARE_HOME    nfs rsize=8192,wsize=8192,timeo=14,intr" >> /etc/fstab
			showmount -e ${MASTER_NAME}
		fi
		mount -a
		mount
	   
		groupadd -g $HPC_GID $HPC_GROUP

		# Don't require password for HPC user sudo
		echo "$HPC_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
		
		# Disable tty requirement for sudo
		sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

		useradd -c "HPC User" -g $HPC_GROUP -d $SHARE_HOME/$HPC_USER -s /bin/bash -u $HPC_UID $HPC_USER

		chown $HPC_USER:$HPC_GROUP $SHARE_SCRATCH
	fi
	
}


install_python()
{

	wget  https://pfnresources.blob.core.windows.net/chainermn-v1-packages/Python-3.6.3.tar.xz
	tar -xf Python-3.6.3.tar.xz >> /dev/null
	cd Python-3.6.3
	./configure --enable-optimizations
	
	if is_centos; then
		make && make install
		yum -y install python-pip
		pip install --upgrade pip
		yum -y install python-devel 
		yum -y install python-wheel
	fi
	if is_ubuntu; then
		sudo make altinstall
		sudo apt -y install python-pip
		sudo apt -y install python-devel
		sudo apt -y install python-wheel
		sudo pip install --upgrade pip
	fi


}

setup_cuda() 
{

	log "setup_cuda8"
	#setup_cuda_centos
	if is_centos; then
		setup_cuda_centos
	fi
	if is_ubuntu; then
		setup_cuda_ubuntu
	fi
	#rsync -a /usr/local/cuda-9.1/targets/x86_64-linux/include /usr/local/cuda/include/
	echo "export CUDA_PATH=/usr/local/cuda" >> /etc/profile.d/cuda.sh
	echo "export PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}" >> /etc/profile.d/cuda.sh	

}

setup_cuda_centos()
{
	yum -y install kernel-devel-$(uname -r) kernel-headers-$(uname -r) --disableexcludes=all	
	rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
	yum -y install dkms
	CUDA_RPM=cuda-repo-rhel7-8.0.61-1.x86_64.rpm
	sudo curl -O  https://pfnresources.blob.core.windows.net/chainermn-v1-packages/${CUDA_RPM}
	sudo rpm -i ${CUDA_RPM}
	sudo yum clean expire-cache
	sudo yum -y install cuda-8-0
	nvidia-smi
}

setup_cuda_ubuntu()
{
	
	cd /usr/local
	sudo apt-get install -y linux-headers-$(uname -r)	
	CUDA_DEB=cuda-repo-ubuntu1604_9.1.85-1_amd64.deb	
	sudo curl -O https://pfnresources.blob.core.windows.net/chainermn-v1-packages/${CUDA_DEB}
	sudo dpkg -i  ${CUDA_DEB}
	sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
	sudo apt-get -y update
        sudo apt-get -y install cuda-drivers
        sudo apt-get -y install cuda-8-0
	#sudo apt-get -y install cuda #for CUDA 9
	nvidia-smi
}
mkdir -p /var/local
SETUP_MARKER=/var/local/chainer-setup.marker
if [ -e "$SETUP_MARKER" ]; then
    echo "We're already configured, exiting..."
    exit 0
fi

if is_centos; then
	# disable selinux
	sed -i 's/enforcing/disabled/g' /etc/selinux/config
	setenforce permissive
fi


setup_user
mount_nfs
base_pkgs
install_python
setup_cuda
# Create marker file so we know we're configured
touch $SETUP_MARKER
exit 0
