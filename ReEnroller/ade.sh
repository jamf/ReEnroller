#!/bin/bash

/bin/launchctl asuser $(id -u "$(stat -f%Su /dev/console)") /usr/bin/profiles renew -type enrollment

