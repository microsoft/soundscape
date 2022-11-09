# Geolocation Manager

The `GeolocationManager` is the object that is responsible for providing the rest of Soundscape with geolocation and orientation updates, which means that it sits at the front of Soundscape's pipline. The architecture of the `GeolocationManager` is intended to be flexible such that it is easy to plug in custom implementations of location, course, and heading providers. This makes it easy to implement features like GPX simulation with minimal changes to the rest of Soundscape.

In this documentation, we will walk through the basic design of the `GeolocationManager` and explain how the `GeolocationManager` can be extended to support new location, course, and heading providers.

## Design of the Geolocation Manager

The easiest way to see an overview of what the `GeolocationManager` does is to take a look at the functions described in `GeolocationManagerProtocol`:

```swift
protocol GeolocationManagerProtocol: AnyObject {
    ...

    func start()
    func stop()
    func snooze()
    
    func add(_ provider: LocationProvider)
    func remove(_ provider: LocationProvider)
    func add(_ provider: CourseProvider)
    func remove(_ provider: CourseProvider)
    func add(_ provider: UserHeadingProvider)
    func remove(_ provider: UserHeadingProvider)
}
```

As we see in this protocol, the `GeolocationManager` is responsible for managing three sensor data providers that can be overriden with custom implementations: a location provider, a course provider, and a user heading provider. There is also a device heading provider which is always implemented using the `CoreLocation` framework and cannot be overriden. When the `start()` function is called, the `GeolocationManager` will call start each of these providers and listen for updates of their respective sensor data. In each case, the `GeolocationManager`simply propagates updates from these providers to the rest of the app.

The flow of location data through Soundscape is quite simple. When the `GeolocationManager` receives a location update, it passes that location update to the `GeolocationManagerUpdateDelegate`. This delegate is implemented by the `SpatialDataContext`, allowing the `SpatialDataContext` to ensure that POI data is downloaded for the user's current location before the rest of the app is informed of the location update. The `SpatialDataContext` is responsible for passing this update along to the rest of the app (using the `locationUpdated` notification).

The flow of orientation data to the rest of the app is slightly more complicated due to the fact that the course, device heading, and user heading are all managed through the same pipeline allowing different components to select the appropriate orientation information for the given task. The `Heading` class handles this prioritization of orientation data for components that are listening fo orientation updates. The `GeolocationManager` sends a `.headingTypeDidUpdate` notification any time any of the three orientation providers provide an updated value and the `Heading` class listens for these updates. For more information on how the various types of orientation data are used in different parts of Soundscape see: [Use of Heading within Soundscape](Use-of-Heading-within-Soundscape.md).

### Default Providers

The `GeolocationManager` defaults to listening for GPS, course, and device heading (i.e. compass) updates from the `CoreLocation` framework. All three of these providers are implemented by the `CoreLocationManager` class. By default, there is no user heading provider enabled. User heading providers provide orientation data for the user's head, and the user must therefore be wearing a head-tracking headset (e.g. Air Pods Pro) for a user heading provider to be enabled.

### Custom Provider Implementations

Any or all of the default providers can be replaced by a custom implementation. This can be useful in a number of circumstances. For example, this could be used for:

* Integrating a new head-tracking headset by providing a custom user heading provider (see `HeadphoneMotionManager.swift`)
* Integrating a custom location provider for simulating a the phone's location during testing (See `GPXSimulator.swift`)
* Integrating a custom indoor location provider

#### Custom Location Providers

Custom location providers only need to implement four functions:

```swift
protocol LocationProvider: AnyObject, SensorProvider {
    var locationDelegate: LocationProviderDelegate? { get set }

    func startLocationUpdates()
    func stopLocationUpdates()
    func startMonitoringSignificantLocationChanges() -> Bool
    func stopMonitoringSignificantLocationChanges()
}

protocol LocationProviderDelegate: AnyObject {
    func locationProvider(_ provider: LocationProvider, didUpdateLocation location: CLLocation?)
}
```

`startLocationUpdates()` and `stopLocationUpdates()` are self-explanatory. `startMonitoringSignificantLocationChanges()` and `stopMonitoringSignificantLocationChanges()` are used when the user turns on "Snooze" mode. In this mode, location providers should attempt to minimize energy consumption by only notifying the `locationDelegate` about updates when the user moves a significant distance. For the default `CoreLocation` provider, this is approximately 50-100 meters. This feature is useful when Soundscape users want the app to be quiet until they leave their current location, at which point it can start up again automatically.

To provide location updates to the `GeolocationManager`, a custom location provider needs only to call:

```swift
// newValue is the latest location update
locationDelegate?.locationProvider(self, didUpdateLocation: newValue)
```

#### Custom Course Providers

Custom course providers can either directly implement the `CourseProvider` protocol, or they can implement the `RawCourseProvider` protocol and then be wrapped by the `FilteredCourseProvider` class before being passed to the `GeolocationManager` (recommended). The `FilteredCourseProvider` ignores any course updates from its `RawCourseProvider` when the user is not currently in motion (e.g. walking). This filters out low accuracy course updates that may occur when the user is standing still. The default course provider is a `FilteredCourseProvider` that wraps the `CoreLocationManager` which implements `RawCourseProvider`.

Both of these protocols only have two functions (start and stop) that must be implemented:

```swift
protocol RawCourseProvider: SensorProvider {
    var courseDelegate: RawCourseProviderDelegate? { get set }

    func startCourseProviderUpdates()
    func stopCourseProviderUpdates()
}

protocol RawCourseProviderDelegate: AnyObject {
    func courseProvider(_ provider: RawCourseProvider, didUpdateCourse course: HeadingValue?, speed: Double?)
}

protocol CourseProvider: SensorProvider {
    var courseDelegate: CourseProviderDelegate? { get set }

    func startCourseProviderUpdates()
    func stopCourseProviderUpdates()
}

protocol CourseProviderDelegate: AnyObject {
    func courseProvider(_ provider: CourseProvider, didUpdateCourse course: HeadingValue?)
}
```

#### Custom User Heading Providers

Similarly to the other providers described above, custom user heading providers only need to implement several functions:

```swift
protocol UserHeadingProvider: AnyObject, SensorProvider {
    var headingDelegate: UserHeadingProviderDelegate? { get set }
    var accuracy: Double { get }

    func startUserHeadingUpdates()
    func stopUserHeadingUpdates()
}

protocol UserHeadingProviderDelegate: AnyObject {
    func userHeadingProvider(_ provider: UserHeadingProvider, didUpdateUserHeading heading: HeadingValue?)
}
```

It is worth noting that user heading providers should also provide an accuracy value that indicates the estimated accuracy of the heading updates from the head tracking device providing the updates. This is used primarily for debugging and logging given that the accuracy value may be measured differently depending on the specific hardware providing the data.