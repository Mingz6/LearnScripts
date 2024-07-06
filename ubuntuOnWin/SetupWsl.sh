# Run the following cli in terminal to install WSL
wsl --install

# Display Ubuntu directory if successfully installed
ls ../..

#  Generated training folder
mkdir trainingData

#  download the dataset from the server to local .
scp -r <jerry>@<255.255.99.99>:/data/ming/tiny-imagenet.zip .

#  For Unraid system list the full path
root@NAS:~# pwd
/root

# Now Back to WSL
# Update apt packges and upgrade (package management)

sudo apt update && apt upgrade

# Install the NVIDIA CUDA Toolkit
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-5

# Check GCC version
gcc --version
# Check GPU
nvidia-smi

# download conda
https://www.anaconda.com/download/

# install conda
bash Anaconda3-2024.02-1-Linux-x86_64.sh

# Check Current Path
echo $PATH

# Add conda to path
vim ~/.bashrc
export PATH="/home/ming/anaconda3/bin:$PATH"
# Save and exit
# esc :wq


# Install cudnn
https://developer.nvidia.com/cudnn-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_network

wget https://developer.download.nvidia.com/compute/cudnn/9.2.0/local_installers/cudnn-local-repo-ubuntu2204-9.2.0_1.0-1_amd64.deb
sudo dpkg -i cudnn-local-repo-ubuntu2204-9.2.0_1.0-1_amd64.deb
sudo cp /var/cudnn-local-repo-ubuntu2204-9.2.0/cudnn-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cudnn

# if failed. this may caused by a bug. you can fix by the following cli
sudo ln -s libcuda.so.1.1 libcuda.so.1

# reinstall cudnn
sudo apt-get --purge remove cudnn
sudo apt-get -y install cudnn
sudo apt-get -y install cudnn-cuda-12

# Modify the LD_LIBRARY_PATH
vim ~/.bashrc
# add the following line
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
# esc :wq
source ~/.bashrc
echo $LD_LIBRARY_PATH

# install nvidia toolkit
sudo apt install nvidia-cuda-toolkit

# create a new conda environment
conda create --name testEnv3.9 python=3.9
# for study https://conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html

# activate the environment
conda activate testEnv3.9

conda env list

source ~/.bashrc

# install packages
pip install numpy
# install pytorch
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121


# watching GPU
watch nvidia-smi
export CUDA_VSIBLE_DEVICES=1

# Use this carefully. It force all process to use 2nd GPU
os.environ['CUDA_VISIBLE_DEVICES'] = '1'

# Coding part
import pytorch

d1 = 'cuda:0'
d2 = 'cuda:1'
x = torch.rand(1000,1000)
y = torch.rand(1000,1000)
x = x.to(d1)
# x
# tensor([[0.6577, 0.5031, 0.0575,  ..., 0.5458, 0.0573, 0.2335],
#         [0.0230, 0.3552, 0.2994,  ..., 0.7154, 0.2068, 0.0031],
#         [0.2932, 0.5924, 0.1053,  ..., 0.1576, 0.7063, 0.7830],
#         ...,
#         [0.9673, 0.1841, 0.7724,  ..., 0.3412, 0.6347, 0.4029],
#         [0.9051, 0.3989, 0.5454,  ..., 0.9876, 0.6385, 0.6119],
#         [0.8512, 0.7616, 0.3554,  ..., 0.9049, 0.7272, 0.9278]],
#        device='cuda:0')
y = y.to(d2)
# >>> y
# tensor([[0.9203, 0.4237, 0.5664,  ..., 0.5897, 0.5871, 0.3757],
#         [0.9226, 0.0441, 0.4391,  ..., 0.5365, 0.3050, 0.1207],
#         [0.3529, 0.2415, 0.1076,  ..., 0.0698, 0.3708, 0.2682],
#         ...,
#         [0.3076, 0.9820, 0.9885,  ..., 0.3287, 0.2188, 0.4782],
#         [0.8919, 0.2197, 0.5592,  ..., 0.3608, 0.6655, 0.9308],
#         [0.8816, 0.3879, 0.8819,  ..., 0.8330, 0.3144, 0.7964]],
#        device='cuda:1')
