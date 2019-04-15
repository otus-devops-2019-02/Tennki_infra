#!/usr/bin/env python

import ConfigParser
import os
import time
import sys
import json
sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), 'lib'))
import googleapiclient.discovery
import warnings
warnings.filterwarnings("ignore", "Your application has authenticated using end user credentials")
#warnings.filterwarnings("ignore", "Failed to parse")
from six.moves import input


def list_instances(compute, project, zone):
    result = compute.instances().list(project=project, zone=zone).execute()
    return result['items'] if 'items' in result else None


if __name__ == '__main__':
    config = ConfigParser.ConfigParser()   
    # Get project id and zone frome ini-file.
    config.read("inventory.ini")  
    project = config.get('settings','project') 
    zone = config.get('settings','zone')        
    compute = googleapiclient.discovery.build('compute', 'v1')
    # Get instances info in current project.
    instances = list_instances(compute, project, zone)
    groups = {'app':[],'db':[]}
    app = 'app'
    db = 'db'
    app_group = []
    db_group = []
    tags = []
    out = {'_meta': {'hostvars': {}}}
    if instances is not None:
        for instance in instances:
            # instance name       
            name = instance['name']
            # instance external ip       
            ext_ip = instance['networkInterfaces'][0]['accessConfigs'][0]['natIP']
            # if find 'app' in instance name then add instance to app group
            if 'app' in name:
                app_group.append(name)
                groups['app'] = app_group
            # if find 'db' in instance name then add instance to db group    
            if 'db' in name:
                db_group.append(name)
                groups['db'] = db_group     
            tags = instance['tags']['items']            
            ansible_user = instance['metadata']['items'][0]['value'].split(':')[0]
            # render host vars
            out['_meta']['hostvars'][str(name)] = {
                'ansible_host': ext_ip,
                'ansible_user': ansible_user,
                'tags': tags
                }
    # render groups
        for group in groups:
            out[group] = {
            'hosts': groups[group]
        }
    else: 
        out = {'app': {'hosts': ['appserver']},'db': {'hosts': ['dbserver']}}
    print(json.dumps(out, indent=4, sort_keys=True))    




