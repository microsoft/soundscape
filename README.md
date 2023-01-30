# Open Source Soundscape

This open source project is a subset of 'Microsoft Soundscape' product
as released on the Apple App Store.  To make this contribution to open
source, it was necessary to remove 3rd party sources and some other
proprietary code.  Further Microsoft branding, reference to specific
Microsoft services, and deployment mechanisms have been removed.

# What is Microsoft Soundscape

"Microsoft Soundscape is a product from Microsoft Research that explores the use of innovative audio-based technology to enable people to build a richer awareness of their surroundings, thus becoming more confident and empowered to get around. Unlike step-by-step navigation apps, Soundscape uses 3D audio cues to enrich ambient awareness and provide a new way to relate to the environment. It allows you to build a mental map and make personal route choices while being more comfortable within unfamiliar spaces. Soundscape is designed to be used by everyone and live in the background; therefore, feel free to use it in conjunction with other apps such as podcasts, audio books, email and even GPS navigation!"

Additional app features include:

* **Guided Routes** - Using the web authoring tool, users can create and share guided routes for Soundscape.
* **Street Preview** - An audio virtual reality experience which places the user on a location with the ability to explore the road graph.
* **Head tracking** (with supported headsets) - Allows the points of interest to stay in place as the user moves the head.
* **Background Use** - The ability to run in the background while you use other apps.
* **Current Location** - Quickly hear your current location and direction of travel.

# Expectations

This open source project is not a turnkey equivalent of the Microsoft Soundscape product offering.  The sources have been modified to remove branding and IP.  References to the production resources were also altered.  Further elements too specific to Microsoft's internal environmen were omitted.

To bring this up this open source project, you'll need:
* iOS experience -- Apple developer account, experience with Swift, Xcode, AppStore processes, etc.
* Cloud experience -- The services ran in the the Azure Cloud, though could be adapted to run elsewhere. In particular, note that no automation has been included to provision the required resources and services.

The core elements of the  service eg. the OSM ingester via [imposm3](https://github.com/omniscale/imposm3) and serving the ingested data as GeoJSON are provided and packaged as containers in svcs/data.

Microsoft is committed to supporting this open source offering.  Please use the [Issues](https://github.com/microsoft/soundscape/issues) section to ask questions.

# Contents

The open source project contains three components:

| Component | Sources | Documentation |
| --------- | ------- | ------------- |
| Soundscape iOS Client app| [dir](./apps/ios) | [docs](docs/Client.md) |
| Service backend | [dir](./svcs/data) | [docs](docs/Services.md) |
| Authoring web app | [dir](./svcs/soundscape-authoring) | [docs](docs/Authoring.md) |

# Trademark Notice

Trademarks This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow Microsoft’s Trademark & Brand Guidelines. Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party’s policies.
