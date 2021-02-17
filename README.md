# ReEnroller

Download: [ReEnroller](https://github.com/BIG-RAT/ReEnroller/releases/download/current/ReEnroller.zip)

Easily migrate a computer from one Jamf server to another.

![alt text](https://github.com/BIG-RAT/ReEnroller/blob/master/ReEnroller/help/images/ReEnroller.png "ReEnroller")


Use ReEnroller to build a package to take a macOS device enrolled in one Jamf server and enroll it into another.
* Ability to add (and then remove) a profile to the package.  This can help maintain a WiFi connection while migrating.
* Machine attempts to fail back to original server if enrollment in the new server fails.
* Specify the number of attempts and interval between attempts for enrolling in the new server.
* Can also be used for initial enrollments.
* Enroll into a specific site.
* Can automatically create a policy to verify enrollment in the new server.
* Select a policy to run after a successful enrollment.
* Deploy the package with policy or push it to an individual machine from within the app.

Important: 

* After enrolling in the new server the user must approve the MDM profile for macOS 10.13 and above.
* Big Sur and later that fail back to the source server will not automatically (re)install the MDM profile.

\* **Be sure to view the help (question mark in the lower right) for detailed usage instructions.**

Thanks @fauxserve for coming up with the idea and initial bash version.

## History
- 2021-02-14: Fixed issue that related to migrations from Jamf School.
 
- 2021-02-14: Code update/cleanup.  Removed option to push the package to a client from the App.  Added ability to mark the device as migrated on the source server by writing to either the Asset Tag, User Name, Phone, Position, or Room attribute.  If the migration fails the the device successfully fails back to the source server the attribute will indicate the failure.  Added the ability to control when the MDM profile is removed, if at all, during the re-enrollment process.


- 2020-11-19: Brought create seperate packages button back into view, minor logging additions.

- 2020-10-05: Added ability to migrate from Jamf School to Jamf Pro, ability to skip the health check that verifies the server is available, ability to call device enrollment (since installing profiles with the profiles command no longer works with Big Sur), modified apiMDM_ removal script for Big Sur.  Recon now runs with the endUsername flag.

- 20-07-27: Fixed device signature error that would occur when calling the remove mdm profile policy.

- 20-06-30: Cleaned up logging and added checks to see if backup files exist before attempting to delete them.

- 20-06-05: Added ability to use unsigned mobileconfig profiles (app no longer crashes).  Jamf Pro URL and user are now saved between launches.  Added ability to enroll using an unsecure (http) URL, provided the server is configured to allow this.

- 20-03-20: Fixed issue where the sites button would not populate.
  
- 20-02-14: Additional logging, including the version of the app. UI updates to include removal of xml tags in alerts. Modified process of downloading the jamf binary from the destination server.

- 19-11-14: Fixed issue that prevented the re-enrollment process from working if the ReEnroller app was on the machine prior to running the package.
