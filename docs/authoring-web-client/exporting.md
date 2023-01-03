# Exporting Activities

The current version of the authoring web client allows exporting an activity as a GPX file containing the activity data. The GPX file contains the links to the uploaded media items (such as waypoint image), but it does not include the media items themselves when exporting.

In order to download the media item, the GPX file can be opened with a text editor, copy the links in this pattern `<link href="{LINK}">` and download in a browser or another HTTP content retrieval software.

For example, when downloading an activity named `my_activity.gpx`, to find all media links via macOS terminal:

```bash
grep -E -o 'href=".+"' ./my_activity.gpx
```

To download a media file:
```bash
wget {LINK}
```
