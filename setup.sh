#!/bin/bash

GLOBAL_PATH=$(pwd)
source "$(dirname $0)/params.sh"

TESTNET_DIR=$GLOBAL_PATH/node;
NODE_HTTP_SRV_ADDR="0.0.0.0:$API_PORT"
NODE_P2P_LST_ENDP="0.0.0.0:$P2P_PORT"
NODE_P2P_SRV_ADDR="$NODE_IP:$P2P_PORT"
BASE_CONFIG=$GLOBAL_PATH/$TESTNET_DIR/config.ini;
signature='#!/bin/bash'

if [[ ! -d $WALLET_DIR ]]; then
    echo "..:: Creating Wallet Dir: $WALLET_DIR ::..";
    mkdir $WALLET_DIR

    echo "..:: Creating Wallet start.sh ::..";
    # Creating start.sh for wallet
    echo -ne "$signature" > $WALLET_DIR/start.sh
    echo "DATADIR=$WALLET_DIR" >> $WALLET_DIR/start.sh
    echo "\$DATADIR/stop.sh" >> $WALLET_DIR/start.sh
    echo "$EOS_SOURCE_DIR/build/programs/keosd/keosd --data-dir \$DATADIR --http-server-address $WALLET_HOST:$WALLET_PORT \"\$@\" > $WALLET_DIR/stdout.txt 2> $WALLET_DIR/stderr.txt  & echo \$! > \$DATADIR/wallet.pid" >> $WALLET_DIR/start.sh
    echo "echo \"Wallet started\"" >> $WALLET_DIR/start.sh
    chmod u+x $WALLET_DIR/start.sh


    # Creating stop.sh for wallet
    echo -ne "$signature" > $WALLET_DIR/stop.sh
    echo "DIR=$WALLET_DIR" >> $WALLET_DIR/stop.sh
    echo '
    if [ -f $DIR"/wallet.pid" ]; then
        pid=$(cat $DIR"/wallet.pid")
        echo $pid
        kill $pid
        rm -r $DIR"/wallet.pid"
        echo -ne "Stopping Wallet"
        while true; do
            [ ! -d "/proc/$pid/fd" ] && break
            echo -ne "."
            sleep 1
        done
        echo -ne "\rWallet stopped. \n"
    fi
    ' >>  $WALLET_DIR/stop.sh
    chmod u+x $WALLET_DIR/stop.sh

fi

#start Wallet
echo "..:: Starting Wallet ::.."
if [[ ! -f $WALLET_DIR/wallet.pid ]]; then
    $WALLET_DIR/start.sh
fi

    # Creating node start.sh
    echo "..:: Creating start.sh ::..";
    echo -ne "$signature" > $TESTNET_DIR/start.sh
    echo "NODEOS=$EOS_SOURCE_DIR/build/programs/nodeos/nodeos" >> $TESTNET_DIR/start.sh
    echo "DATADIR=$TESTNET_DIR" >> $TESTNET_DIR/start.sh
    echo -ne "\n";
    echo "\$DATADIR/stop.sh" >> $TESTNET_DIR/start.sh
    echo -ne "\n";
    echo "\$NODEOS --data-dir \$DATADIR --config-dir \$DATADIR \"\$@\" > \$DATADIR/stdout.txt 2> \$DATADIR/stderr.txt &  echo \$! > \$DATADIR/nodeos.pid" >> $TESTNET_DIR/start.sh
    chmod u+x $TESTNET_DIR/start.sh


    # Creating node stop.sh
    echo "..:: Creating stop.sh ::..";
    echo -ne "$signature" > $TESTNET_DIR/stop.sh
    echo "DIR=$TESTNET_DIR" >> $TESTNET_DIR/stop.sh
    echo -ne "\n";
    echo '
    if [ -f $DIR"/nodeos.pid" ]; then
        pid=$(cat $DIR"/nodeos.pid")
        echo $pid
        kill $pid
        rm -r $DIR"/nodeos.pid"
        echo -ne "Stopping Nodeos"
        while true; do
            [ ! -d "/proc/$pid/fd" ] && break
            echo -ne "."
            sleep 1
        done
        echo -ne "\rNodeos stopped. \n"
    fi
    ' >>  $TESTNET_DIR/stop.sh
    chmod u+x $TESTNET_DIR/stop.sh


    # Creating cleos.sh
    echo "..:: Creating cleos.sh ::..";
    echo -ne "$signature" > $TESTNET_DIR/cleos.sh
    echo "CLEOS=$EOS_SOURCE_DIR/build/programs/cleos/cleos" >> $TESTNET_DIR/cleos.sh
    echo -ne "\n"
    echo "\$CLEOS -u https://127.0.0.1:$API_PORT --wallet-url http://127.0.0.1:$WALLET_PORT \"\$@\"" >> $TESTNET_DIR/cleos.sh
    chmod u+x $TESTNET_DIR/cleos.sh

# config.ini
echo -ne "\n\n..:: Creating config.ini ::..\n\n";

echo '
blocks-dir = "blocks"
chain-state-db-size-mb = 65536
reversible-blocks-db-size-mb = 340
contracts-console = false
# Override default maximum ABI serialization time allowed in ms (eosio::chain_plugin)
abi-serializer-max-time-ms = 2000

# actor-whitelist =
# actor-blacklist =
# contract-whitelist =
# contract-blacklist =
filter-on = *
# https-client-root-cert =

https-client-validate-peers = 1

# https-certificate-chain-file =
# https-private-key-file =
access-control-allow-origin = *
# access-control-allow-headers =
# access-control-max-age =
access-control-allow-credentials = false

http-server-address = '$NODE_HTTP_SRV_ADDR'
p2p-listen-endpoint = '$NODE_P2P_LST_ENDP'
p2p-server-address = '$NODE_P2P_SRV_ADDR'
p2p-max-nodes-per-host = 1

agent-name = "agent"
allowed-connection = any
' >> $BASE_CONFIG

echo 'signature-provider = '$SIGNING_PUBLIC_KEY'='KEY:$SIGNING_PRIV_KEY'' >> $BASE_CONFIG;

echo 'producer-name = '$PRODUCER_NAME'' >> $BASE_CONFIG;

echo '
max-clients = 100
connection-cleanup-period = 30
network-version-match = 1
sync-fetch-span = 100
max-implicit-request = 1500
enable-stale-production = true
pause-on-startup = false
max-transaction-time = 10000
max-irreversible-block-age = -1
txn-reference-block-lag = 0

unlock-timeout = 900

plugin = eosio::chain_api_plugin
plugin = eosio::history_api_plugin
plugin = eosio::chain_plugin
plugin = eosio::history_plugin
' >> $BASE_CONFIG
