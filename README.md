

Table of Contents
=================
* [Compute grid in Azure](#compute-grid-in-azure)
* [ChainerMN On CentOS](#chainermn-on-centos)
* [Deployment steps](#deployment-steps)
  * [Create the jumpbox](#create-the-jumpbox)
  * [Provision the compute nodes](#provision-the-compute-nodes)
* [Running Applications](#running-applications)
  * [Validating MPI](#validating-mpi)
* [Check status of the ChainerMN nodes](#Check-status-of-the-ChainerMN-nodes)
 
# ChainerMN on Azure

These templates will build a compute grid made by a single jumpbox VM running the management services, multiple VM Scaleset for ChainerMN.
# Chainermn on centos
# Deployment steps
To setup ChainerMN two steps need to be executed :
1. Create the jumpbox
2. Provision the compute nodes where ChainerMN is setup

## Create the jumpbox
The template __deploy-jumpbox.json__ will provision the networking infrastructure as well as a master VM exposing an SSH endpoint for remote connection.   

You have to provide these parameters to the template :
* _Location_ : Select the location where NC series is available(for example East US,South Central US). 
* _Virtual Machine Name_ : Enter the virtual machine name. 
* _Virtual Machine Size_ : Select virtual machine size from the dropdown.
* _Admin Username_ : This is the name of the administrator account to create on the VM.
* _Admin Public Key_ : The public SSH key to associate with the administrator user. Format has to be on a single line 'ssh-rsa key'

## Deploy jumpbox
[![Click to deploy template on Azure](http://azuredeploy.net/deploybutton.png "Click to deploy template on Azure")](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazmigproject%2FChainerMN%2Fchainermnphase2copy1%2FChainerMN_V1.0%2Fdeploy-jumpbox.json)

### Check your deployment
Login into the jumpbox, do "sudo su hpcuser" to switch from default user to hpcuser.

## Provision the ChainerMN nodes

You have to provide these parameters to the template :
* _Location_ : Select the same location where jumpbox is deployed.
* _Virtual Machine Size_ : Select from NC series(standard_NC6, standard_NC12, standard_NC24, standard_NC24r)
* _VM Image_ : Default is **CentOS_7.3** allowed values are (CentOS_7.3, CentOS-HPC_7.3 ) recommended CentOS-HPC_7.3.
* _VM prefix Name_ : It is vm prefix.
* _Instance Count_ : it is the no. of instances inside a VMSS.
* _Master Name_ : The short name of the Master VM
* _Admin User Name_ : This is the name of the administrator account to create on the VM.
* _SSH Key Data_ : The public SSH key to associate with the administrator user. Format has to be on a single line 'ssh-rsa key'.

## Deploy ChainerMN
[![Click to deploy template on Azure](http://azuredeploy.net/deploybutton.png "Click to deploy template on Azure")](https://portal.azure.com/#create/Microsoft.Template/uri/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazmigproject%2FChainerMN%2Fchainermnphase2copy1%2FChainerMN_V1.0%2Fdeploy-chainermn.json)

## Check status of the ChainerMN nodes
 Use scripts "prerequisite.sh" to install the prerequsite (Azure CLI, Telnet and JQ) and "check_status.sh" for checking the status of    the individual instances of VMSS if VM is not running restart to them.
 Follow the document "ScriptsExecution.docx" to run the scripts.
# Running applications
## Validating MPI
Intel MPI and Infiniband are only available for A8/A9 and H16r instances. A default user named **hpcuser** has been created on the compute nodes and on the master node with passwordless access so it can be immediately used to run MPI across nodes.

To begin, you need first to ssh on the master and then switch to the **hpcuser** user. From there, either run the 2 node pingpong test from master node or ssh to one of the compute nodes, and configure MPI by following the instructions from [here](https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-classic-rdma-cluster#configure-intel-mpi)

To run the 2 node pingpong test, execute the following command

    impi_version=`ls /opt/intel/impi`
    source /opt/intel/impi/${impi_version}/bin64/mpivars.sh

    mpirun -hosts <host1>,<host2> -ppn 1 -n 2 -env I_MPI_FABRICS=shm:dapl -env I_MPI_DAPL_PROVIDER=ofa-v2-ib0 -env I_MPI_DYNAMIC_CONNECTION=0 -env I_MPI_FALLBACK_DEVICE=0 IMB-MPI1 pingpong

You should expect an output as the one below

    #------------------------------------------------------------
    #    Intel (R) MPI Benchmarks 4.1 Update 1, MPI-1 part
    #------------------------------------------------------------
    # Date                  : Thu Jan 26 02:16:14 2017
    # Machine               : x86_64
    # System                : Linux
    # Release               : 3.10.0-229.20.1.el7.x86_64
    # Version               : #1 SMP Tue Nov 3 19:10:07 UTC 2015
    # MPI Version           : 3.0
    # MPI Thread Environment:

    # New default behavior from Version 3.2 on:

    # the number of iterations per message size is cut down
    # dynamically when a certain run time (per message size sample)
    # is expected to be exceeded. Time limit is defined by variable
    # "SECS_PER_SAMPLE" (=> IMB_settings.h)
    # or through the flag => -time



    # Calling sequence was:

    # IMB-MPI1 pingpong

    # Minimum message length in bytes:   0
    # Maximum message length in bytes:   4194304
    #
    # MPI_Datatype                   :   MPI_BYTE
    # MPI_Datatype for reductions    :   MPI_FLOAT
    # MPI_Op                         :   MPI_SUM
    #
    #

    # List of Benchmarks to run:

    # PingPong

    #---------------------------------------------------
    # Benchmarking PingPong
    # #processes = 2
    #---------------------------------------------------
           #bytes #repetitions      t[usec]   Mbytes/sec
                0         1000         3.37         0.00
                1         1000         3.40         0.28
                2         1000         3.69         0.52
                4         1000         3.39         1.13
                8         1000         3.41         2.24
               16         1000         3.38         4.51
               32         1000         2.78        10.99
               64         1000         2.79        21.90
              128         1000         3.12        39.09
              256         1000         3.34        73.13
              512         1000         3.79       128.87
             1024         1000         4.85       201.48
             2048         1000         5.74       340.21
             4096         1000         7.06       552.98
             8192         1000         8.51       917.87
            16384         1000        10.86      1438.11
            32768         1000        16.55      1888.21
            65536          640        28.15      2220.37
           131072          320        53.47      2337.75
           262144          160        84.07      2973.66
           524288           80       148.77      3360.92
          1048576           40       284.91      3509.84
          2097152           20       546.43      3660.15
          4194304           10      1077.75      3711.45


    # All processes entering MPI_Finalize

____



 



