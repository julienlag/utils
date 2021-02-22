#!/usr/bin/env python
#import os
import sys
#import csv
import json
import jsonschema
#import requests
#from pyelasticsearch import ElasticSearch
#import xlrd
#import xlwt
#from base64 import b64encode



# read json objects from file
def ReadJSON(json_file):
    json_load = open(json_file)
    json_read = json.load(json_load)
    json_load.close()
    return json_read

# check json object for validity. SHOULD ONLY NEED OBJECT. NEED DEF TO EXTRACT VALUE (LIKE TYPE) FROM JSON OBJECT GRACEFULLY.
def ValidJSON(new_object,object_schema):
    #get the relevant schema
    #object_schema = get_ENCODE(('/profiles/' + object_type + '.json'))
            
    # test the new object. SHOULD HANDLE ERRORS GRACEFULLY
    try:
        jsonschema.validate(new_object,object_schema)
    # did not validate
    except Exception as e:
        print('Validation failed.')
        print(e)
        return False

    # did validate
    else:
        # inform the user of the success
        print('Validation succeeded.')
        return True




jsonSchemaFile=sys.argv[1]
jsonFile=sys.argv[2]
jsonObj=ReadJSON(jsonFile)
jsonSch=ReadJSON(jsonSchemaFile)
ValidJSON(jsonObj,jsonSch)
