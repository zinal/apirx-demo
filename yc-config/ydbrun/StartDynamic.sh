#! /bin/sh

. $HOME/Config.sh

screen -m -d ydbd server --grpc-port 2136 --ic-port 19002 --mon-port 8766 \
    --yaml-config $HOME/ydbconf/dynamic.yaml --tenant /Root/testdb \
    --node-broker grpc://ydb-s0:2135
