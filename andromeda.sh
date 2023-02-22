#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '    _                 _                      '
echo -e '   / \   ___ __ _  __| | ___ _ __ ___  _   _ '
echo -e '  / _ \ / __/ _  |/ _  |/ _ \  _   _ \| | | |'
echo -e ' / ___ \ (_| (_| | (_| |  __/ | | | | | |_| |'
echo -e '/_/   \_\___\__ _|\__ _|\___|_| |_| |_|\__  |'
echo -e '                                       |___/ '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Wallet"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export ANDROMEDA_CHAIN_ID=galileo-3" >> $HOME/.bash_profile
source $HOME/.bash_profile

# update
sudo apt update && sudo apt upgrade -y

# packages

sudo apt install curl build-essential git wget jq make gcc tmux -y

# install go
if ! [ -x "$(command -v go)" ]; then
ver="1.19.4"
cd $HOME
wget -O go1.19.4.linux-amd64.tar.gz https://golang.org/dl/go1.19.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz && sudo rm go1.19.4.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
fi

# download binary
cd $HOME
rm -rf andromedad
git clone https://github.com/andromedaprotocol/andromedad.git
cd andromedad
git checkout galileo-3-v1.1.0-beta1
make install

# config
andromedad config chain-id galileo-3
andromedad config keyring-backend test

# init
andromedad init $NODENAME --chain-id galileo-3

# download genesis and addrbook
curl -L https://raw.githubusercontent.com/andromedaprotocol/testnets/galileo-3/genesis.json > $HOME/.andromedad/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/andromeda-testnet/addrbook.json > $HOME/.andromedad/config/addrbook.json

# set minimum gas price
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.25uandr\"/" $HOME/.andromedad/config/app.toml

# set peers and seeds
SEEDS=''
PEERS='9d058b4c4eb63122dfab2278d8be1bf6bf07f9ef@andromeda-testnet.nodejumper.io:26656,c043b90a737b92b26b39c52c502d7468dc6b1481@46.0.203.78:22258,9d058b4c4eb63122dfab2278d8be1bf6bf07f9ef@65.109.86.236:26656,7ac17e470c16814be55aa02a1611b23a3fba3097@75.119.141.16:26656,c5f6021d8da08ff53e90725c0c2a77f8d65f5e03@195.201.195.40:26656,bcdd1b337504f2d3523f6d63a7de1a2641187908@154.26.130.175:26656,1d94f397352dc20be4b56e4bfd9305649cbac778@65.108.232.150:20095,749114faeb62649d94b8ed496efbdcd4a08b2e3e@136.243.93.134:20095,20248068f368f5d1eda74646d2bfd1fcdaffb3e1@89.58.59.75:60656,bd323d2c7ce260b831d20923d390e4a1623f32c4@213.239.215.195:20095,bb81a52f86a5332e447373796f8a0b99f195816d@5.78.67.243:26656'
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.andromedad/config/config.toml

# disable indexing
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.andromedad/config/config.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.andromedad/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.andromedad/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.andromedad/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.andromedad/config/app.toml
sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.andromedad/config/app.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.andromedad/config/config.toml

# create service
sudo tee /etc/systemd/system/andromedad.service > /dev/null << EOF
[Unit]
Description=Andromeda testnet Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which andromedad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

andromedad tendermint unsafe-reset-all --home $HOME/.andromedad --keep-addr-book

curl https://snapshots-testnet.nodejumper.io/andromeda-testnet/galileo-3_2023-02-14.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.andromedad

# start service
sudo systemctl daemon-reload
sudo systemctl enable andromedad
sudo systemctl start andromedad

break
;;

"Create Wallet")
andromedad keys add $WALLET
echo "============================================================"
echo "Save address and mnemonic"
echo "============================================================"
ANDROMEDA_WALLET_ADDRESS=$(andromedad keys show $WALLET -a)
ANDROMEDA_VALOPER_ADDRESS=$(andromedad keys show $WALLET --bech val -a)
echo 'export ANDROMEDA_WALLET_ADDRESS='${ANDROMEDA_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export ANDROMEDA_VALOPER_ADDRESS='${ANDROMEDA_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile

break
;;

"Create Validator")
andromedad tx staking create-validator \
  --amount 1000000uandr \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey  $(andromedad tendermint show-validator) \
  --moniker $NODENAME \
  --chain-id galileo-3 \
  --fees=44300uandr \
  --gas=auto
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
