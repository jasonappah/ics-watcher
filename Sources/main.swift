import AppKit
import Foundation

// MARK: - Logging

func log(_ message: String) {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let timestamp = formatter.string(from: Date())
    print("[\(timestamp)] \(message)")
    fflush(stdout)
}

// MARK: - ICS Event Model

struct ICSEvent {
    let summary: String
    let location: String?
    let startDate: Date?
    let endDate: Date?
    
    var displayText: String {
        var lines: [String] = []
        lines.append("Event: \(summary)")
        
        if let start = startDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .short
            lines.append("When: \(formatter.string(from: start))")
        }
        
        if let loc = location, !loc.isEmpty {
            lines.append("Where: \(loc)")
        }
        
        return lines.joined(separator: "\n")
    }
}

// MARK: - ICS Parser

func parseICSDate(_ value: String) -> Date? {
    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
    
    let formats = [
        "yyyyMMdd'T'HHmmss'Z'",  // 20260126T100000Z
        "yyyyMMdd'T'HHmmss",      // 20260126T100000
        "yyyyMMdd"                // 20260126
    ]
    
    for format in formats {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if format.hasSuffix("'Z'") {
            formatter.timeZone = TimeZone(identifier: "UTC")
        }
        if let date = formatter.date(from: cleaned) {
            return date
        }
    }
    return nil
}

func parseICS(at url: URL) -> ICSEvent? {
    guard let content = try? String(contentsOf: url, encoding: .utf8) else {
        log("Failed to read ICS file: \(url.path)")
        return nil
    }
    
    var summary = "Unknown Event"
    var location: String?
    var startDate: Date?
    var endDate: Date?
    
    let lines = content.components(separatedBy: .newlines)
    for line in lines {
        if line.hasPrefix("SUMMARY:") {
            summary = String(line.dropFirst("SUMMARY:".count))
        } else if line.hasPrefix("LOCATION:") {
            location = String(line.dropFirst("LOCATION:".count))
        } else if line.hasPrefix("DTSTART") {
            // Handle DTSTART:value or DTSTART;TZID=...:value
            if let colonIndex = line.lastIndex(of: ":") {
                let value = String(line[line.index(after: colonIndex)...])
                startDate = parseICSDate(value)
            }
        } else if line.hasPrefix("DTEND") {
            if let colonIndex = line.lastIndex(of: ":") {
                let value = String(line[line.index(after: colonIndex)...])
                endDate = parseICSDate(value)
            }
        }
    }
    
    return ICSEvent(summary: summary, location: location, startDate: startDate, endDate: endDate)
}

// MARK: - Confirmation Dialog

func showConfirmationDialog(for event: ICSEvent, filename: String) -> Bool {
    NSApplication.shared.activate(ignoringOtherApps: true)
    
    let alert = NSAlert()
    alert.messageText = "Add to Calendar?"
    alert.informativeText = event.displayText
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Add to Calendar")
    alert.addButton(withTitle: "No Thanks")
    
    let response = alert.runModal()
    return response == .alertFirstButtonReturn
}

// MARK: - File Watcher

class ICSWatcher {
    let downloadsURL: URL
    var directoryMonitor: DispatchSourceFileSystemObject?
    var processingFiles: Set<String> = []
    let fileManager = FileManager.default
    
    init() {
        downloadsURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
    }
    
    func start() {
        log("ICS Watcher starting...")
        log("Monitoring: \(downloadsURL.path)")
        
        checkForNewICSFiles()
        startDirectoryMonitor()
        
        log("ICS Watcher running. Waiting for ICS files...")
        RunLoop.current.run()
    }
    
    func startDirectoryMonitor() {
        let fd = open(downloadsURL.path, O_EVTONLY)
        guard fd >= 0 else {
            log("Error: Could not open Downloads directory for monitoring")
            return
        }
        
        directoryMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )
        
        directoryMonitor?.setEventHandler { [weak self] in
            self?.checkForNewICSFiles()
        }
        
        directoryMonitor?.setCancelHandler {
            close(fd)
        }
        
        directoryMonitor?.resume()
    }
    
    func checkForNewICSFiles() {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: downloadsURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            
            let icsFiles = contents.filter { $0.pathExtension.lowercased() == "ics" }
            
            for file in icsFiles {
                let filename = file.lastPathComponent
                guard !processingFiles.contains(filename) else { continue }
                
                processingFiles.insert(filename)
                handleICSFile(file)
            }
        } catch {
            log("Error scanning Downloads: \(error.localizedDescription)")
        }
    }
    
    func handleICSFile(_ url: URL) {
        let filename = url.lastPathComponent
        log("Found ICS file: \(filename)")
        
        guard let event = parseICS(at: url) else {
            log("Failed to parse ICS file, moving to trash")
            trashFile(url)
            return
        }
        
        log("Event: \(event.summary)")
        
        let shouldAdd = showConfirmationDialog(for: event, filename: filename)
        
        if shouldAdd {
            log("User chose to add event to calendar")
            NSWorkspace.shared.open(url)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.trashFile(url)
            }
        } else {
            log("User declined to add event")
            trashFile(url)
        }
    }
    
    func trashFile(_ url: URL) {
        do {
            try fileManager.trashItem(at: url, resultingItemURL: nil)
            log("Moved to trash: \(url.lastPathComponent)")
        } catch {
            log("Error moving to trash: \(error.localizedDescription)")
        }
        
        processingFiles.remove(url.lastPathComponent)
    }
}

// MARK: - Main Entry

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let watcher = ICSWatcher()
watcher.start()
