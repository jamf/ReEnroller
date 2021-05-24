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
    <name>Jamf School Unenroll</name>
    <priority>9</priority>
</category>
"""
    static var script   = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<script>
    <name>Jamf School Unenroll</name>
    <category>Jamf School Unenroll</category>
    <filename>Jamf School Unenroll</filename>
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
curl -s "$jamfSchoolServer/api/devices/${udid}/unenroll" -H "Authorization: Basic ${token}" -H "Content-Type: application/data-urlencoded; charset=utf-8" -X POST</script_contents>
</script>
"""
    static var policy   = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<policy>
    <general>
        <name>Jamf School Unenroll</name>
        <enabled>true</enabled>
        <trigger>EVENT</trigger>
        <trigger_checkin>false</trigger_checkin>
        <trigger_enrollment_complete>false</trigger_enrollment_complete>
        <trigger_login>false</trigger_login>
        <trigger_logout>false</trigger_logout>
        <trigger_network_state_changed>false</trigger_network_state_changed>
        <trigger_startup>false</trigger_startup>
        <trigger_other>jamfSchoolUnenroll</trigger_other>
        <frequency>Ongoing</frequency>
        <location_user_only>false</location_user_only>
        <target_drive>/</target_drive>
        <offline>false</offline>
        <category>
            <name>Jamf School Unenroll</name>
        </category>
        <date_time_limitations>
            <activation_date></activation_date>
            <activation_date_epoch>0</activation_date_epoch>
            <activation_date_utc></activation_date_utc>
            <expiration_date></expiration_date>
            <expiration_date_epoch>0</expiration_date_epoch>
            <expiration_date_utc></expiration_date_utc>
            <no_execute_on></no_execute_on>
            <no_execute_start></no_execute_start>
            <no_execute_end></no_execute_end>
        </date_time_limitations>
        <network_limitations>
            <minimum_network_connection>No Minimum</minimum_network_connection>
            <any_ip_address>true</any_ip_address>
            <network_segments></network_segments>
        </network_limitations>
        <override_default_settings>
            <target_drive>default</target_drive>
            <distribution_point></distribution_point>
            <force_afp_smb>false</force_afp_smb>
            <sus>default</sus>
            <netboot_server>current</netboot_server>
        </override_default_settings>
        <network_requirements>Any</network_requirements>
        <site>
            <name>None</name>
        </site>
    </general>
    <scope>
        <all_computers>true</all_computers>
        <computers></computers>
        <computer_groups></computer_groups>
        <buildings></buildings>
        <departments></departments>
        <limitations>
            <users></users>
            <user_groups></user_groups>
            <network_segments></network_segments>
            <ibeacons></ibeacons>
        </limitations>
        <exclusions>
            <computers></computers>
            <computer_groups></computer_groups>
            <buildings></buildings>
            <departments></departments>
            <users></users>
            <user_groups></user_groups>
            <network_segments></network_segments>
            <ibeacons></ibeacons>
        </exclusions>
    </scope>
    <self_service>
        <use_for_self_service>false</use_for_self_service>
        <self_service_display_name></self_service_display_name>
        <install_button_text>Install</install_button_text>
        <reinstall_button_text>Reinstall</reinstall_button_text>
        <self_service_description></self_service_description>
        <force_users_to_view_description>false</force_users_to_view_description>
        <self_service_icon></self_service_icon>
        <feature_on_main_page>false</feature_on_main_page>
        <self_service_categories></self_service_categories>
        <notification>false</notification>
        <notification>Self Service</notification>
        <notification_subject>Jamf School Unenroll</notification_subject>
        <notification_message></notification_message>
    </self_service>
    <package_configuration>
        <packages>
            <size>0</size>
        </packages>
    </package_configuration>
    <scripts>
        <size>1</size>
        <script>
            <name>Jamf School Unenroll</name>
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
    <printers>
        <size>0</size>
        <leave_existing_default></leave_existing_default>
    </printers>
    <dock_items>
        <size>0</size>
    </dock_items>
    <account_maintenance>
        <accounts>
            <size>0</size>
        </accounts>
        <directory_bindings>
            <size>0</size>
        </directory_bindings>
        <management_account>
            <action>doNotChange</action>
        </management_account>
        <open_firmware_efi_password>
            <of_mode>none</of_mode>
            <of_password_sha256 since="9.23">e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855</of_password_sha256>
        </open_firmware_efi_password>
    </account_maintenance>
    <reboot>
        <message>This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu.</message>
        <startup_disk>Current Startup Disk</startup_disk>
        <specify_startup></specify_startup>
        <no_user_logged_in>Do not restart</no_user_logged_in>
        <user_logged_in>Do not restart</user_logged_in>
        <minutes_until_reboot>5</minutes_until_reboot>
        <start_reboot_timer_immediately>false</start_reboot_timer_immediately>
        <file_vault_2_reboot>false</file_vault_2_reboot>
    </reboot>
    <maintenance>
        <recon>false</recon>
        <reset_name>false</reset_name>
        <install_all_cached_packages>false</install_all_cached_packages>
        <heal>false</heal>
        <prebindings>false</prebindings>
        <permissions>false</permissions>
        <byhost>false</byhost>
        <system_cache>false</system_cache>
        <user_cache>false</user_cache>
        <verify>false</verify>
    </maintenance>
    <files_processes>
        <search_by_path></search_by_path>
        <delete_file>false</delete_file>
        <locate_file></locate_file>
        <update_locate_database>false</update_locate_database>
        <spotlight_search></spotlight_search>
        <search_for_process></search_for_process>
        <kill_process>false</kill_process>
        <run_command></run_command>
    </files_processes>
    <user_interaction>
        <message_start></message_start>
        <allow_users_to_defer>false</allow_users_to_defer>
        <allow_deferral_until_utc></allow_deferral_until_utc>
        <allow_deferral_minutes>0</allow_deferral_minutes>
        <message_finish></message_finish>
    </user_interaction>
    <disk_encryption>
        <action>none</action>
    </disk_encryption>
</policy>
"""
}

struct Xml {
    static var objectDict  = [String:String]()
    static var objectArray = [String]()
}
