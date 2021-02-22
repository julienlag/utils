# ~/Awk/overlap_better_all_and_i_info_refgff_inbed.awk
# takes a gff file of ORDERED feature A (chr, beg, end) in fileRef and acts on an input bed file of ORDERED feature B (chr, beg, end) 
# saying for each the feature B all the A features overlapping it and the intersection for each of them

#use: 
#awk -v toadd=ex -v fileRef=objectA.gff -f ~/Awk/overlap_better_all_and_i_info_refgff_inbed.awk objectB.bed

#example:
#

#
#

#
#

#
#


BEGIN{
  #store A objects
  while(getline < fileRef >0)
    {
      nbA[$1]++;
      begA[$1,nbA[$1]]=$4; 
      endA[$1,nbA[$1]]=$5;
    }
}



{ 
  #store B objects
  nbB[$1]++;
  begB[$1,nbB[$1]]=$2+1; #since bed format
  endB[$1,nbB[$1]]=$3;
  line[$1,nbB[$1]]=$0;
}


END{
  #For each B object ordered compute A objects overlapped by it
  for(c in nbB)
    {
      iA=1;
      for(iB=1; iB<=nbB[c]; iB++)
	{
	  s[c,iB]="";  #string with A objects overlapped by the current B object and with inter/union info
	  while((iA<=nbA[c])&&(endA[c,iA]<begB[c,iB]))   #while current A object is upstream of current B object, get next A objectr (ordered)
	    {
	      iA++;
	    }
	  firstiA=iA;   #remember first A object overlapped by current B object (to be used for next B object)
	  if((iA<=nbA[c])&&(begA[c,iA]<=endB[c,iB]))   #if current B object overlaps current A object
	    {
	      #here we want to get the first A object overlapped by the current B object
	      while((iA>=1)&&(foverlap(begA[c,iA],endA[c,iA],begB[c,iB],endB[c,iB])))
		{
		  iA--;
		}
	      iA++;   
	      # then we go over all the A objects and check wether they overlap the current B object 
	      # in such case we store them in s[c,iB] together with their i/u*100 value 
	      while((iA<=nbA[c])&&(begA[c,iA]<=endB[c,iB]))
		{
		    if(foverlap(begA[c,iA],endA[c,iA],begB[c,iB],endB[c,iB]))
		    {
			s[c,iB]=(s[c,iB])(c"_"(begA[c,iA])"_"(endA[c,iA])"_"(strA[c,iA]))":"((min(endA[c,iA],endB[c,iB])-max(begA[c,iA],begB[c,iB])+1))",";
			nbover[c,iB]++;
		    }
		  iA++;
		}
	      iA=firstiA;  #go back to first A object overlapped by current B object 
	    }  #end of if((iA<=nbA[c])&&(begA[c,iA]<=endB[c,iB]))
 
	  #We print for each B object it-self plus all the A objects overlapped by it as well as their associated i/u*100 info
	  if(s[c,iB]=="")
	    {
	      s[c,iB]=".";
	      nbover[c,iB]=0;
	    }
	  print (line[c,iB])"\tovlp_"(toadd)": "(s[c,iB])" nbovlp: "(nbover[c,iB]);

	}  #end of for(iB=1; iB<=nbB[c]; iB++)
    }  #end of for(c in nbB)
}  #end of END



function min(x,y){
  return x <= y ? x : y;
}

function max(x,y){
  return x >= y ? x : y;
}

function foverlap(beg1,end1,beg2,end2)
{
  return ((end1>=beg2)&&(beg1<=end2)) ? 1 : 0;
}


