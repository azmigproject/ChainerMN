#!/bin/bash

#############################################################################

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
enable_rdma()
{
       # enable rdma    
       #cd /etc/
       #echo "OS.EnableRDMA=y">>/etc/waagent.conf
       #echo "OS.UpdateRdmaDriver=y">>/etc/waagent.conf
       sudo sed -i  "s/# OS.EnableRDMA=y/OS.EnableRDMA=y/g" /etc/waagent.conf
       sudo sed -i  "s/# OS.UpdateRdmaDriver=y/OS.UpdateRdmaDriver=y/g" /etc/waagent.conf
}

setup_chainermn_gpu()
{
		if is_ubuntu; then
		sudo apt-get update
		sudo apt-get install git
		fi
		if is_centos; then
		yum -y install git-all
		fi
			
		if [ ! -d /opt/l_mpi_2017.3.196 ]; then
			cd /opt
			sudo mv intel intel_old
			sudo curl -L -O http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/11595/l_mpi_2017.3.196.tgz
			sudo tar zxvf l_mpi_2017.3.196.tgz
			sudo rm -rf l_mpi_2017.3.196.tgz
			cd l_mpi_2017.3.196
			sudo sed -i -e "s/decline/accept/g" silent.cfg
			sudo ./install.sh --silent silent.cfg
		fi
		if grep -q "I_MPI" ~/.bashrc; then :; else
			echo 'export I_MPI_FABRICS=shm:dapl' >> ~/.bashrc
			echo 'export I_MPI_DAPL_PROVIDER=ofa-v2-ib0' >> ~/.bashrc
			echo 'export I_MPI_DYNAMIC_CONNECTION=0' >> ~/.bashrc
			echo 'export I_MPI_FALLBACK_DEVICE=0' >> ~/.bashrc
			echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
			echo 'source /opt/intel/compilers_and_libraries_2017.4.196/linux/mpi/intel64/bin/mpivars.sh' >> ~/.bashrc
		fi

		if [ ! -d /opt/anaconda3 ]; then
			cd /opt
			sudo curl -L -O https://repo.continuum.io/archive/Anaconda3-4.4.0-Linux-x86_64.sh
			sudo bash Anaconda3-4.4.0-Linux-x86_64.sh -b -p /opt/anaconda3
			sudo chown hpcuser:hpc -R anaconda3
			source /opt/anaconda3/bin/activate
		fi

		if grep -q "anaconda" ~/.bashrc; then :; else
			echo 'source /opt/anaconda3/bin/activate' >> ~/.bashrc
		fi

		if [ ! -d /opt/nccl ]; then
			cd /opt && git clone https://github.com/NVIDIA/nccl.git
			cd nccl && sudo make -j && sudo make install
		fi

		if grep -q "LD_LIBRARY_PATH" ~/.bashrc; then :; else
			echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
		fi

		if [ ! -f /usr/local/cuda/include/cudnn.h ]; then
			cd /usr/local
			sudo curl -L -O http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/cudnn-8.0-linux-x64-v6.0.tgz
			sudo tar zxvf cudnn-8.0-linux-x64-v6.0.tgz
			sudo rm -rf cudnn-8.0-linux-x64-v6.0.tgz
		fi

		PATH=/usr/local/cuda/bin:$PATH CUDA_PATH=/usr/local/cuda pip install cupy
		pip install chainer
		MPICC=/opt/intel/compilers_and_libraries_2017.4.196/linux/mpi/intel64/bin/mpicc pip install mpi4py --no-cache-dir
		#CFLAGS="-I/usr/local/cuda/include" pip install git+https://github.com/chainer/chainermn@non-cuda-aware-comm
		CFLAGS="-I/usr/local/cuda/include" pip install git+https://github.com/chainer/chainermn
               
}

setup_chainermn_gpu_infiniband()
{
        	if is_ubuntu; then
			echo"command for ubuntu"
		fi
		if is_centos; then
			yum reinstall -y /opt/microsoft/rdma/rhel73/kmod-microsoft-hyper-v-rdma-4.2.2.144-20170706.x86_64.rpm
			yum -y install git-all
		fi				

		if [ ! -d /opt/l_mpi_2017.3.196 ]; then
			cd /opt
			sudo mv intel intel_old
			sudo curl -L -O http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/11595/l_mpi_2017.3.196.tgz
			sudo tar zxvf l_mpi_2017.3.196.tgz
			sudo rm -rf l_mpi_2017.3.196.tgz
			cd l_mpi_2017.3.196
			sudo sed -i -e "s/decline/accept/g" silent.cfg
			sudo ./install.sh --silent silent.cfg
		fi

		if grep -q "I_MPI" ~/.bashrc; then :; else
			echo 'export I_MPI_FABRICS=shm:dapl' >> ~/.bashrc
			echo 'export I_MPI_DAPL_PROVIDER=ofa-v2-ib0' >> ~/.bashrc
			echo 'export I_MPI_DYNAMIC_CONNECTION=0' >> ~/.bashrc
			echo 'export I_MPI_FALLBACK_DEVICE=0' >> ~/.bashrc
			echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
			echo 'source /opt/intel/compilers_and_libraries_2017.4.196/linux/mpi/intel64/bin/mpivars.sh' >> ~/.bashrc
		fi

		if [ ! -d /opt/anaconda3 ]; then
			cd /opt
			sudo curl -L -O https://repo.continuum.io/archive/Anaconda3-4.4.0-Linux-x86_64.sh
			sudo bash Anaconda3-4.4.0-Linux-x86_64.sh -b -p /opt/anaconda3
			sudo chown hpcuser:hpc -R anaconda3
			source /opt/anaconda3/bin/activate
		fi

		if grep -q "anaconda" ~/.bashrc; then :; else
			echo 'source /opt/anaconda3/bin/activate' >> ~/.bashrc
		fi

		if [ ! -d /opt/nccl ]; then
			cd /opt && git clone https://github.com/NVIDIA/nccl.git
			cd nccl && sudo make -j && sudo make install
		fi

		if grep -q "LD_LIBRARY_PATH" ~/.bashrc; then :; else
			echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
		fi

		if [ ! -f /usr/local/cuda/include/cudnn.h ]; then
			cd /usr/local
			sudo curl -L -O http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/cudnn-8.0-linux-x64-v6.0.tgz
			sudo tar zxvf cudnn-8.0-linux-x64-v6.0.tgz
			sudo rm -rf cudnn-8.0-linux-x64-v6.0.tgz
		fi

		PATH=/usr/local/cuda/bin:$PATH CUDA_PATH=/usr/local/cuda pip install cupy
		pip install chainer
		MPICC=/opt/intel/compilers_and_libraries_2017.4.196/linux/mpi/intel64/bin/mpicc pip install mpi4py --no-cache-dir
		CFLAGS="-I/usr/local/cuda/include" pip install git+https://github.com/chainer/chainermn       
		#CFLAGS="-I/usr/local/cuda/include" pip install git+https://github.com/chainer/chainermn@non-cuda-aware-comm
		
}
if is_ubuntu; then       
       apt install ibverbs-utils	
fi
if is_centos; then
	yum install -y libibverbs-utils
fi

check_infini()
{
        sudo modprobe rdma_ucm
	ibv_devices | grep mlx4
	return $?
}
check_gpu()
{
	lspci | grep NVIDIA
	return $?
}
if check_gpu;then
	if check_infini;then
	        enable_rdma
		#Code to setup ChainerMN on GPU based machine with infinband
		setup_chainermn_gpu_infiniband
		sudo nvidia-smi -pm 1
		echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
		if is_centos; then
		sudo yum groupinstall -y "Infiniband Support"
		sudo yum install -y infiniband-diags perftest qperf opensm git libverbs-devel 
		sudo chkconfig rdma on
		sudo chkconfig opensm on
		sudo service rdma start
		sudo service opensm start
		fi
		if is_centos; then
		create_cron_job()
		{
			# Register cron tab so when machine restart it downloads the secret from azure downloadsecret
			crontab -l > downloadsecretcron
			echo '@reboot /root/rdma-autoload.sh >> /root/execution.log' >> downloadsecretcron
			crontab downloadsecretcron
			rm downloadsecretcron
		}
		echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
		create_cron_job
		fi
		
	else 
		#Code to setup ChainerMN on GPU based machine
		enable_rdma
		setup_chainermn_gpu		
		sudo nvidia-smi -pm 1
		mv /var/lib/waagent/custom-script/download/1/rdma-autoload.sh ~
		create_cron_job()
		{
			# Register cron tab so when machine restart it downloads the secret from azure downloadsecret
			crontab -l > downloadsecretcron
			echo '@reboot /root/rdma-autoload.sh >> /root/execution.log' >> downloadsecretcron
			crontab downloadsecretcron
			rm downloadsecretcron
		}
		echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
		create_cron_job
	fi
else
	if check_infini;then
		echo "CPU with Infini"
	else
		echo "CPU only"
	fi
fi

shutdown -r +1
