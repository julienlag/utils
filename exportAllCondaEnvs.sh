#!/bin/bash


source ~/.bashrc
# modified from https://github.com/conda/conda/issues/5165

NOW=$(date "+%Y-%m-%d")
EXPORT_DIR="$HOME/condaEnvExport/envs-$NOW"
ln -srf $EXPORT_DIR $(dirname $EXPORT_DIR)/$(basename $EXPORT_DIR $NOW)latest
mkdir -p $EXPORT_DIR
ENVS=$(conda env list | grep '^\w' | cut -d' ' -f1)
for env in $ENVS; do
	echo "Exporting $env..."
    conda activate $env
    conda env export > $EXPORT_DIR/$env.yml
    echo "Done."
done
