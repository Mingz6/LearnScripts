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

# remove xcode Junk
rm -rf ~/Library/Developer/CoreSimulator/Caches

# Remove iOS DeviceSupport
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport

# Remove DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData

# Images takes lots of space, but I don't know is it safe to delete them
/Library/Developer/CoreSimulator/Images