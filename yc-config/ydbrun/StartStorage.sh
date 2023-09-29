#! /bin/sh

. $HOME/Config.sh

screen -m -d ydbd server --log-level 3 --tcp --yaml-config  $HOME/ydbconf/storage.yaml \
    --grpc-port 2135 --ic-port 19001 --mon-port 8765 --node static
