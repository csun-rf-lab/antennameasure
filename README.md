# Hello!

This repository is a work in progress. It is not ready for general use. This notice will be removed when it is ready.

# Requirements

* MATLAB R2021a

# Committing from the lab computer

To commit from the lab computer (where this repository is checked out via HTTPS), you need to create a Personal Access Token to use as your password:
https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token

# TODO

* Ability to set axis velocities from job config and from motion controller app
* Tests for extractMeasurement... functions
* Add some controls to the VNA view
* Add support for 3 axes in measurements live view
* Add the ability to clear the cached axis names in the motion controller
* Originally the MI4190 and HP8720 classes were built with _Prologix extensions and it made sense at the time. However, since then things have changed and the separate classes no longer make sense. To clean up, the _Prologix classes should be integrated back into the core classes.
* There is still a nasty bug related to the log in MotionControllerApp. Try opening and closing it a few times in a row and you'll see what I mean.

# Longer-term TODO

* live camera feed
* live diagram of cuts/angles
* demo/instruction mode with dummy data (motioncontroller/vna)
* take reference antenna into account in final results
* aux gpio controls

# Compiling

* In matlab, `run applicationCompiler`.
* Pick "main file" to be `App.mlapp`.
* "Runtime downloaded from web" is fine. This means the MATLAB libraries will be downloaded from the internet when the application is installed.
* Rename the installer from the default "MyAppInstaller_web" to "AntennaMeasureInstaller".
* Fill in the application information:
** name: AntennaMeasure
** version: Pick a number higher than the current one installed, and use semantic versioning.
* "Files required for your application to run": Just select all of them in the repository.
* Click the "Package" button and select a place to save the installer.
* When the process completes, the `for_redistribution` folder will contain the installer executable.



# Useful links

* Prologix devices: http://prologix.biz/
* Camera: https://www.trendnet.com/store/products/surveillance-camera/indoor-outdoor-8mp-4k-uhd-h265-wdr-poe-ir-bullet-network-camera-TV-IP318PI#specifications

# General notes

* Apparently the MI4190 only supports moving one axis at once?! So while there is some code in here for moving all of the axes simultaneously, it's unused.
* Event handling in matlab is... weird. It would be nice to be able to emit events from the abstract MotionController and VNA classes, but apparently we're not allowed to do that. To get around it, I created event containers which are stored as properties on those abstract classes, and are then accessible on the final concrete classes that are used when the app runs. This lets us maintain the event handling behavior even if other classes [supporting additional measurement hardware] are added in the future.
