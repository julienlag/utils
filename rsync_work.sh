#!/bin/bash

rsync -aqP --delete crg:/users/rg/jlagarde/projects/encode/scaling/whole_genome/lncRNACapture_phase3/plots $HOME/work/lncRNACapture_phase3/ &> $HOME/work/lncRNACapture_phase3.rsync.log &
rsync -aqP --delete crg:/users/rg/jlagarde/projects/encode/scaling/whole_genome/lncRNACapture_phase3.1/plots $HOME/work/lncRNACapture_phase3.1/ &> $HOME/work/lncRNACapture_phase3.1.rsync.log &