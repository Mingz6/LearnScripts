# This script outlines the steps to set up a Windows Subsystem for Linux (WSL) environment, install necessary packages, and configure CUDA for GPU computing with PyTorch.

# Step 1: Install WSL
# Run the following command in the terminal to install WSL.
wsl --install

# Step 2: Verify Installation
# Display the Ubuntu directory to verify successful installation.
ls ../..

# Step 3: Prepare Data Directory
# Create a directory for training data.
mkdir trainingData

# Step 4: Transfer Data
# Download the dataset from a remote server to the local machine. Replace placeholders with actual values.
scp -r <username>@<server_ip>:/path/to/<tiny-imagenet.zip> .

# Step 5: Update and Upgrade Packages
# Update package lists and upgrade installed packages.
sudo apt update && sudo apt upgrade

# Step 6: Install NVIDIA CUDA Toolkit
# Download and install the CUDA Toolkit for WSL.
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-5

# Step 7: Verify CUDA Installation
# Check the installed GCC version and GPU availability.
gcc --version
nvidia-smi

# Step 8: Install Anaconda
# Download and install Anaconda for managing Python versions and packages.
# Replace the URL with the latest Anaconda installer link.
wget https://www.anaconda.com/download/
bash Anaconda3-2024.02-1-Linux-x86_64.sh

# Step 9: Configure Environment
# Add Anaconda to the PATH environment variable.
echo 'export PATH="/home/<username>/anaconda3/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Step 10: Install cuDNN
# Download and install cuDNN. Replace the URL with the latest cuDNN installer link for your CUDA version.
wget https://developer.download.nvidia.com/compute/cudnn/9.2.0/local_installers/cudnn-local-repo-ubuntu2204-9.2.0_1.0-1_amd64.deb
sudo dpkg -i cudnn-local-repo-ubuntu2204-9.2.0_1.0-1_amd64.deb
# sudo cp /var/cudnn-local-repo-ubuntu2204-9.2.0/cudnn-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cudnn

# If installation fails due to a missing library, create a symbolic link as shown below and reinstall cuDNN.
sudo ln -s /usr/local/cuda/lib64/libcuda.so.1.1 /usr/local/cuda/lib64/libcuda.so.1
sudo apt-get --purge remove cudnn
sudo apt-get -y install cudnn
# sudo apt-get -y install cudnn-cuda-12

# Step 11: Configure Library Paths
# Add CUDA library paths to LD_LIBRARY_PATH.
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

# Step 12: Install NVIDIA CUDA Toolkit (Alternative Method)
# Install the NVIDIA CUDA Toolkit using apt.
sudo apt install nvidia-cuda-toolkit

# Step 13: Create and Activate a Conda Environment
# Create a new Conda environment with Python 3.9.
conda create --name testEnv3.9 python=3.9
conda activate testEnv3.9

# Step 14: Install Python Packages
# Install necessary Python packages using pip.
pip install numpy
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Step 15: Monitor GPU Usage
# Use the watch command to monitor GPU usage.
watch nvidia-smi
# Force PyTorch to use GPU #2.
# export CUDA_VSIBLE_DEVICES=1

# Step 16: PyTorch GPU Test
# Test PyTorch GPU operations by allocating tensors to different GPUs.

# # Use this carefully. It force all process to use 2nd GPU
# os.environ['CUDA_VISIBLE_DEVICES'] = '1'
import torch

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


# enter `code` in ubuntu terminal to open vs code with wsl environment

# Follow the instructions to install and config the ssh on wsl.

# https://medium.com/@wuzhenquan/windows-and-wsl-2-setup-for-ssh-remote-access-013955b2f421

netsh interface portproxy add v4tov4 listenaddress=192.168.1.246 listenport=8889 connectaddress=172.26.157.41 connectport=22

# RUn the following command in Windows Terminal to allow the port 8889 to be accessed from the internet.
netsh advfirewall firewall add rule `
name="wslEnableRemote" `
dir=in `
action=allow `
protocol=TCP `
localport=8889

# Open the port 8889 on the Windows firewall.
New-NetFirewallRule -DisplayName "Allow SSH on port 8889" -Direction Inbound -Protocol TCP -LocalPort 8889 -Action Allow -Profile Any

# <!-- Setup static IP for the windows on your router. -->

# Access the WSL from a remote machine using the following command.
ssh ming@192.168.1.246 -p 8889

# Access the WSL from a public machine using the following command.
ssh ming@<public_wan_ip> -p <external_ssh_port>