# Callouts Design

This page documents the various callout designs used throughout the app. This is intended as a reference for verifying app functionality as we add in new features that may effect callouts. Callouts can have different structures based on the context of when/where they are called out. The documentation below denotes both the callout structure and the context in which that structure will be used.

## Notation

* `[Item]`: An item that will be replaced in the callout structure with the content described by the item name
* `{Sound}`: A sound that will be played (as opposed to TTS)
* `<content>(Bearing)`: Indicates that the content (items, sound, and/or static text) should be played in 3D at the specified bearing
* `[Item](Bearing)`: Indicates that the item should be played in 3D at the specified bearing
* `{Sound}(Bearing)`: Indicates that the sound should be played in 3D at the specified bearing

In examples, 🔊 represents the wav audio that should be played and the text represents TTS audio that should be played.

## Callout Types

### POI Callouts

#### Automatic Callouts

| Context | Callout Structure <br> (Example) |
| ------- | :----------------- |
| General | `<{Category Sound} [POI Name]>(POI bearing)` <br> |
| When inside the  POI | `<{Category Sound} at [POI Name]>(POI bearing)` <br> |
| Destination Callouts | Destination Callouts follow the same structure rules as the *Around Me & Ahead of Me* callouts (see next below) |
| BLE Beacon | Beacon callouts are the same as the *General* callout structure above |

#### Around Me & Ahead of Me

The callout structures below also apply for automatic destination update callouts.

Definitions:

* *d*: Rounded distance from the user to the POI
* *a*: GPS accuracy provided by Location Services
* *dist*: String representation of the rounded distance *d*

| Context | Callout Structure <br> (Example) |
| ------- | :----------------- |
| *d* ≤ 15m | `<{Category Sound} [POI Name], close by>(POI bearing)` <br> |
| *d* ≥ 200m | `<{Category Sound} [POI Name], [dist]>(POI bearing)` <br> |
| 15m < *d* < 200m <br> *a* ≤ +- 10m | `<{Category Sound} [POI Name], [dist]>(POI bearing)` <br> |
| 15m < *d* < 200m <br> *a* ≤ +- 20m | `<{Category Sound} [POI Name], about [dist]>(POI bearing)` <br> |
| 15m < *d* < 200m <br> *a* > +- 20m | `<{Category Sound} [POI Name], around [dist]>(POI bearing)` <br> |

#### Notes on Rounding Distances

For metric units, we round all distances less than 1000 meters to the nearest 5 meters and all distances over 1000 meters to the nearest 50 meters. For imperial units, we round all distances less than 1760 yards (1 mile) to the nearest 5 yards and all distances over 1760 yards to the nearest yard.

When rounded distances are converted to a string representation further rounding may occur. We express distances greater than 1 kilometer or mile in kilometers/miles to the nearest hundredth and distances less than 1 kilometer or mile in meters/yards without additional rounding (obviously corresponding to the users units of measure setting). For example, in metric units, a rounded distance of 1050 meters is converted to the string "1.05 kilometers" while a distance of 975 meters is converted to the string "975 meters". As another example, but in imperial units, a rounded distance of 2323 yards is converted to the string "1.32 miles" while a distance of 1255 yards is converted to the string "1255 yards".

### Intersection Callouts

Definitions:

* *User's Heading*: The current heading or bearing of the user (i.e. straight ahead of the user)
* *Road direction*: A string representing the direction a road travels in relative to the user (either "goes left," "goes right," or "continues ahead")
* *Road bearing*: The bearing relative to the *user's heading* that represents left, right, or ahead (e.g. if the user's heading is 0.0 degrees, then left is 270 degrees, ahead is 0 degrees, and right is 90 degrees)

| Context | Callout Structure <br> (Example) |
| ------- | :----------------- |
| General | `<{Place Category Sound} Approaching intersection.>(Users Heading)` <br> `<[Road name] [Road direction]>(Road Bearing)` <br> `<[Road name] [Road direction]>(Road Bearing)` <br> ... <br> `<[Road name] [Road direction]>(Road Bearing)` <br><br> From ahead: "🔊Approaching Intersection," <br> From the left: "NE 36th Street goes left," <br> From ahead: "148th Avenue NE continues ahead," <br> From the right: "NE 36th Street goes right" |

### Location Callouts

Location callouts occur in three different instances:

1. Manual: when the user presses the "My Location" button
2. Automatic (Location Sense): when the user moves from one semantically meaningful location to another (e.g. turns off one road and onto another)
3. Automatic (Intersection Departure): when the user is leaving an intersection

All three of these instances generate the same possible types of location callouts (they use the same underlying reverse geocoding infrastructure) described below.

Definitions:

* *Direction String*: A string indicating the direction a user is either facing or heading currently (e.g. if the user is holding their phone flat pointing north the string is "Facing North," but if they are walking eastward with the phone in their pocket the string is "Heading East").
* *User's Heading*: The current heading or bearing of the user (i.e. straight ahead of the user)

| Context | Callout Structure <br> (Example) |
| ------- | :----------------- |
| When inside a POI | `<{Location Sense} [Direction String]>(User's Heading), <at [POI Name]>(POI bearing)` <br> From ahead: "🔊Facing north" <br> |
| When outside near a road | `<{Location Sense} [Direction String] along [Road Name]>(User's Heading). <Intersection with [Intersecting Road Name] is [Rounded Intersection Distance] [Intersection Direction]>(Intersection bearing)` <br> |
| General | `<{Location Sense} [Direction String]>(User's Heading)` <br> `<Nearest road, [Road Name] is [Road Distance] [Road Direction]>(Road Bearing)` <br> `<[POI Name] is [Rounded POI Distance] [POI Direction]>(POI Bearing)` <br> * *Both the POI and Road parts are optional in this callout* <br> |
