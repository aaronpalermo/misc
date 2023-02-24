from boto3 import resource
from datetime import datetime
from dateutil.tz import gettz
from os import environ as env

##
# Credit to the source/inspiration: https://gist.github.com/gregarious-repo/b75eb8cb34e9b3644542c81fa7c7c23b
# Compare current time (HH:MM) to the value of 'ScheduleStop' or 'ScheduleStart'
# Value of the `ScheduleStop` or `ScheduleStart` must be in the following formats 'HH:MM' or 'HHMM' - example '09:00' or '21:32'
# 
# In order to trigger this function make sure to setup CloudWatch event which will be executed every minute. 
# Following Lambda Function needs a role with permission to start and stop EC2 instances and writhe to CloudWatch logs.
# 
# Example EC2 Instance tags: 
# 
# ScheduleStart : 06:00
# ScheduleStop  : 18:00
# ScheduleWeekend : True
##

#define boto3 the connection
ec2 = resource('ec2')

def lambda_handler(event, context):
    # get the current timezone from the timezone map function
    tz = tzmap()
    
    # Get current local time in format H:M
    current_time = datetime.now(tz).strftime("%H:%M")
    current_time2 = datetime.now(tz).strftime("%H%M")

    print(f"{datetime.now(tz)} Run started at ", current_time)
    
    # Find all the instances where any tag starts with "Schedule" 
    filters = [{ 'Name': 'tag-key', 'Values': ['Schedule*'] }]
    
    # Search all the instances which contains scheduled filter 
    print(f"{datetime.now(tz)} About to query instances")
    instances = list(ec2.instances.filter(Filters=filters))
    print(f"{datetime.now(tz)} Retrieved all instances tagged with Schedule*, that's a total of {len(instances)}")
    stopInstances = []   
    startInstances = []   

    # Locate all instances that are tagged to start or stop.
    print(f"{datetime.now(tz)} About to iterate through instances")
    for instance in instances:
        print(f'{datetime.now(tz)} processing instance id {instance.id} with tags {instance.tags}')
        # If it's a weekend and ScheduleWeekend = False, skip the instance
        if ({'Key':'ScheduleStop', 'Value':current_time} in instance.tags) or ({'Key':'ScheduleStop', 'Value':current_time2} in instance.tags):
            if (datetime.now(tz).weekday() > 4) and ({'Key':'ScheduleWeekend', 'Value':'True'} not in instance.tags):
                print(f"NOT stopping instance {instance.instance_id} since it's a weekend and ScheduleWeekend = True isn't present")
            else:
                stopInstances.append(instance.id)
        if ({'Key':'ScheduleStart', 'Value':current_time} in instance.tags) or ({'Key':'ScheduleStart', 'Value':current_time2} in instance.tags):
            if (datetime.now(tz).weekday() > 4) and ({'Key':'ScheduleWeekend', 'Value':'True'} not in instance.tags):
                print(f"NOT starting instance {instance.instance_id} since it's a weekend and ScheduleWeekend = True isn't present")
            else:
                startInstances.append(instance.id)               
    print(f"{datetime.now(tz)} Finished iterating through instances")
    
    # shut down all instances tagged to stop. 
    if len(stopInstances) > 0:
        # perform the shutdown
        print(f"{datetime.now(tz)} About to stop instances")
        stop = ec2.instances.filter(InstanceIds=stopInstances).stop()
        print(f"{datetime.now(tz)} Instances stopped:", stop)
    else:
        print(f"{datetime.now(tz)} No instances to shutdown.")

    # start instances tagged to stop. 
    if len(startInstances) > 0:
        # perform the start
        print(f"{datetime.now(tz)} About to start instances")
        start = ec2.instances.filter(InstanceIds=startInstances).start()
        print(f"{datetime.now(tz)} Starting instances: ", start)
        print(f"{datetime.now(tz)} Started instances")
    else:
        print(f"{datetime.now(tz)} No instances to start.")
        
def tzmap():
    tzdict= {
                "us-east-1"      : "US/Eastern",
                "us-east-2"      : "US/Eastern",
                "us-west-1"      : "US/Pacific",
                "us-west-2"      : "US/Pacific",
                "ap-south-1"     : "Asia/Kolkata",
                "ap-northeast-3" : "Asia/Tokyo",
                "ap-northeast-2" : "Asia/Seoul",
                "ap-southeast-1" : "Asia/Singapore",
                "ap-southeast-2" : "Australia/Sydney",
                "ap-northeast-1" : "Asia/Tokyo",
                "ca-central-1"   : "Canada/Central",
                "eu-central-1"   : "Europe/Berlin",
                "eu-west-1"      : "Europe/Dublin",
                "eu-west-2"      : "Europe/London",
                "eu-west-3"      : "Europe/Paris",
                "eu-north-1"     : "Europe/Stockholm",
                "sa-east-1"      : "America/Sao_Paulo"
            }
    tz = gettz(tzdict[env['AWS_REGION']])
    return(tz)
