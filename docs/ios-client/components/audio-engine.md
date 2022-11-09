# Audio Engine Overview

This document will describe how the audio engine renders sounds in Soundscape including both discrete sounds (like callouts and earcons) and dynamic sounds (e.g. beacons).

## Audio Engine Public API

NOTE: You should almost never need to directly call methods on the Audio Engine. Instead, if you want to generate new sounds, create a new callout generator within the Event Processor architecture (e.g. create a generator, add it to a behavior, and then create events that cause the generator to generate a `CalloutGroup` that captures the sounds you want played).

The core of the API surface for the audio engine is a set of `play(...)` functions that allow several types of sound objects to be rendered:

* `Sound` Protocol: Types that implement this protocol encapsulate discrete buffers of audio. The term "discrete" in this context is referring to the fact that the buffer of audio is played once and is done. Currently implement concrete types include:
  * `TTSSound`: Asynchronously renders audio buffers for a string using Apple's `AVSpeechSynthesizer` API.
  * `GenericSound`: Encapsulates any wav file (see `StaticAudioEngineAsset`). `GlyphSound` derives from this type in order to provide better logging for wav files that represent earcons.
  * `ConcatenatedSound`: A wrapper that takes multiple sounds and concatenates their buffers.
  * `LayeredSound`: A wrapper that takes multiple sounds and allows the audio engine to play their buffers simultaneously.
* `DynamicSound` Protocol: Dynamic sounds are streams of audio that are generated dynamically based on sensor input. All dynamic sounds are composed of a set of wav files and a function that determines which wav file should be playing at any given time. This allows beacons to have different components that play based on the bearing between the user's heading and the heading towards the beacon's location. `BeaconSound` is the only concrete implementation of this protocol currently.

All sound objects encapsulate information about how the sound should be rendered by the audio engine via the `SoundType` enum which has four cases:

* `.standard`: Causes the audio to be rendered in 2D
* `.localized`: Causes the audio to be rendered in 3D using the user's location and a geolocation assigned to the sound. As the user's location updates, the audio engine will automatically update the 3D rendering properties to appropriately localized the sound.
* `.relative`: Causes the audio to be rendered in 3D in a specified direction _**relative to the user's current heading**_. Audio rendered with this type will appear to be head-locked (if the audio is played at 90°, it will always appear to be to the user's right regardless of how their heading changes as the sound plays).
* `.compass`: Causes the audio to be rendered in 3D in a specified direction _**relative to the world**_. Audio rendered with this type will appear to be world-locked in the specified compass direction (e.g. always to the north).

The audio engine's public API also provides functions for managing the engine's lifecycle (starting and stopping it), stopping sounds, and managing some system audio state.

## Audio Engine Internals

Under the hood, the audio engine is responsible for constructing an `AVAudioEngine` instance and wiring up audio graph nodes within that instance appropriately in order to render all the various audio that may be playing at any given time in Soundscape. Key to this audio graph management is task of appropriately managing EQ nodes (which allow for controlling volume and balance) and environment nodes (which allow for controlling the 3D rendering of audio).
