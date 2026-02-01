# ReEnroller

![GitHub release (latest by date)](https://img.shields.io/github/v/release/BIG-RAT/ReEnroller?display_name=tag) ![GitHub all releases](https://img.shields.io/github/downloads/BIG-RAT/ReEnroller/total) ![GitHub latest release](https://img.shields.io/github/downloads/BIG-RAT/ReEnroller/latest/total)
 ![GitHub issues](https://img.shields.io/github/issues-raw/BIG-RAT/ReEnroller) ![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/BIG-RAT/ReEnroller) ![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/BIG-RAT/ReEnroller) ![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/BIG-RAT/ReEnroller)

Download: [ReEnroller](https://github.com/BIG-RAT/ReEnroller/releases/latest/download/ReEnroller.zip)

Easily migrate a computer from one Jamf Pro server to another.

By default the application sends anonymous data to [TelemetryDeck](https://telemetrydeck.com). This data is used to aid in development of the app. To opt out of sending data select 'Opt out of analytics' during package creation.

![alt text](https://github.com/BIG-RAT/ReEnroller/blob/master/ReEnroller/help/images/ReEnroller.png "ReEnroller")


Use ReEnroller to build a package to take a macOS device enrolled in one Jamf Pro server and enroll it into another.
* Ability to add (and then remove) a wifi profile to the package.  This can help maintain a WiFi connection while migrating.
* Machine attempts to fail back to original server if enrollment in the new server fails.
* Specify the number of attempts and interval between attempts for enrolling in the new server.
* Can also be used for initial enrollments.
* Enroll into a specific site.
* Can automatically create a policy to verify enrollment in the new server.
* Select a policy to run after a successful enrollment.

Important: 

* apiMDM_removal script requires an API client to run.
* When deploying to machines running macOS 13+ be sure to deploy ReEnrollerNotifications.mobileconfig before the package.
* After enrolling in the new server the user must approve the MDM profile for macOS 10.13 and above.
* Big Sur and later that fail back to the source server will not automatically (re)install the MDM profile.
* Application submits anonamous data to [TelemetryDeck](https://telemetrydeck.com) by default. Select 'Opt out of analytics' to disable sending data.

\* **Be sure to view the help (question mark in the lower right) for detailed usage instructions.**

Thanks @fauxserve for coming up with the idea and initial bash version.