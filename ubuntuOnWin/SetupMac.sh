# Install Anaconda3 on Mac
brew install --cask anaconda

# Add Anaconda3 to PATH in .zshrc for CLI access
echo 'export PATH="/opt/homebrew/anaconda3/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc  # Reload .zshrc to apply changes

# Check Anaconda installation
conda --version

# Create a Conda environment with Python 3.9
conda create --name testEnv3.9 python=3.9

# Initialize and activate the new Conda environment
conda init zsh
conda activate testEnv3.9

# Deactivate the Conda environment
conda deactivate  