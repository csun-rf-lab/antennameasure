# TODO

* Test the method for moving multiple axes at once.
* Measurement results: Include real positions as separate vector in the results (alongside the ideal ones)
* VNA view while we're actively running the measurements.
* JobRunner that gives progress updates and can be stopped.
* Cache axis names so it's not always a slow lookup
* Show the measurements as they happen (defaults for single axis/freq, dropdowns for more complex jobs)
* Originally the MI4190 and HP8720 classes were built with _Prologix extensions and it made sense at the time. However, since then things have changed and the separate classes no longer make sense. To clean up, the _Prologix classes should be integrated back into the core classes.
* There is still a nasty bug related to the log in MotionControllerApp. Try opening and closing it a few times in a row and you'll see what I mean.


# Useful links

* Prologix devices: http://prologix.biz/
* Camera: https://www.trendnet.com/store/products/surveillance-camera/indoor-outdoor-8mp-4k-uhd-h265-wdr-poe-ir-bullet-network-camera-TV-IP318PI#specifications
