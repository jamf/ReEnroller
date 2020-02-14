# ReEnroller

Download: [ReEnroller](https://github.com/BIG-RAT/ReEnroller/releases/download/current/ReEnroller.zip)

Easily migrate a computer from one Jamf server to another.

![alt text](https://github.com/BIG-RAT/ReEnroller/blob/master/ReEnroller/images/ReEnroller.png "ReEnroller")


Use ReEnroller to build a package to take a macOS device enrolled in one Jamf server and enroll it into another.
* Ability to add (and then remove) a profile to the package.  This can help maintain a WiFi connection while migrating.
* Machine attempts to fail back to original server if enrollment in the new server fails.
* Specify the number of attempts and interval between attempts for enrolling in the new server.
* Can also be used for initial enrollments.
* Enroll into a specific site.
* Can automatically create a policy to verify enrollment in the new server.
* Select a policy to run after a successful enrollment.
* Deploy the package with policy or push it to an individual machine from within the app.

Important: After enrolling in the new server the user must approve the MDM profile for macOS 10.13 and above.<p>

**Be sure to view the help for detailed usage instructions.

Thanks @fauxserve for coming up with the idea and initial bash version.

## History
- 20-02-14: Additional logging, including the version of the app. UI updates to include removal of xml tags in alerts. Modified process of download the jamf binary from the destination server.

- 19-11-14: Fixed issue that prevented the re-enrollment process from working if the ReEnroller app was on the machine prior to running the package.
