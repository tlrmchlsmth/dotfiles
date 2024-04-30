# Setup on Ubuntu 22.04

## Install Github CLI
```console
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
&& sudo mkdir -p -m 755 /etc/apt/keyrings \
&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y
```

Log into Github:

https://github.com/settings/tokens/new
```console
echo <your_token> | gh auth login --with-token
```

## Clone this repo and install dotfiles
```console
git clone https://github.com/tlrmchlsmth/dotfiles
cd dotfiles
```

Install oh my zsh (and let it change your default shell)
```console
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Install oh my zh fish autocomplete plugin
```console
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```
Copy dotfiles:
```console
mkdir -p $HOME/.local/bin $HOME/.local/lib $HOME/.config/nvim
cp ./zshrc $HOME/.zshrc
cp -r ./config/* $HOME/.config/
```

## Installation
### Neovim
```console
wget -P $HOME/.local/bin https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
chmox +x $HOME/.local/bin/nvim.appimage
ln -s $HOME/.local/bin/nvim.appimage $HOME/.local/bin/nvim
```
### Others
```
sudo apt install ripgrep
```
```
pip install -U pynvim
```

## Huggingface CLI
First install the huggingface hub cli
```console
pip3 install -U "huggingface_hub[cli]"
```
Then create a new token and log in.

https://huggingface.co/settings/tokens
```console
huggingface-cli login --token <your token>
```
