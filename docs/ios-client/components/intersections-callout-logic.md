# Intersections Callout Logic

This document describes the app’s logic regarding the handling of intersections.

We currently have three ways of hearing information about nearby intersections:

* **Automatic Callouts** - Automatically invoked when the user is in motion.
* **Where Am I?** - Automatically invoked when the user turns on the _Where Am I?_ sense.
* **Locate** - Invoked when a user presses the _Locate_ button.

## Automatic Callouts

Upon a new location update, we first determine if the location update filter allows us to process the new location. This is in place in order to throttle the frequency of computation initiated by the location updates.

We check if the user has moved more than **5 meters** and if at least **5 seconds** have passed.

Additional parameters to block the next intersection detection:

* If intersection sense is not turned on in app settings
* If a user’s activity is **Driving**
* If a user’s speed is more than **5 meters per second**
* If we haven’t received nearby spatial data

When a valid location update arrives and the above conditions pass, we filter the relevant intersection by these parameters:

* Maximum distance is **25 meters**
* Maximum travel direction angle is **60 degrees** (see [Travel Direction Angle](#travel-direction-angle))
* The same intersection has not been callout in the last **30 seconds**
* If we are not in proximity of the last called out intersection (the same intersection is found in the results of these filter, i.e. we are near it and traveling towards it)

From these results, we select the closest one, and call it out.

## Where Am I? / Locate

These are similar, but one is invoked automatically and one is invoked by the user pressing a button.

These are also logically similar to the _Automatic Callouts_, but with a few changes:

* We **do not** check if the intersection sense is turned on in app settings
* We **do not** check if a user’s activity is **Driving**
* We **do not** check if a user’s speed is more than **5 meters per second**

We add these additional checks:

* If a user is not inside a building
* If we found a road near the user
* If we are closer than **20 meters** to the road
* The road we are on is one of the roads the intersection intersects
* Maximum distance is **500 meters**
* Maximum travel direction angle is **90 degrees**

## Detecting Intersection Departure

We detect an intersection departure be these parameters:

* A user has left the proximity of the intersection (**15 meters**).
* A user is not traveling towards the intersection. Meaning the intersection is not within the maximum travel direction angle of **180 degrees**.

## Travel Direction Angle

In order to detect intersections that are in the direction the user is traveling, we calculate the bearing to the intersection, and use the user’s course to check if he is traveling towards the intersection. Also, we allow for an offset (_maximum travel direction angle_) to account for some user drift.

Example:

If the bearing from the user’s location to the intersection is 80° and the allowed offset is 40°, the allowed range that the user’s course should be in is between 60° and 100° (80°±20°).

We currently calculate this only in regards to the user’s course (not heading), found in the device’s location updates.
