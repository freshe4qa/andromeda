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
PEERS='9d058b4c4eb63122dfab2278d8be1bf6bf07f9ef@andromeda-testnet.nodejumper.io:26656,69e89a5169fef99ed1b72dadd4f5c7b801616c88@142.132.209.236:21256,29a9c5bfb54343d25c89d7119fade8b18201c503@209.34.206.32:26656,50ca8e25cf1c5a83aa4c79bb1eabfe88b20eb367@65.108.199.120:61356,749114faeb62649d94b8ed496efbdcd4a08b2e3e@136.243.93.134:20095,50ce639d8889108b488f0aa802468bc13d4873a4@75.119.159.195:26656,20248068f368f5d1eda74646d2bfd1fcdaffb3e1@89.58.59.75:60656,4a3bba3812a9b1d32e928ee1ecfcbe25670f29da@95.216.241.112:11656,e4d0c8cf6a3dbee8af43582bb14e6e1077028341@198.244.179.125:30170,f17030edb4e4ec7143c3e3bbbfaeee3dd1a619f2@194.34.232.224:56656,bd323d2c7ce260b831d20923d390e4a1623f32c4@213.239.215.195:20095,c45d01b216a7f24a06448a47b6cf19a42e74c29b@65.21.170.3:32656,1d94f397352dc20be4b56e4bfd9305649cbac778@65.108.232.150:20095,488fb9232083b58f4959b63e559ae75b8817c57e@51.159.197.227:26656,6006190d5a3a9686bbcce26abc79c7f3f868f43a@37.252.184.230:26656,3b998a882d8d9bcb2869eef988af86254e0e9602@89.116.29.20:26656,8d5b60d185f1c61a3070c249ac162d1856e75927@161.97.175.56:36656,c043b90a737b92b26b39c52c502d7468dc6b1481@46.0.203.78:22258,fc1c12503b0fd8dfcef4a9ccd0af7a26f9d0738f@51.91.153.78:32705,72bba2142c9cada7e4b8e861fb79e8a66e345d99@95.217.236.79:50656,18dcd9769f1b9b16730c432cdc1155c7fe90e834@136.243.56.252:56656,b83b19437fe160b0ea94c7c37556e3d5b9978e5a@135.181.160.61:11656,1c9d70cda1b46e8a33a39783e9af0ad8b5d876ac@65.109.85.225:3340,5e5186020063f7f8a3f3c6c23feca32830a18f33@65.109.174.30:56656,39627f2386fe19679396314966febf9827fbed46@195.201.147.57:60656,2cd625793bb1131c642987e6b6bb9e46fd4a868c@141.95.124.226:32636,38a626dfc05c0d9756098349ce8ccd532496d6a2@65.108.206.118:61456,757ac962fdf68a5382f745d1d69d7971a50d54e7@95.217.238.105:26656,239eeebb9c4c32f5ca91b22322fed2486aee01b5@195.201.197.4:30656,99cebda3a65a35b9a6a8bef774c8b92c1e548aa5@65.108.226.26:36656,433cc64756cb7f00b5fb4b26de97dc0db72b27ca@65.108.216.219:6656,e83b6c8460fd2273267fa6bc789c8eca08d7c13f@85.10.192.238:26656,704e605f9bd65912d8c65a58f955601c31188548@65.21.203.204:19656,2475bcd6fc1950d8ddecfccd2c3161ce99130741@194.126.172.250:36656,117bf8ca700de022d9c87cd7cc7155958dc0ba23@185.188.249.18:02656,fe53a0a745aac8e8466150b890a357f4820d0f3a@65.109.85.208:26656,ef30bb942109dbb6d1a13c3c32c46459689a6c15@162.55.245.219:19656,df7cf95427701d6d00797042fb8548a7f8eeeb6e@172.104.159.69:55716,dfa4155254cf862fbd411b9e02e26ecb00cd2436@85.10.198.171:26456,139e89b8868aed5c5922a563ecd5002959af04ff@65.108.111.236:55716,4cd929e58c35970289659e402a582115671baaee@65.109.106.91:25656,ea02551ef2aea634e10b60edc0020a42fe79416a@46.101.82.159:26656,0cc98f28ed826b3b43d2c88deb214ff01b36f6ce@159.69.126.18:15656,da069807b2c490b8adf09760236cd7e04a47de29@65.108.227.112:36656,695998981b66ee04c1b0117892313742dc66a048@65.109.180.242:11656,f51b215535e43428b7122c3d3ebbb4ab20c1b808@185.9.144.138:26656,e2efe3e1d7e0ed2e5b6a1b384c47f745e9f205ac@65.108.141.109:31656,7fd9a427a03f0e8632d2ff4b6fe32e99e3151f04@23.88.71.247:31656,f1d30c5f2d5882823317718eb4455f87ae846d0a@85.239.235.235:30656,5cfce64114f98e29878567bdd1adbebe18670fc6@65.108.231.124:30656,247f3c2bed475978af238d97be68226c1f084180@88.99.164.158:4376'
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
  --fees=2000uandr \
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
