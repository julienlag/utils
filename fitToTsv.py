#!/usr/bin/env python 
from __future__ import division
from __future__ import print_function
import datetime, time
import sys
from fitparse import FitFile

fitfile = FitFile(sys.argv[1])
garmin_epoch=631065600
sport=None
filetype=None
timestamp_offset=None
local_time_difference=datetime.timedelta()
# Get all data messages

for record in fitfile.get_messages():
#    print("\nname:", record.name)
    # if record.name == 'unknown_6':
    #     continue
    if record.get_value('timestamp') is not None and record.get_value('local_timestamp') is not None:
        local_time_difference=record.get_value('local_timestamp') - record.get_value('timestamp')
    if record.name == 'device_settings':
        local_time_difference=datetime.timedelta(seconds=record.get_value('time_offset'))
    #https://stackoverflow.com/questions/57774180/how-to-handle-timestamp-16-in-garmin-devices
    if record.get_value('timestamp') is not None:
        timestamp_offset=record.get_value('timestamp') + local_time_difference
#    print (timestamp_offset)
#        print ("Time diff:", local_time_difference)
    if record.name == 'file_id':
        filetype=record.get_value('type')
    elif record.name == 'sport':
        sport=record.get_value('sport')
#    print ("\ndict\n",record.as_dict())
#    print ("Type:", filetype)
#    print ("Sport:", sport)
#    print ("\nvalues:\n", record.get_values())
    if record.name == 'monitoring' or record.name == 'length' or record.name == 'record':
        lat=None
        long=None
        if record.get_value('position_lat') is not None:
            lat= record.get_value('position_lat') * (180 / 2 ** 31)
        if record.get_value('position_long') is not None:
            long= record.get_value('position_long') * (180 / 2 ** 31)
        timestamp=None
        if record.get_value('timestamp') is not None:
            timestamp=record.get_value('timestamp') + local_time_difference
        elif record.get_value('timestamp_16') is not None:
          #  print("timestamp_16")
         #   print("timestamp_offset:", timestamp_offset)
            # https://stackoverflow.com/questions/57774180/how-to-handle-timestamp-16-in-garmin-devices
            tstamp = int(timestamp_offset.strftime('%s')) - garmin_epoch
            timestamp = tstamp
            timestamp += ( record.get_value('timestamp_16') - ( timestamp & 0xFFFF ) ) & 0xFFFF
            timestamp= datetime.datetime.fromtimestamp(timestamp + garmin_epoch)
        #print("Timestamp:", timestamp)
        print(filetype, sport, record.name, timestamp, record.get_value('heart_rate'), lat, long, record.get_value('enhanced_altitude'), record.get_value('enhanced_speed'), record.get_value('steps'), record.get_value('distance'), record.get_value('activity_type'), record.get_value('total_strokes'), record.get_value('avg_speed'), record.get_value('message_index'), record.get_value('total_timer_time'), record.get_value('active_time'),sep='\t')

    



# name: file_id
#    type: activity, monitoring_b
# name: sport
#    sport: running,
# record:
#    distance, heart_rate, timestamp, enhanced_altitude, position_lat, position_long, enhanced_speed, 
# session:
#    start_time, max_heart_rate, avg_heart_rate, sport, total_calories, total_elapsed_time, total_distance, enhanced_max_speed, enhanced_avg_speed