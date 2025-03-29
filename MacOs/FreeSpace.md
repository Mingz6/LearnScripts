# Get the timemachine backup name on loca
```bash
tmutil listlocalsnapshotdates
```

# Remove timemachine backup on local
```bash
tmutil deletelocalsnapshots <2025-01-06-052634>
```

# try to remove all caches
rm -rf ~/Library/Caches/*
rm -rf /Library/Caches/*
rm -rf /System/Library/Caches/*

# remove xcode Junk
rm -rf ~/Library/Developer/CoreSimulator/Caches
# Remove iOS DeviceSupport
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport
# Remove DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData

# Remove Wechat Messages
rm -rf ~/Library/Containers/com.tencent.xinWeChat/Data/Library/Application\ Support/com.tencent.xinWeChat/2.0b4.0.9/62e8bf572309d9a54cc1194863436161/Message/MessageTemp
# Remove teams messages
rm -rf ~/Library/Containers/com.microsoft.teams2/Data/Library/Caches/Microsoft/MSTeams
rm -rf ~/Library/Containers/com.microsoft.teams2/Data/Library/Caches/Microsoft/com.microsoft.teams2
rm -rf ~/Library/Containers/com.microsoft.teams2/Data/Library/Caches/Microsoft/com.microsoft.teams2.modulehost
rm -rf ~/Library/Containers/com.microsoft.teams2/Data/Library/Caches/Microsoft/WebKit
# Remove discord caches
rm -rf ~/Library/Application\ Support/discord/Cache
# remove vscode caches
sudo rm -rf ~/Library/Application\ Support/Code/Cache

# remove telegram caches
rm -rf ~/Library/Group\ Containers/6N38VWS5BX.ru.keepcoder.Telegram/stable/account-17560967941536714162/postbox/media

# remove Apple wallpaper caches
rm -rf ~/Library/Containers/com.apple.wallpaper.agent/Data/Library/Caches/com.apple.wallpaper.caches
# remove Apple GEOD caches
rm -rf ~/Library/Containers/com.apple.geod/Data/Library/Caches/com.apple.geod
# Remove Apple media analysis
rm -rf ~/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches/PFSceneGeographyData.index
rm -rf ~/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches/com.apple.mediaanalysisd
rm -rf ~/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches/PFSceneTaxonomyData.index
rm -rf ~/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches/com.apple.VisualIntelligence
# Remove Apple Photo analysis
rm -rf ~/Library/Containers/com.apple.photoanalysisd/Data/Library/Caches/

# Remove logs 
rm -rf ~/Library/Logs

# Images takes lots of space, but I don't know is it safe to delete them
# cannot be deleted with sudo.
<!-- rm -rf /Library/Developer/CoreSimulator/Images -->

# Remove npx cache
rm -rf ~/.npm/_npx 
# TODO: check this folder
rm -rf /private/var/tmp