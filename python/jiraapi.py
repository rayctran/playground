import datetime
from datetime import timezone
import glob
import logging
import os
from jira import JIRA
import shutil
import sys
import subprocess
import zipfile
from utils import helpers
from utils import weather
import netrc


def connect(url, settings):
    # The following method only works for SERVICE account and jira version 2.0.0.
    username,other,password = netrc.netrc().hosts['projects.torc.tech']
    try:
        if settings['dev_j2']:
            jira_options = {
            'server': url,
            'verify': False
            }
            return JIRA(url, jira_options, basic_auth=(username, password))
        else:
            return JIRA(url, auth=(username, password))
    except:
        logging.getLogger('api').error('Failed to connect to Jira, have to exit....', exc_info=True)
        sys.exit()   

def getAttachments(j2,event_uid,settings):
    print(f"project = {settings['test_event_types'][settings['test_event_type']]['jira_project']} AND issuetype = Event AND summary ~ 'Event {event_uid}'")
    issues = j2.search_issues(f"project = {settings['test_event_types'][settings['test_event_type']]['jira_project']} AND issuetype = Event AND summary ~ 'Event {event_uid}'",maxResults=1)
    attachments = j2.search_issues(f"project = {settings['test_event_types'][settings['test_event_type']]['jira_project']} AND issuetype = Event AND summary ~ 'Event {event_uid}'",maxResults=1,fields="key, attachment")
    if len(issues) == 0:
        return (None,[])
    if 'fields' not in dir(issues[0]) or 'attachment' not in dir(attachments[0].fields):
        return (issues[0],[])

    # Try to remove all attachments if the event ticket has PIPELINE_ISSUE label. However, only those who uploaded the attachments can delete them.
    # Should only reprocess the necessary attachments in the future.
    if 'PIPELINE_ISSUE' in issues[0].fields.customfield_10306:
        settings['PIPELINE_ISSUE'] = True
        logging.getLogger('api').debug(f'This issue has been flagged as a pipeline issue...')
        for a in attachments[0].fields.attachment:
            try:
                j2.delete_attachment(a.id)
            except:
                logging.getLogger('api').debug(f"Do not have permission to delete attachment...")
        return (issues[0],[])
    return (issues[0],[a.filename for a in attachments[0].fields.attachment])

def resetLabel(issue,settings,commit_names,vehicle,health_monitor,deploy_dir):
    prev_dir = os.getcwd()
    os.chdir(os.path.expanduser(deploy_dir))

    eventLabelList = [vehicle]
    
    for commit_name in commit_names:
        eventLabelList.append(commit_name)
    if settings['TF_BAD']:
        eventLabelList.append("TF_BAD") # adds TF BAD Label

    if settings['NO_DATA']:
        eventLabelList.append("NO_DATA") # adds NO DATA Label
    
    # TODO: Dirty. Should not access list index directly
    try:
        for label in health_monitor[4]: # can add MRM, RKO
            eventLabelList.append(label)
    except:
        logging.getLogger('pipeline').debug(f'No MRM or RKO Labels.')
    
    issue.update(fields={'customfield_10306': eventLabelList})

    os.chdir(prev_dir)

def uploadAttachments(j2,issue,event_uid,event_id,attachments,settings):
    J2_FILESIZE_LIMIT = 10.0 # MB
    J2_FILESIZE_LIMIT_TXT = 25.0 # MB, this is only a temporary solution until S3 bucket is used.

    prev_dir = os.getcwd()
    os.chdir(os.path.expanduser(settings[event_uid][0]))
    uploads = glob.glob(f"event_{event_id}_*.png")
    uploads += glob.glob(f"hmv3_*_{event_uid}.txt")
    uploads.append(f"logstream_{event_uid}.scn.yaml") #Logstream
    uploads.append(f"rqt_{event_uid}.png")
    for name in settings['rviz']:
        uploads.append(f"rviz_{name['name']}_{event_uid}.mp4")
    # Semantic map visualization
    for name in settings['rviz_semantic']:
        uploads.append(f"rviz_{name['name']}_{event_uid}.mp4")
    for name in settings['localizer']:
        uploads.append(f"localizer_{name['name']}_{event_uid}.mp4")
    for upload in uploads:
        if os.path.isfile(upload) and upload not in attachments:
            upload_size = os.path.getsize(upload)
            if upload_size > 100:
                logging.getLogger('api').debug(f'Uploading {upload} to J2', extra={'event': event_uid})
                if helpers.bytesTo(upload_size, "M") >= J2_FILESIZE_LIMIT:
                    logging.getLogger('api').debug(f'Upload file size too large at {round(helpers.bytesTo(upload_size, "M"), 2)} MB', extra={'event': event_uid, 'upload': upload})
                    if upload.endswith('.mp4'):
                        ffmpeg_cmd = f"rm -rf tmp.mp4; ffmpeg -i {upload} -fs 7.5M -preset slow -c:v libx264 tmp.mp4 && mv tmp.mp4 {upload}"
                        res = subprocess.run(ffmpeg_cmd, shell=True, check=False, executable="/bin/bash")
                    else:
                        with zipfile.ZipFile(f"{upload}.zip", 'w') as myzip:
                            myzip.write(upload, os.path.basename(upload))
                        compressed_size = os.path.getsize(f"{upload}.zip")
                        if helpers.bytesTo(compressed_size, "M") >= J2_FILESIZE_LIMIT_TXT:
                            logging.getLogger('api').warning(f'Compressed file size too large at {round(helpers.bytesTo(compressed_size, "M"), 2)} MB for {upload}.zip, skipping', extra={'event': event_uid, 'upload': upload})
                            continue
                        else:
                            upload = f"{upload}.zip"
                try:
                    j2.add_attachment(issue=issue, attachment=upload)
                except Exception as e:
                    logging.getLogger('api').error(f'Upload to J2 failed with exception {e}.' , extra={'event': event_uid}, exc_info=True)
            else:
                logging.getLogger('api').warning(f'Upload file size too small at {upload_size} Bytes. Skipping upload {upload}.', extra={'event': event_uid, 'upload': upload})

        else:
            logging.getLogger('api').warning(f'Skipping upload {upload} because the file does not exist.', extra={'event': event_uid, 'upload': upload})
    os.chdir(prev_dir)

# The Custom field id's can be found by opening an event ticket that has the desired field visible, right click, select "view page source", and
# search in the opened page (ctrl+f and then type in the field name like "Event Reportable").
def createEvent(j2,settings,event_uid,timestamp,event_type,commit_names,vehicle,event_latitude,event_longitude,health_monitor,deploy_dir):
    prev_dir = os.getcwd()
    os.chdir(os.path.expanduser(deploy_dir))

    date = datetime.datetime.fromtimestamp(timestamp/1e6,tz=timezone.utc)
    #payload = { "fields": {"project": {"key": "APPS"},"summary": f"Event {event_uid}","customfield_10305": f"{event_date}","customfield_10304": f"{event_url}","reporter":{"name":"hill"},"description": f"Manual Note: {event_manual_note}\nType: {event_type}\nSet soft pause: {event_softpause}\nOther failures: {event_other}", "issuetype": {"name": "Event"} }, "update":{"issuelinks":[{"add":{"type":{"name":"Issue split","inward":"split from","outward":"split to"},"inwardIssue":{"key":"APPS-385"}}}]} }
    eventLabelList = [vehicle]
    swLabelList = []
    map_version_BCB = ''
    map_version_ABQ = ''

    # Get map version information in ./versions.yaml
    file = open("versions.yaml","r")
    lines = file.readlines()
    for i in range(len(lines)):
        if "map_blacksburg" in lines[i]:
            map_version_BCB = lines[i].strip('\n').replace(' ', '')

        if "map_southwest" in lines[i]:
            map_version_ABQ = lines[i].strip('\n').replace(' ', '')
    file.close()

    for commit_name in commit_names:
        eventLabelList.append(commit_name)
        swLabelList.append(commit_name)
    if settings['TF_BAD']:
        eventLabelList.append('TF_BAD')
    if settings['NO_DATA']:
        eventLabelList.append("NO_DATA") # adds NO DATA Label
    # TODO: Dirty. Should not access list index directly
    try:
        for label in health_monitor[4]: # can add MRM, RKO
            eventLabelList.append(label)
    except:
        logging.getLogger('pipeline').debug(f'No MRM or RKO Labels.')
    if settings['dev_j2']:
        # dev_j2 does not have map version fields yet
        issue_dict = {
            'project': {"key": settings['test_event_types'][settings['test_event_type']]['jira_project']},
            "issuetype": {"name": "Event"},
            'summary': f"Event {event_uid}",
            "customfield_10307": 0.0, # Event Review Time
            "customfield_10305": date.strftime('%Y-%m-%d'), # Event Date
            "customfield_10304": f"https://discovery.eng.torc.tech/event/{event_uid}", # Event URL
            'description': 'Creating this event but was not able to pull data from storageapi...',
            'customfield_10432': {'value': event_type}, # Event Type
            'customfield_10310': {'value': 'Unknown'}, # Event Legitimate Failure Default Value
            'customfield_10306': eventLabelList, # Event Label
            'customfield_10309': {'value': 'Unreviewed & Reportable'}, # New default reportability (after 09/29/2020)
            'customfield_10603': swLabelList, # New "Event Deployed SW Tag" Field
            'customfield_10425': f"{event_latitude}", # Latitude
            'customfield_10426': f"{event_longitude}", # Longitude
            'customfield_10427': f"http://osm.eng.torc.tech/#map=19/{event_latitude}/{event_longitude}" # JOSM Geographic Address 
            }
    else:
        issue_dict = {
            'project': {"key": settings['test_event_types'][settings['test_event_type']]['jira_project']},
            "issuetype": {"name": "Event"},
            'summary': f"Event {event_uid}",
            "customfield_10307": 0.0, # Event Review Time
            "customfield_10305": date.strftime('%Y-%m-%d'), # Event Date
            "customfield_10304": f"https://discovery.eng.torc.tech/event/{event_uid}", # Event URL
            'description': 'Creating this event but was not able to pull data from storageapi...',
            'customfield_10432': {'value': event_type}, # Event Type
            'customfield_10310': {'value': 'Unknown'}, # Event Legitimate Failure Default Value
            'customfield_10306': eventLabelList, # Event Label
            'customfield_11106': map_version_BCB, # BCB Map Version
            'customfield_11107': map_version_ABQ, # ABQ Map Version
            'customfield_10309': {'value': 'Unreviewed & Reportable'}, # New default reportability (after 09/29/2020)
            'customfield_10603': swLabelList, # New "Event Deployed SW Tag" Field
            'customfield_10425': f"{event_latitude}", # Latitude
            'customfield_10426': f"{event_longitude}", # Longitude
            'customfield_10427': f"http://osm.eng.torc.tech/#map=19/{event_latitude}/{event_longitude}" # JOSM Geographic Address 
            }
    

    #"issuelinks": [{"add":{"type":{"name":"Issue split","inward":"split from","outward":"split to"},"inwardIssue":{"key":"APPS-385"}}}]
    issue = j2.create_issue(fields=issue_dict)
    inward = j2.issue(settings['test_event_types'][settings['test_event_type']]['inward'])
    j2.create_issue_link("Issue split", inward, issue)
    os.chdir(prev_dir)
    return issue

#https://projects.torc.tech/rest/api/2/field
#{"id":"customfield_10432","name":"Event Type"}
#{"id":"customfield_10304","name":"Event URL"}
#{"id":"customfield_10309","name":"Event Reportable"}
#{"id":"customfield_10311","name":"Event Currently Mitigated"}
#{"id":"customfield_10310","name":"Event Legitimate Failure"}
#{"id":"customfield_10306","name":"Event Label"}

def updateDescription(issue,settings,event,health_monitor,vehicle,route):
    description  = (f"*Event ID (6 digit)*:     {event.id}\n"
                    f"*Test UID*:               {event.test_uid}\n"
                    f"*Manual Note*:            {event.note}\n"
                    f"*Disengagement Type*:     {event.type.name}\n"
                    f"*Disengagement ROS Time*: {event.timestamp}\n"
                    f"*Disengagement Time*:     {datetime.datetime.fromtimestamp(event.timestamp/1e6,tz=timezone.utc)}\n"
                    f"*Disengagement Reason*:   {event.reason}\n"
                    f"*Vehicle:*                {vehicle}\n"
                    f"*Route:*                  {route}\n"
                    f"*/hm_out*:                {health_monitor[0]}\n" # first_hm_msg
                    f"*/set_soft_pause*:        {health_monitor[1]}\n" # first_ssp_msg
                    f"*/unknown_errors*:        {health_monitor[2]}\n" # = see attachment
                    f"*/error_tracing*:         {health_monitor[3]}\n" # = see attachment
                    f"*Event Location*:         https://maps.google.com/?q={event.location['latitude']},{event.location['longitude']}\n" 
                    f"*Event Weather*:          {getWeatherDescription(settings,event)}\n"
                    f"*Legitimate Failure Reason*:          TBD....\n"
                    f"*Reportable Reason*:                  TBD....\n"
                    )
    issue.update(description=description)

def getWeatherDescription(settings,event):
    weather_resp = weather.getWeather(settings,event)
    weather_desc = "Unknown"
    if weather_resp.status_code == 200:
        try:
            rain = f"{weather_resp.json()['current']['rain']}"
        except:
            rain = "0"
        try:
            snow = f"{weather_resp.json()['current']['snow']}"
        except:
            snow = "0"
        try:
            wind = f"{weather_resp.json()['current']['wind_gust']}mph"
        except:
            wind = "None"
        try:
            weather_desc  = (f"{weather_resp.json()['current']['weather'][0]['main']} - {weather_resp.json()['current']['weather'][0]['description']}\n"
                        f"||Cloud Cover||Visibility||Temp||Wind||Rain||Snow||\n"
                        f"|{weather_resp.json()['current']['clouds']}%"
                        f"|{weather_resp.json()['current']['visibility']}m"
                        f"|{weather_resp.json()['current']['temp']}\N{DEGREE SIGN}F\n"
                        f"Feels Like: {weather_resp.json()['current']['feels_like']}\N{DEGREE SIGN}F\n"
                        f"Dew Point: {weather_resp.json()['current']['dew_point']}\N{DEGREE SIGN}F"
                        f"|{weather_resp.json()['current']['wind_speed']}mph @ {weather_resp.json()['current']['wind_deg']}\N{DEGREE SIGN}\n"
                        f"Gusts: {wind}"
                        f"|{rain}mm"
                        f"|{snow}mm|"
                        )
        except:
            weather_desc = "Unknown"
    else:
        logging.getLogger('pipeline').warning(f'Failed to retrieve weather data. Returned: {weather_resp.text}')
    return weather_desc
