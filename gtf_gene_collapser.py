#!/usr/bin/python26
# Collapses all overapping exons within a gene. This still allows for 
# a result of multiple exons per gene.
# stdin = standard gtf file, stdout = gtf file with exons collapsed per gene
# NOTE: All gtf entries with the same 'gene_id' are assumed to have matching seqname and strand
# NOTE: The output contains 'transcript_id' as an attribute, but the value is the same as the 'gene_id'.
#       This is meaningless, but included for compatible viewing in the UCSC browser

import sys

class locus:
    def __init__(self, seqname, source, start, end, strand):
        self.seqname = seqname
        self.source = source
        self.start = int(start)
        self.end = int(end)
        self.strand = strand

class collapsedGene:
    def __init__(self, id, lineFields):
        self.id = id
        self.loci = []
        self.addLocus(lineFields)

    def addLocus(self, lineFields):
        if len(self.loci) == 0:
            self.loci.append(locus(lineFields[0], lineFields[1], lineFields[3], lineFields[4], lineFields[6]))
            return
        foundOverlap = False
        newStart = int(lineFields[3])
        newEnd = int(lineFields[4])
        for l in self.loci:
            if l.start <= newEnd and l.end >= newStart: # overlap
                foundOverlap = True
                if newStart < l.start:
                    l.start = newStart
                if newEnd > l.end:
                    l.end = newEnd
                break
        if not foundOverlap: # new locus
            self.loci.append(locus(lineFields[0], lineFields[1], lineFields[3], lineFields[4], lineFields[6]))

geneDict = {}
for line in sys.stdin:
    fields = line.split("\t")
    attributes = fields[8].strip().split("; ")
    geneAttribute = attributes[0].split(" ") # assumes the gene attribute is in the first position
    geneID = geneAttribute[1].strip('"')
    if geneID in geneDict:
        geneDict[geneID].addLocus(fields)
    else:
        geneDict[geneID] = collapsedGene(geneID, fields)

for geneID, gene in geneDict.iteritems():
    for locus in gene.loci:
       print '{0}\t{1}\texon\t{2}\t{3}\t.\t{4}\t.\tgene_id "{5}"; transcript_id "{5}"; '.format(locus.seqname, locus.source, locus.start, locus.end, locus.strand, geneID)
