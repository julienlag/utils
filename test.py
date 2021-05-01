#!/usr/bin/env python

import pandas as pd
from pprint import pprint
sampleAnnot = pd.read_table(
    "/users/project/gencode_006070/jlagarde/lncRNACapture_phase3/annotations/samples/sample_annotations.tsv", header=0, sep='\t')

sampleAnnot.set_index('sample_name', inplace=True)

# print(sampleAnnot)
# sampleAnnot.astype({'reverse_transcriptase': str})
sampleAnnotDict = sampleAnnot.to_dict('index')

if sampleAnnotDict['pacBioSII:pacBio:IsoSeq:_HpreCap_0+_AlzhBrain']['libraryPrep'] == 'IsoSeq1':
    pprint("Hello you guys")
else:
    pprint("Sorry you guys")
