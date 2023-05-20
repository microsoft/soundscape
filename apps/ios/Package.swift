// swift-tools-version:5.2
import PackageDescription
let packageName = "GuideDogs" // <-- Change this to yours
let package = Package(
  name: "",
  // platforms: [.iOS("9.0")],
  products: [
    .library(name: packageName, targets: [packageName])
  ],
  targets: [
    .target(
      name: packageName,
      path: packageName,
      exclude: [
        "Code/Data/Models/Helpers",
        "Code/Behaviors/Helpers/GDAStateMachine",
        "Code/App/Helpers/NSException Handling"
      ]
    )
  ]
) 