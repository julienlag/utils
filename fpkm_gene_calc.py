#!/usr/bin/python26
# stdin = results of 'coverageBed' assuming that genes have been collapsed, 
# stdout = same as input wth 1 additional field of FPKM values

import sys

totalFragments = int(sys.argv[1])

class locus:
    def __init__(self, lineFields):
        self.seqname = lineFields[0]
        self.source = lineFields[1]
        self.start = int(lineFields[3])
        self.end = int(lineFields[4])
        self.strand = lineFields[6]
        self.attributes = lineFields[8]
        self.numReads = float(lineFields[9])
        self.numCoveredBases = float(lineFields[10])
        self.len = float(lineFields[11])

class collapsedGene:
    def __init__(self, id, gtfLine, lineFields):
        self.id = id
        self.loci = []
        self.addLocus(gtfLine, lineFields)

    def addLocus(self, gtfLine, lineFields):
        self.loci.append(locus(lineFields))

geneDict = {}
for line in sys.stdin:
    fields = line.split("\t")
    attributes = fields[8].strip().split("; ")
    geneAttribute = attributes[0].split(" ") # assumes the gene attribute is in the first position
    geneID = geneAttribute[1].strip('"')
    if geneID in geneDict:
        geneDict[geneID].addLocus(line.strip(), fields)
    else:
        geneDict[geneID] = collapsedGene(geneID, line.strip(), fields)

for geneID, gene in geneDict.iteritems():
    geneStart = 1000000000
    geneEnd = 0
    readCount = 0
    coveredLen = 1
    totalLen = 0
    for locus in gene.loci:
        if locus.start < geneStart:
            geneStart = locus.start
        if locus.end > geneEnd:
            geneEnd = locus.end
        readCount += locus.numReads
        coveredLen += locus.numCoveredBases
        totalLen += locus.len
    percentCoverage = coveredLen/totalLen
    fpkmVal = 1000000000*readCount/coveredLen/totalFragments
    # Some tokens in the printed line come from the last locus in the gene.
    # It is assumed these values are all the same for all loci in that gene.
    print '{0}\t{1}\texon\t{2}\t{3}\t.\t{4}\t.\t{5}\t{6}\t{7}\t{8}\t{9}\t{10}'.format(locus.seqname, locus.source, geneStart, geneEnd, locus.strand, locus.attributes, readCount, coveredLen, totalLen, percentCoverage, fpkmVal)
