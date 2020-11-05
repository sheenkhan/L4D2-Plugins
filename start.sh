#!/bin/sh
pkill -9 srcds_
screen ~/game/l4d2/srcds_run -game left4dead2 -port 35001 -tickrate 100 -ip 0.0.0.0 +map c5m1_waterfront +exec server.cfg
