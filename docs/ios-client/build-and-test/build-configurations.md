# Build Configurations

The Soundcape Xcode project contains 3 build configurations. We used each configuration for the purposes defined below, but you may wish to use a different configuration model.

* **Debug** - Used for local builds / when installing directly from Xcode
* **AdHoc** - Used for testing outside of TestFlight releases
* **Release** - Used for AppStore and TestFlight builds

## Feature Flags

Each build configuration may enable a different set of feature flags via the files:  
`/apps/ios/GuideDogs/Assets/Configurations/FeatureFlags-<<Configuration>>`

See for additional documentation and to define feature flags within the code, see:  
`/apps/ios/GuideDogs/Code/App/Feature Flags/FeatureFlag.swift`
