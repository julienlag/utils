#!/bin/bash
sleep 200s
autossh -N -L 9090:127.0.0.1:8384 lehp &> ~/log/connectLehSyncthing.log &
#access through http://localhost:9090/
