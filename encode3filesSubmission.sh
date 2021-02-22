#!/bin/bash
#set -e
export PATH="/users/rg/jlagarde/julien_utils/:$PATH"
failedUploads=0;
totalEntries=0;
failedRegistrations=0;
withoutJson=0;
for file in `cat $2 |skipcomments`; do
	let "totalEntries++";
 	if [ -e "$file.json" ]; then
echoerr $file.json
	let "withJson++"
 #processEncode3DccJsonObject.pl http://test.encodedcc.org/files POST $file.json
echoerr " Registering"
  processEncode3DccJsonObject.pl $1 POST $file.json
  if [ $? -ne 0 ]; then
  	echoerr "Skipping to next entry";
  	let "failedRegistrations++"
  	continue;
  fi

echoerr " Submitting"
 submitToAwsDcc.pl $file.json.postResponse.json
 if [ $? -ne 0 ]; then
  	echoerr "Skipping to next entry";
  	let "failedUploads++"
  	continue;
  fi
else
	echoerr "##### No json file available for $file. NOT SUBMITTED. #####"
	let "withoutJson++"
fi
done

echo -e "

\t## SUMMARY OF SUBMISSION
\t\ttotal entries in input:\t$totalEntries
\tERRORS:
\t\t\tJSON not found:\t$withoutJson
\t\t\tJSON found, but failed registrations:\t$failedRegistrations
\t\t\tJSON found, successful registration, but failed upload:\t$failedUploads
## END OF SUMMARY OF SUBMISSION
" >&2

