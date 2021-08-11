# TODO

* Measurement results: check actualPos value in final measurement results
* Include axis names in measurement results
* JobRunner that gives progress updates and can be stopped.
* Try a simpler approach for the MotionController event handling
* VNA view while we're actively running the measurements.
* Cache axis names so it's not always a slow lookup
* Show the measurements as they happen (defaults for single axis/freq, dropdowns for more complex jobs)
* Originally the MI4190 and HP8720 classes were built with _Prologix extensions and it made sense at the time. However, since then things have changed and the separate classes no longer make sense. To clean up, the _Prologix classes should be integrated back into the core classes.
* There is still a nasty bug related to the log in MotionControllerApp. Try opening and closing it a few times in a row and you'll see what I mean.

# Longer-term TODO

* live camera feed
* live diagram of cuts/angles
* demo/instruction mode with dummy data (motioncontroller/vna)
* take reference antenna into account in final results
* aux gpio controls

# Useful links

* Prologix devices: http://prologix.biz/
* Camera: https://www.trendnet.com/store/products/surveillance-camera/indoor-outdoor-8mp-4k-uhd-h265-wdr-poe-ir-bullet-network-camera-TV-IP318PI#specifications

# General notes

* Apparently the MI4190 only supports moving one axis at once?! So while there is some code in here for moving all of the axes simultaneously, it's unused.
