#!/bin/bash

#############################################################################
is_ubuntu()
{
	python -mplatform | grep -qi Ubuntu
	return $?
}

is_centos()
{
        cat /etc/centos-release | grep CentOS
	#python -mplatform | grep -qi CentOS
	return $?
}

is_Ubuntu()
{
	cat /etc/issue | grep Ubuntu
	return $?
}
enable_rdma()
{
	   # enable rdma    
	   sudo sed -i  "s/# OS.EnableRDMA=y/OS.EnableRDMA=y/g" /etc/waagent.conf
	   sudo sed -i  "s/# OS.UpdateRdmaDriver=y/OS.UpdateRdmaDriver=y/g" /etc/waagent.conf
}

install_Chainer()
{
	cd /usr/local
	#install numpy and six required version as chainer is dependent on numpy
	#install_cython_protobuf #required for numpy/six/cupy
	pip install -U cython
	sudo curl -L -O https://pypi.python.org/packages/b2/30/ab593c6ae73b45a5ef0b0af24908e8aec27f79efcda2e64a3df7af0b92a2/protobuf-3.1.0-py2.py3-none-any.whl ##md5=f02742e46128f1e0655b44c33d8c9718
	pip install protobuf-3.1.0-py2.py3-none-any.whl
	
	#install_numpy
	cd /usr/local
	sudo curl -L -O  https://pfnresources.blob.core.windows.net/chainermn-v1-packages/numpy-1.13.3.tar.gz
	sudo tar -zxf numpy-1.13.3.tar.gz
	cd numpy-1.13.3	
	python setup.py install
	
	#install_six
	cd /usr/local
	sudo curl -L -O  https://pfnresources.blob.core.windows.net/chainermn-v1-packages/six-1.11.0.tar.gz
	sudo tar -zxf six-1.11.0.tar.gz
	cd six-1.11.0
	python3 setup.py install	
	#if none of above commands work it will update six to 1.11.0
	easy_install --upgrade six
	
	#install_cupy
	cd /usr/local
	#may require NCCL first
	#sudo curl -L -O  https://pfnresources.blob.core.windows.net/chainermn-v1-packages/cupy-2.2.0.tar.gz
	#sudo tar -zxf cupy-2.2.0.tar.gz
	#cd cupy-2.2.0
	#PATH=/usr/local/cuda/bin:$PATH CUDA_PATH=/usr/local/cuda python3 setup.py install 
	PATH=/usr/local/cuda/bin:$PATH CUDA_PATH=/usr/local/cuda pip install cupy #It install latest CuPy version
	
	#pip install chainer
	cd /usr/local
	sudo curl -L -O  https://pfnresources.blob.core.windows.net/chainermn-v1-packages/chainer-3.2.0.tar.gz
	sudo tar -zxf chainer-3.2.0.tar.gz
	cd chainer-3.2.0
	#python3 setup.py install #install from root works well too
	pip install chainer --no-cache #It install latest chainer	
}

install_chainermn()
{
	#CFLAGS="-I/usr/local/cuda/include" pip install git+https://github.com/chainer/chainermn --version 1.1.0
	if is_centos; then
	sudo cp /opt/nccl/build/include/nccl.h /usr/local/cuda/include
	fi	
	cd /usr/local
	CFLAGS="-I /usr/local/cuda/include" pip install chainermn==1.1.0
}

install_intel_mpi
{
#install_Intel _MPI
		if [ ! -d /opt/l_mpi_2017.3.196 ]; then
			cd /opt
			sudo mv intel intel_old
			#PKG_Name=l_mpi_2017.3.196.tgz
			#PKG_Name=l_mpi_2018.1.163.tgz
			#PKG_Name=l_mpi-rt_p_5.1.3.223.tgz.gz
			#sudo curl -L -O http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/11595/l_mpi_2017.3.196.tgz
			#sudo tar zxvf l_mpi_2017.3.196.tgz
			#sudo rm -rf l_mpi_2017.3.196.tgz
			#cd l_mpi_2017.3.196
			#sudo curl -L -O http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/11595/${PKG_Name}
			#sudo curl -L -O https://pfnresources.blob.core.windows.net/chainermn-v1-packages/${PKG_Name}
			sudo curl -L -O http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/9278/l_mpi_p_5.1.3.223.tgz
			#gzip -d ${PKG_Name}
			sudo tar zxvf l_mpi_p_5.1.3.223.tgz
			sudo rm -rf l_mpi_p_5.1.3.223.tgz
			cd l_mpi_p_5.1.3.223
			sudo sed -i -e "s/decline/accept/g" silent.cfg
			#sudo sed -i -e "s/#ACTIVATION_SERIAL_NUMBER=snpat/ACTIVATION_SERIAL_NUMBER=VTDT-4246MB9S/g" silent.cfg
			#sudo sed -i -e "s/ACTIVATION_TYPE=exist_lic/ACTIVATION_TYPE=serial_number/g" silent.cfg
			sudo ./install.sh --silent silent.cfg
		fi

		if grep -q "I_MPI" ~/.bashrc; then :; else
			echo 'export I_MPI_FABRICS=shm:dapl' >> ~/.bashrc
			echo 'export I_MPI_DAPL_PROVIDER=ofa-v2-ib0' >> ~/.bashrc
			echo 'export I_MPI_DYNAMIC_CONNECTION=0' >> ~/.bashrc
			echo 'export I_MPI_FALLBACK_DEVICE=0' >> ~/.bashrc
			echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
			echo 'source /opt/intel/compilers_and_libraries_2016.3.223/linux/mpi/intel64/bin/mpivars.sh' >> ~/.bashrc	
			#echo 'source /opt/intel/compilers_and_libraries_2017.4.196/linux/mpi/intel64/bin/mpivars.sh' >> ~/.bashrc
		fi	
}

setup_chainermn_gpu()
{ 

		if is_Ubuntu; then
		sudo apt-get update
		sudo apt-get install git
		fi
		if is_centos; then
		yum -y install git-all
		fi
		install_intel_mpi
		if [ ! -d /opt/anaconda3 ]; then
			cd /opt
			#anaconda_3_5.0.1
			PKG_Name=Anaconda3-5.0.1-Linux.sh.gz
			sudo curl -L -O https://pfnresources.blob.core.windows.net/chainermn-v1-packages/${PKG_Name}
			gzip -d ${PKG_Name}			
			sudo bash ${PKG_Name::-3} -b -p /opt/anaconda3
			sudo chown hpcuser:hpc -R anaconda3
			source /opt/anaconda3/bin/activate			
		fi

		if grep -q "anaconda" ~/.bashrc; then :; else
			echo 'source /opt/anaconda3/bin/activate' >> ~/.bashrc
		fi

		#NCCL package # for ubuntu : 2.1 # for centos 1.3.4
		if [ ! -d /opt/nccl ]; then
			cd /opt
			if is_Ubuntu; then				
				sudo curl -L -O  https://pfnresources.blob.core.windows.net/chainermn-v1-packages/libnccl2_2.1.2-1+cuda9.0_amd64.deb
				sudo dpkg -i libnccl2_2.1.2-1+cuda9.0_amd64.deb
				sudo curl -L -O  https://pfnresources.blob.core.windows.net/chainermn-v1-packages/libnccl-dev_2.1.2-1+cuda9.0_amd64.deb
				sudo dpkg -i libnccl-dev_2.1.2-1+cuda9.0_amd64.deb
			fi
			if is_centos; then
				#Working using tar file
				sudo wget   https://pfnresources.blob.core.windows.net/chainermn-v1-packages/nccl-1.3.4-1.tar.gz
				tar -zxf nccl-1.3.4-1.tar.gz
				mv nccl-1.3.4-1 nccl
				cd nccl && sudo make -j && sudo make install
				
			fi			
		fi

		if grep -q "LD_LIBRARY_PATH" ~/.bashrc; then :; else
			echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
		fi


		#cudnn 
		if [ ! -f /usr/local/cuda/include/cudnn.h ]; then
			cd /usr/local
			sudo curl -L -O https://www.dropbox.com/s/241tka1skcgcjie/cudnn-9.0-linux-x64-v7.tgz
			sudo tar zxvf cudnn-9.0-linux-x64-v7.tgz
			sudo rm -rf cudnn-9.0-linux-x64-v7.tgz
						
		fi
					
		#install Chainer V3.1.0
		install_Chainer
		
		#MPICC=/opt/intel/compilers_and_libraries_2017.4.196/linux/mpi/intel64/bin/mpicc pip install mpi4py --no-cache-dir
		#CFLAGS="-I/usr/local/cuda/include" pip install git+https://github.com/chainer/chainermn@non-cuda-aware-comm
		
		install_chainermn
		alias python=python3		
		#CFLAGS="-I/usr/local/cuda/include" pip install git+https://github.com/chainer/chainermn@non-cuda-aware-comm	
		sudo nvidia-smi -pm 1		
}

setup_chainermn_gpu_infiniband()
{

		if is_Ubuntu; then
			sudo apt-get update
			sudo apt-get install git
		fi
		if is_centos; then			
			yum reinstall -y /opt/microsoft/rdma/rhel73/kmod-microsoft-hyper-v-rdma-4.2.2.144-20170706.x86_64.rpm
			yum -y install git-all
			
		fi	
		install_intel_mpi
		if [ ! -d /opt/anaconda3 ]; then
			cd /opt
			#anaconda_3_5.0.1
			PKG_Name=Anaconda3-5.0.1-Linux.sh.gz
			sudo curl -L -O https://pfnresources.blob.core.windows.net/chainermn-v1-packages/${PKG_Name}
			gzip -d ${PKG_Name}			
			sudo bash ${PKG_Name::-3} -b -p /opt/anaconda3
			sudo chown hpcuser:hpc -R anaconda3
			source /opt/anaconda3/bin/activate			
		fi

		if grep -q "anaconda" ~/.bashrc; then :; else
			echo 'source /opt/anaconda3/bin/activate' >> ~/.bashrc
		fi
		
		#NCCL package # for ubuntu : 2.1 # for centos 1.3.4		
		if [ ! -d /opt/nccl ]; then		
			cd /opt				
			#if is_Ubuntu; then
			
				#cd /opt && git clone https://github.com/azmigproject/NCCL.git 
				#cd NCCL && sudo make -j && sudo make install
				##sudo curl -L -O  https://pfnresources.blob.core.windows.net/chainermn-v1-packages/libnccl2_2.1.2-1+cuda9.0_amd64.deb
				#sudo dpkg -i libnccl2_2.1.2-1+cuda9.0_amd64.deb
				#sudo curl -L -O  https://pfnresources.blob.core.windows.net/chainermn-v1-packages/libnccl-dev_2.1.2-1+cuda9.0_amd64.deb
				#sudo dpkg -i libnccl-dev_2.1.2-1+cuda9.0_amd64.deb
			#fi
			#if is_centos; then
				#Working using tar file
				cd /opt
				sudo wget   https://pfnresources.blob.core.windows.net/chainermn-v1-packages/nccl-1.3.4-1.tar.gz
				tar -zxf nccl-1.3.4-1.tar.gz
				mv nccl-1.3.4-1 nccl
				cd nccl && sudo make -j && sudo make install
				cp /opt/nccl/build/include/nccl.h /usr/local/cuda/include
				export "PATH=/opt/nccl/build/include:$PATH"				
			#fi			
		fi

		if grep -q "LD_LIBRARY_PATH" ~/.bashrc; then :; else
			echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
		fi
		
		#cudnn 7.0.4
		if [ ! -f /usr/local/cuda/include/cudnn.h ]; then
			cd /usr/local
			#if is_centos; then
			sudo curl -L -O https://pfnresources.blob.core.windows.net/chainermn-v1-packages/cudnn-8.0-linux-x64-v7.tgz.gz
			gzip -d cudnn-8.0-linux-x64-v7.tgz.gz
			sudo tar zxvf cudnn-8.0-linux-x64-v7.tgz
			sudo rm -rf cudnn-8.0-linux-x64-v7.tgz
			#fi
			#if is_Ubuntu; then
			#sudo curl -L -O https://pfnresources.blob.core.windows.net/chainermn-v1-packages/cudnn-9.0-linux-x64-v7.tgz.gz
			#gzip -d cudnn-9.0-linux-x64-v7.tgz.gz
			#sudo tar zxvf cudnn-9.0-linux-x64-v7.tgz
			#sudo rm -rf cudnn-9.0-linux-x64-v7.tgz
			#fi
			#Copy CUDNN files to required locaiton			
			sudo cp cuda/include/cudnn.h /usr/local/cuda/include 
			sudo cp cuda/lib64/libcudnn* /usr/local/cuda/lib64
			chmod a+r /usr/local/cuda/include/cudnn.h /usr/local/cuda/lib64/libcudnn*
		fi
		
		#install Chainer V3.1.0
		install_Chainer		
		#MPICC=/opt/intel/compilers_and_libraries_2017.4.196/linux/mpi/intel64/bin/mpicc pip install mpi4py --no-cache-dir
		MPICC=/opt/intel/compilers_and_libraries_2016.3.223/linux/mpi/intel64/bin/mpicc pip install mpi4py --no-cache-dir
		install_chainermn
		alias python=python3
		
		

}

if is_Ubuntu; then       
       apt install ibverbs-utils	
fi
if is_centos; then
	yum install -y libibverbs-utils
fi

check_infini()
{

if is_Ubuntu; then 
	sudo modprobe rdma_ucm
	return $?
fi
if is_centos; then
	ibv_devices | grep mlx4
	return $?
fi
}

check_gpu()
{
	# echo "\n\n check_gpu \n\n"
	lspci | grep NVIDIA
	return $?
}

if check_gpu; then
	if check_infini; then
		enable_rdma
		#Code to setup ChainerMN on GPU based machine with infinband
		setup_chainermn_gpu_infiniband
		sudo nvidia-smi -pm 1
		echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
		if is_centos; then
		sudo yum groupinstall -y "Infiniband Support"
		sudo yum install -y infiniband-diags perftest qperf opensm git libverbs-devel dapl
				
		sudo chkconfig rdma on
		sudo chkconfig opensm on
		sudo service rdma start
		sudo service opensm start
		fi
		if is_Ubuntu; then
		create_cron_job()
		{
					
			# Register cron tab so when machine restart it downloads the secret from azure downloadsecret
			crontab -l > downloadsecretcron
			echo '@reboot /root/rdma-autoload.sh >> /root/execution.log' >> downloadsecretcron
			crontab downloadsecretcron
			rm downloadsecretcron
		}
		echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
		mv /var/lib/waagent/custom-script/download/1/rdma-autoload.sh ~
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
