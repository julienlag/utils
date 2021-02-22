#!/bin/awk

{
		if (substr($6,length($6),1)=="S") {
			split($6,A,/[DIMNS]/);
			L=A[length(A)-1];
			Seq=substr($10,length($10)-L+1,L);
			nA=gsub("A","A",Seq);
			if (nA/length(Seq)>=0.9) {
				print $3,$8-$9,"+",L,nA;
			}





		}
		L=substr($6,1,index($6,"S")-1);
		if ( L==L+0 && L>0 ) {
			Seq=substr($10,1,L);
			nA=gsub("T","T",Seq);
			if (nA/length(Seq)>=0.9) {
				print $3,$4-1,"-",L,nA;
			}
		}
	}

}
