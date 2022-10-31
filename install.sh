# Install oh my zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install oh my zh fish autocomplete plugin
cwd=$PWD
cd  $HOME/.oh-my-zsh/custom/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
cd $PWD

cp zshrc $HOME/.zshrc
cp -r config $HOME/.config
cp -r ./local $HOME/.local
