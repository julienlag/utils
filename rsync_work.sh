#!/bin/bash

rsync -a --info=progress2 --delete crg:/users/rg/jlagarde/projects/encode/scaling/whole_genome/lncRNACapture_phase3/plots $HOME/work/lncRNACapture_phase3/ &> $HOME/work/lncRNACapture_phase3.rsync.log &
