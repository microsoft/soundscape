# Heading in Soundscape

## Types of Heading

### Course

- The direction of movement
- Inferred from the movement of the user's iPhone and provided by the Core Location framework

### User Orientation

- The direction that the user's head is facing
- Measured by an external IMU worn on the user's head (e.g., Apple AirPods)

### Device Orientation

- The direction that the user's iPhone is pointing
- Measured by the internal compass in the user's iPhone and provided by the Core Location framework

## Heading Availability

The following table defines the conditions that must be met for each type of heading to be available. If conditions are not met, then the corresponding heading is considered unavailable.

|Heading|State|
|--|--|
|Course  |User is walking or in-vehicle  |
|User Orientation  |Headset with external IMU is available  |
|Device Orientation  |Dependent on context of use*  |

*Desired state for iPhone orientation is subject to the context of use. Desired states are defined in [Heading Availability - iPhone Orientation](#heading-availability---iphone-orientation)

## Heading Availability - iPhone Orientation

|Context  |State  |
|--|--|
|Default  |Soundscape is in the foreground or the iPhone is being held flat  |
|Kayaking  |iPhone is held vertically in lanyard*  |

*We are still exploring and defining how Soundscape should work while kayaking. The desired state may change as we continue this work, but the table reflects current behavior.

## Heading Priority

The following table assigns a priority (with 1 being the highest priority) to each type of heading for a given feature.

The table differentiates between the type of heading ghat is used for the **collection** of data (e.g., deciding what data to call out) and the type of heading that is used to **present** data (e.g., how to spatialize the call-out).

Soundscape will try to use the type of heading that is marked as the highest priority for the given feature and context. If the type of heading is not available (as defined in [Heading Availability](#heading-availability)), Soundscape will try to use the type of heading that is marked as the next highest priority and so on.

|  |Collection  |  |  |Presentation  |  |  |
|--|--|--|--|--|--|--|
|  |1st Priority  |2nd Priority  |3rd Priority  |1st Priority  |2nd Priority  |3rd Priority  |
|Place Callout  |n/a  |n/a  |n/a  |Head  |Course  |iPhone  |
|Intersection Callout  |Course  |Head  |iPhone  |Head  |Course  |iPhone  |
|Beacon Callout  |n/a  |n/a  |n/a  |Head  |Course  |iPhone  |
|My Location  |Course  |Head  |iPhone  |Head  |Course  |iPhone  |
|Nearby Markers  |Course  |Head  |iPhone  |Head  |Course  |iPhone  |
|Around Me  |Course  |Head  |iPhone  |Head  |Course  |iPhone  |
|Ahead of Me  |Head  |iPhone  |Course  |Head  |Course  |iPhone  |
|Beacon  |Head  |iPhone  |Course  |Head  |Course  |iPhone  |

## What if heading is not available?

There are scenarios in which all heading values will be unavailable. Currently, this will occur when an external IMU is not available and the user is standing still and not holding her phone. The following table outlines the expected behavior for each feature where this scenario occurs.

|Feature  |Action  |
|--|--|
|Place Callout  |Skip callout  |
|Intersection Callout  |Skip callout  |
|Beacon Callout  |Skip callout  |
|My Location  |n/a  |
|Nearby Markers  |n/a  |
|Around Me  |n/a  |
|Ahead of Me  |n/a  |
|Beacon  |"Dim" beacon  |
