#!/bin/sh
export ROOT=$(cd `dirname $0`; pwd)

$ROOT/skynet/3rd/lua/lua $ROOT/client/simpleclient.lua $ROOT $1

