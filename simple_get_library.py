#!/usr/bin/env python
'''GET an ENCODE antibody lot object'''

'''use requests to handle the HTTP connection'''
import requests
'''use json to convert between Python dictionaries and JSON objects'''
import json
import sys

'''store the ENCODE server address and an authorization keypair'''
'''create the keypair from persona or get one from your wrangler'''
SERVER = 'http://test.encodedcc.org'
AUTHID = '3WM54JEI'
AUTHPW = 'aaetc5tlz3rh4nve'

'''force return from the server in JSON format'''
HEADERS = {'content-type': 'application/json'}

def get_ENCODE(obj_id):
    '''GET an ENCODE object as JSON and return as dict'''
    url = SERVER+obj_id+'?limit=all'
    response = requests.get(url, auth=(AUTHID, AUTHPW), headers=HEADERS)
    if not response.status_code == requests.codes.ok:
        print >> sys.stderr, response.text
        response.raise_for_status()
    return response.json()

if __name__ == "__main__":

    '''GET the ENCODE object using it's resource name'''
    library = get_ENCODE('/libraries/')
    #antibody_lot = get_ENCODE('/antibody-lots/b40f24ee-8803-4937-9223-1df3a6bf3cd9')

    '''extract some fields from the ENCODE object'''
    print "accession:  %s" %(library['accession'])
    print "biosample:  %s" %(library['biosample']['biosample_term_name'])
    print "paired ended? %s" %(library['paired_ended'])
    print "lab ID: %s"    %(library['lab'])

    '''link through the lab object'''
    lab = get_ENCODE(library['lab'])
    print "lab name:   %s" %(lab['name'])
    print "lab city:   %s" %(lab['city'])
