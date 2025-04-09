# Setup on Ubuntu 22.04

## Installation
```
mkdir -p $HOME/.local/bin $HOME/.local/lib $HOME/.config/nvim
```
### Neovim
```console
wget -P $HOME/.local/bin https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage \
&& chmod +x $HOME/.local/bin/nvim-linux-x86_64.appimage \
&& ln -s $HOME/.local/bin/nvim-linux-x86_64.appimage $HOME/.local/bin/nvim
```
### Others
```
sudo apt install -y ripgrep bat zsh fuse clangd python3-pip python3-venv
```
```
pip install -U pynvim
```

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
echo <your_token> | gh auth login --with-token \
&& gh auth setup-git
```


## Clone this repo and install dotfiles
```console
git clone https://github.com/tlrmchlsmth/dotfiles \
&& cd dotfiles
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
cp ./zshrc $HOME/.zshrc \
&& cp -r ./config/* $HOME/.config/ \
&& cp -r ./local/* $HOME/.local/
```

## Configure Git
```console
git config --global user.email "tysmith@redhat.com" \
&& git config --global user.name "Tyler Michael Smith" \
&& git config pull.rebase false 
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
