# TubeSync
A small Menu Bar OSX application to sync your Youtube Playlists to your Mac.

## Download
For the latest stable version of TubeSync, check the [releases](https://github.com/benjamincongdon/TubeSync/releases) page!

Alternatively, if you want the most 'up-to-date' (read 'buggy') version, you can download the master repo and compile the project yourself in XCode.

## Instructions
Using `TubeSync` is simple: 

1. To add a playlist to the sync watchlist, simply open the preferences window and click on the `+` near the Playlist table and paste in a youtube playlist URL. (For example, your Watch Later playlist would have the url `https://www.youtube.com/playlist?list=WL`).

2. Set `Automatic Sync Enabled` to your prefrence. If you do want to have your playlists synced automatically, you can set the `Sync Frequency` to define the time interval between syncs.

  If you don't have your playlists sync automatically, you can click `Sync Now` in the main menu or in the right-click menu to manually intiate syncing.
  
3. Click on the `+` near `Output Folder` to set the root directory where `TubeSync` will download your playlists.
4. That's it! You can go back the main menu and click `Sync Now` to do the initial sync, after which `TubeSync` will keep the local copy of your videos up-to-date on the automatic time interval you set.
