# Video Downloader App - Build Instructies

## Vereisten
1. **Xcode** geïnstalleerd via App Store
2. **yt-dlp** geïnstalleerd: `brew install yt-dlp`

## Xcode instellen (eenmalig)
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

## App bouwen en runnen

### Methode 1: Xcode GUI (Aanbevolen)
1. Open `VideoDownloader.xcodeproj` in Xcode
2. Selecteer "My Mac" als destination
3. Druk ⌘R om te builden en runnen

### Methode 2: Command line
```bash
cd VideoDownloader
xcodebuild -project VideoDownloader.xcodeproj -scheme VideoDownloader -configuration Release build
```

## App exporteren voor distributie

### Stap 1: Build voor distributie
```bash
xcodebuild -project VideoDownloader.xcodeproj -scheme VideoDownloader -configuration Release -archivePath VideoDownloader.xcarchive archive
```

### Stap 2: Export app
```bash
xcodebuild -exportArchive -archivePath VideoDownloader.xcarchive -exportPath ./Export -exportOptionsPlist ExportOptions.plist
```

## Troubleshooting

### "Developer directory not found"
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### "yt-dlp not found"
```bash
brew install yt-dlp
```

### Permission issues
De app vraagt automatisch om toestemming voor:
- Netwerk toegang (voor downloads)
- Bestanden schrijven (voor opslaan)

## App Features
- ✅ Native macOS interface
- ✅ Folder picker dialog
- ✅ Progress indicator
- ✅ Error handling
- ✅ Ondersteunt alle yt-dlp websites