# Reverse Geocoder Design

A traditional reverse geocoder takes a latitude and longitude coordinate and returns the street address of that coordinate. Within the context of Soundscape, we have the reverse geocoder return a more rich description of where the user is since the user is not always on a street and when on a street, the particular address they are standing at may not be very useful. Our `ReverseGeocoderContext` classifies a user's location into one of four possible types of locations:

1. **Unknown:** We don't have geolocation information from iOS, so we don't know where the user is.
2. **Inside a POI:** The user's location is within the boundary of a POI's polygon. Most often this means that a user is indoors, but it could also mean they are within a space like a park, a public square, etc.
3. **Alongside a Road:** The user's location is within 20 meters of a road.
4. **Other:* The user's location is neither inside a POI or alongside a road.

The `ReverseGeocoderContext` updates it's description of the user's location every 15 seconds or every 10 meters the user moves (note that the 15 seconds and 10 meters are not exact as the `ReverseGeocoderContext` only checks if it should update when it receives a location from the `GeolocationContext`). This limitation in the frequency of updates is to ensure that we are not wasting expensive update operations (each update requires finding the closest point on all nearby roads in order to find the nearest road - this is an expensive operation). When an updated location is received from the `GeolocationContext`, the `ReverseGeocoderContext` takes several steps:

1. Check if enough time has passed from the previous update or if the user has moved far enough away from the previous update location. If so, continue.
2. Check if the user is **inside a POI**. If so, store the POI's name for location sense callouts. If not, continue.
3. Try to find the nearest POI and the nearest road. If the user was previously on a road and they are still within 20 meters of that road, then ignore all other roads for this update (e.g. stick to the previous road).
4. If a road was found and the user is within 20 meters of it, try and find the closest intersection in the direction the user is facing.
5. Check if we need to perform an automatic callout for the user's location (e.g. perform location sense if the name of the nearest road or POI has changed and the user has the "Where Am I?" automatic callout setting turned on).

Location sense has 4 possible callouts based on the four types of user locations described above. Here is how their callouts are structured (italic text indicates the direction the callout comes from and bracketed items indicate values that are filled in based on the user's current location):

* **Unknown:**

* *(From ahead)* You are `[facing/heading]` `[cardinal direction]`.

* **Inside a POI:**

* *(From ahead)* You are `[facing/heading]` `[cardinal direction]` at `[POI name]`.

* **Alongside a Road:**

* *(From ahead)* You are `[facing/heading]` `[cardinal direction]` along `[road name]`.
* *(From the intersection)* Intersection with `[intersection name]` is `[intersection distance]` `[intersection cardinal direction]`.
* *(From the POI)* `[POI name]` is `[POI distance]` `[POI cardinal direction]`.

* **Other:**

* *(From ahead)* You are `[facing/heading]` `[cardinal direction]`
* *(From the road)* Nearest road, `[road name]` is `[road distance]` `[road cardinal direction]`.
* *(From the POI)* `[POI name]` is `[POI distance]` `[POI cardinal direction]`.
