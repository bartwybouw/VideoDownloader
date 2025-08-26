import SwiftUI
import Foundation

// MARK: - Window Configuration
struct WindowConfig {
    static let minWidth: CGFloat = 240
    static let maxWidth: CGFloat = 280
    static let minHeight: CGFloat = 320
    static let iconSize: CGFloat = 24
}

struct ContentView: View {
    @State private var videoURL: String = ""
    @State private var selectedFolderURL: URL?
    @State private var isDownloading: Bool = false
    @State private var downloadMessage: String = ""
    @State private var progressValue: Double = 0.0
    @State private var downloadSpeed: String = ""
    @State private var eta: String = ""
    @State private var currentStatus: String = ""
    @State private var downloadTask: Process?
    @State private var isPaused: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0, green: 0.478, blue: 1), Color(red: 0.353, green: 0.784, blue: 0.980)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Video Downloader")
                    .font(.title2)
            }
            .padding(.top, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Video URL:")
                    .font(.headline)
                TextField("Plak hier de video URL", text: $videoURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Download locatie:")
                    .font(.headline)
                HStack {
                    Text(selectedFolderURL?.path ?? "Geen map geselecteerd")
                        .foregroundColor(selectedFolderURL == nil ? .gray : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                    
                    Button("Browse") {
                        selectFolder()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: downloadVideo) {
                    if isDownloading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Downloaden...")
                        }
                    } else {
                        Text("Download Video")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(videoURL.isEmpty || selectedFolderURL == nil || isDownloading)
                
                if isDownloading {
                    Button(action: pauseResumeDownload) {
                        Text(isPaused ? "Hervatten" : "Pauzeren")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: stopDownload) {
                        Text("Stoppen")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            
            if !downloadMessage.isEmpty {
                Text(downloadMessage)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
            }
            
            // Progress Section
            if isDownloading {
                VStack(spacing: 10) {
                    ProgressView(value: progressValue, total: 100)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(1.0, anchor: .center)
                    
                    HStack {
                        Text("\(String(format: "%.1f", progressValue))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if !downloadSpeed.isEmpty {
                            Text(downloadSpeed)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if !eta.isEmpty {
                            Text("ETA: \(eta)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !currentStatus.isEmpty {
                        Text(currentStatus)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer(minLength: 8)
            
            // Footer with credits
            VStack(spacing: 2) {
                Link("Powered by yt-dlp", destination: URL(string: "https://github.com/yt-dlp/yt-dlp")!)
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                Link("Contact: bart.wybouw@bamati.be", destination: URL(string: "mailto:bart.wybouw@bamati.be")!)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 8)
        }
        .padding(24)
        .frame(minWidth: WindowConfig.minWidth, maxWidth: WindowConfig.maxWidth, minHeight: WindowConfig.minHeight)
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK {
            selectedFolderURL = panel.url
        }
    }
    
    private func downloadVideo() {
        guard let folderURL = selectedFolderURL else { return }
        
        // Reset progress state
        isDownloading = true
        downloadMessage = "Download wordt gestart..."
        progressValue = 0.0
        downloadSpeed = ""
        eta = ""
        currentStatus = "Voorbereiden..."
        isPaused = false
        
        let outputPath = folderURL.appendingPathComponent("%(title)s.%(ext)s").path
        
        let task = Process()
        downloadTask = task
        
        // Find yt-dlp location
        let ytdlpPaths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]
        
        var ytdlpPath: String?
        for path in ytdlpPaths {
            if FileManager.default.fileExists(atPath: path) {
                ytdlpPath = path
                break
            }
        }
        
        guard let validYtdlpPath = ytdlpPath else {
            downloadMessage = "❌ yt-dlp niet gevonden. Installeer het met: brew install yt-dlp"
            isDownloading = false
            return
        }
        
        task.launchPath = validYtdlpPath
        task.arguments = [
            "--hls-prefer-native",
            "--newline",
            "--progress",
            videoURL,
            "-o", outputPath
        ]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        // Start reading output in real time
        let outputHandle = pipe.fileHandleForReading
        outputHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty {
                let output = String(data: data, encoding: .utf8) ?? ""
                DispatchQueue.main.async {
                    self.parseDownloadProgress(output: output)
                }
            }
        }
        
        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                outputHandle.readabilityHandler = nil
                self.isDownloading = false
                self.downloadTask = nil
                
                if task.terminationStatus == 0 {
                    self.downloadMessage = "✅ Download voltooid!"
                    self.progressValue = 100.0
                    self.currentStatus = "Gereed"
                } else if task.terminationStatus == 15 { // SIGTERM (stopped by user)
                    self.downloadMessage = "⏹️ Download gestopt"
                    self.currentStatus = "Gestopt door gebruiker"
                } else {
                    self.downloadMessage = "❌ Download mislukt. Controleer de URL en probeer opnieuw."
                    self.currentStatus = "Fout opgetreden"
                }
            }
        }
        
        do {
            try task.run()
        } catch {
            isDownloading = false
            downloadTask = nil
            downloadMessage = "❌ Fout: \(error.localizedDescription)"
        }
    }
    
    private func pauseResumeDownload() {
        guard let task = downloadTask else { return }
        
        if isPaused {
            // Resume: Send SIGCONT
            kill(task.processIdentifier, SIGCONT)
            isPaused = false
            currentStatus = "Download hervat..."
        } else {
            // Pause: Send SIGSTOP
            kill(task.processIdentifier, SIGSTOP)
            isPaused = true
            currentStatus = "Download gepauzeerd"
        }
    }
    
    private func stopDownload() {
        guard let task = downloadTask else { return }
        
        task.terminate()
        downloadTask = nil
        isDownloading = false
        downloadMessage = "⏹️ Download gestopt"
        currentStatus = "Gestopt door gebruiker"
    }
    
    private func parseDownloadProgress(output: String) {
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse download progress line (format: [download]  45.2% of 123.45MB at 1.23MB/s ETA 00:45)
            if trimmedLine.contains("[download]") && trimmedLine.contains("%") {
                // Extract percentage
                if let percentRange = trimmedLine.range(of: #"\d+\.\d+%"#, options: .regularExpression) {
                    let percentString = String(trimmedLine[percentRange]).replacingOccurrences(of: "%", with: "")
                    if let percent = Double(percentString) {
                        progressValue = percent
                    }
                }
                
                // Extract download speed
                if let speedRange = trimmedLine.range(of: #"at [\d\.]+[KMGT]?B/s"#, options: .regularExpression) {
                    let speedString = String(trimmedLine[speedRange]).replacingOccurrences(of: "at ", with: "")
                    downloadSpeed = speedString
                }
                
                // Extract ETA
                if let etaRange = trimmedLine.range(of: #"ETA \d+:\d+"#, options: .regularExpression) {
                    let etaString = String(trimmedLine[etaRange]).replacingOccurrences(of: "ETA ", with: "")
                    eta = etaString
                }
            }
            
            // Parse status messages
            if trimmedLine.contains("[info]") {
                currentStatus = trimmedLine.replacingOccurrences(of: "[info] ", with: "")
            }
            
            if trimmedLine.contains("Downloading") && !trimmedLine.contains("[download]") {
                currentStatus = "Video wordt gedownload..."
            }
            
            if trimmedLine.contains("Extracting") {
                currentStatus = "Video-informatie wordt opgehaald..."
            }
            
            if trimmedLine.contains("Merging") {
                currentStatus = "Bestanden worden samengevoegd..."
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}