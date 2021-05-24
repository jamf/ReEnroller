//
//  ObjectXML.swift
//  ReEnroller
//
//  Created by Leslie Helou on 2/15/21
//

import Foundation

struct JamfPro {
    static var migrationCheckPolicy = """
<?xml version="1.0" encoding="UTF-8"?>
<policy>
    <general>
        <name>Migration Complete v4</name>
        <enabled>true</enabled>
        <trigger>EVENT</trigger>
        <trigger_checkin>false</trigger_checkin>
        <trigger_enrollment_complete>false</trigger_enrollment_complete>
        <trigger_login>false</trigger_login>
        <trigger_logout>false</trigger_logout>
        <trigger_network_state_changed>false</trigger_network_state_changed>
        <trigger_startup>false</trigger_startup>
        <trigger_other>jpsmigrationcheck</trigger_other>
        <frequency>Ongoing</frequency>
        <location_user_only>false</location_user_only>
        <target_drive>/</target_drive>
        <offline>false</offline>
        <network_requirements>Any</network_requirements>
        <site>
            <name>None</name>
        </site>
    </general>
    <scope>
        <all_computers>true</all_computers>
    </scope>
    <files_processes>
        <run_command>touch /Library/Application\\ Support/JAMF/ReEnroller/Complete</run_command>
    </files_processes>
</policy>
"""
}

struct JamfSchool {
    static var catagory = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<category>
    <name>Migration Unenroll</name>
    <priority>9</priority>
</category>
"""
    static var script   = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<script>
    <name>Migration Unenroll</name>
    <category>Migration Unenroll</category>
    <filename>Migration Unenroll</filename>
    <info></info>
    <notes></notes>
    <priority>Before</priority>
    <parameters>
        <parameter4>Jamf School URL</parameter4>
        <parameter5>Jamf School authentication token</parameter5>
        <parameter6>.</parameter6>
        <parameter7>.</parameter7>
        <parameter8>.</parameter8>
        <parameter9>.</parameter9>
        <parameter10>.</parameter10>
        <parameter11>.</parameter11>
    </parameters>
    <os_requirements></os_requirements>
    <script_contents>#!/bin/sh

if [ "$4" = "" ];then
    echo "missing Jamf School URL - exiting"
    exit 1
else
    jamfSchoolServer="$4"
fi
if [ "${5}" = "" ];then
    echo "missing Jamf School authentication token - exiting"
    exit 1
else
    token="${5}"
fi

udid=$(ioreg -rd1 -c IOPlatformExpertDevice | awk '/UUID/ { print $3 }' | sed -e 's/"//g')
echo "unmanage machine: /usr/bin/curl -s \"$jamfSchoolServer/api/devices/${udid}/unenroll\" -H \"Authorization: Basic ---------------\" -H \"Content-Type: application/data-urlencoded; charset=utf-8\" -X POST"
/usr/bin/curl -s "$jamfSchoolServer/api/devices/${udid}/unenroll" -H "Authorization: Basic ${token}" -H "Content-Type: application/data-urlencoded; charset=utf-8" -X POST</script_contents>
</script>
"""
    static var policy   = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<policy>
    <general>
        <name>Migration Unenroll</name>
        <enabled>true</enabled>
        <trigger>EVENT</trigger>
        <trigger_other>sourceMdmUnenroll</trigger_other>
        <frequency>Ongoing</frequency>
        <category>
            <name>Migration Unenroll</name>
        </category>
    </general>
    <scope>
        <all_computers>true</all_computers>
    </scope>
    <scripts>
        <size>1</size>
        <script>
            <name>Migration Unenroll</name>
            <priority>Before</priority>
            <parameter4>----jamfSchoolUrl----</parameter4>
            <parameter5>---jamfSchoolToken---</parameter5>
            <parameter6></parameter6>
            <parameter7></parameter7>
            <parameter8></parameter8>
            <parameter9></parameter9>
            <parameter10></parameter10>
            <parameter11></parameter11>
        </script>
    </scripts>
</policy>
"""
}

struct WS1 {
    static var catagory = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<category>
    <name>Migration Unenroll</name>
    <priority>9</priority>
</category>
"""
    static var script   = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<script>
    <name>Migration Unenroll</name>
    <category>Migration Unenroll</category>
    <filename>Migration Unenroll</filename>
    <info></info>
    <notes></notes>
    <priority>Before</priority>
    <parameters>
        <parameter4>Workspace ONE URL</parameter4>
        <parameter5>Workspace ONE tenant code</parameter5>
        <parameter6>Workspace ONE authentication token</parameter6>
        <parameter7>.</parameter7>
        <parameter8>.</parameter8>
        <parameter9>.</parameter9>
        <parameter10>.</parameter10>
        <parameter11>.</parameter11>
    </parameters>
    <os_requirements></os_requirements>
    <script_contents>#!/bin/sh

if [ "$4" = "" ];then
    echo "missing Workspace ONE URL - exiting"
    exit 1
else
    ws1Server="$4"
fi
if [ "${5}" = "" ];then
    echo "missing Workspace ONE tenant code - exiting"
    exit 1
else
    tenantCode="${5}"
fi
if [ "${6}" = "" ];then
    echo "missing Workspace ONE authentication token - exiting"
    exit 1
else
    token="${6}"
fi

serialNumber=$(ioreg -l | grep IOPlatformSerialNumber | awk '{ print $4 }' | sed 's/"//g')
echo "unmanage machine: /usr/bin/curl -X POST -s $ws1Server/api/mdm/devices/commands?command=EnterpriseWipe&amp;searchBy=Serialnumber&amp;id=$serialNumber"
result=$(/usr/bin/curl -X POST -s "$ws1Server/api/mdm/devices/commands?command=EnterpriseWipe&amp;searchBy=Serialnumber&amp;id=$serialNumber" \\
    --header "accept: application/json;version=1" \\
    --header "authorization: Basic ${token}" \\
    --header "aw-tenant-code: ${tenantCode}" \\
    --header "content-type: application/json" \\
    --data "")
    
if [ "$result" = "" ];then
    /Library/Scripts/hubuninstaller.sh
else
    echo "$result"
fi</script_contents>
</script>
"""
    static var policy   = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<policy>
    <general>
        <name>Migration Unenroll</name>
        <enabled>true</enabled>
        <trigger>EVENT</trigger>
        <trigger_other>sourceMdmUnenroll</trigger_other>
        <frequency>Ongoing</frequency>
        <target_drive>/</target_drive>
        <category>
            <name>Migration Unenroll</name>
        </category>
    </general>
    <scope>
        <all_computers>true</all_computers>
    </scope>
    <scripts>
        <size>1</size>
        <script>
            <name>Migration Unenroll</name>
            <priority>Before</priority>
            <parameter4>----WS1Url----</parameter4>
            <parameter5>---WS1Tenant---</parameter5>
            <parameter6>----WS1Token----</parameter6>
            <parameter7></parameter7>
            <parameter8></parameter8>
            <parameter9></parameter9>
            <parameter10></parameter10>
            <parameter11></parameter11>
        </script>
    </scripts>
</policy>
"""
}

struct Xml {
    static var objectDict  = [String:String]()
    static var objectArray = [String]()
}
