yum -y install git-all
sudo nvidia-smi -pm 1

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
  echo 'export I_MPI_DAPL_TRANSLATION_CACHE=0' >> ~/.bashrc
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
CFLAGS="-I/usr/local/cuda/include" pip install git+https://github.com/chainer/chainermn@non-cuda-aware-comm
shutdown -r +1
