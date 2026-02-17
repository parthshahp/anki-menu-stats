import AppKit
import Foundation

enum MenuBarState {
    case loading
    case loaded(ReviewStats)
    case failed(String)
}

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published private(set) var state: MenuBarState = .loading

    nonisolated private let service: any StatsServing
    private let refreshInterval: TimeInterval
    private var autoRefreshTask: Task<Void, Never>?

    init(service: any StatsServing, refreshInterval: TimeInterval = 120) {
        self.service = service
        self.refreshInterval = refreshInterval

        refresh()
        startAutoRefresh()
    }

    var menuBarTitle: String {
        switch state {
        case .loading:
            return "…"
        case .loaded(let stats):
            return "\(stats.remainingCount)"
        case .failed:
            return "!"
        }
    }

    var remainingDescription: String {
        switch state {
        case .loaded(let stats):
            return "\(stats.remainingCount) cards left today"
        case .loading:
            return "Loading remaining cards..."
        case .failed:
            return "Unable to load remaining cards"
        }
    }

    var studiedTimeDescription: String {
        switch state {
        case .loaded(let stats):
            return formatDuration(stats.studiedSecondsToday)
        case .loading:
            return "Loading..."
        case .failed:
            return "--"
        }
    }

    var lastUpdatedDescription: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        switch state {
        case .loaded(let stats):
            return "Updated \(formatter.string(from: stats.lastUpdated))"
        case .loading:
            return "Loading"
        case .failed:
            return "Update failed"
        }
    }

    var errorDescription: String? {
        if case .failed(let message) = state {
            return message
        }
        return nil
    }

    func refresh() {
        Task { await refreshNow() }
    }

    func openAnki() {
        let bundleID = "net.ankiweb.dtop"

        if let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
            running.activate(options: [.activateAllWindows])
            return
        }

        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.openApplication(
                at: appURL,
                configuration: NSWorkspace.OpenConfiguration()
            ) { _, _ in }
            return
        }

        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let candidateAppURLs = [
            URL(filePath: "/Applications/Anki.app"),
            homeDirectory.appending(path: "Applications/Anki.app")
        ]

        for appURL in candidateAppURLs where fileManager.fileExists(atPath: appURL.path) {
            NSWorkspace.shared.openApplication(
                at: appURL,
                configuration: NSWorkspace.OpenConfiguration()
            ) { _, _ in }
            return
        }

        if let url = URL(string: "anki://") {
            _ = NSWorkspace.shared.open(url)
        }
    }

    func quitApp() {
        NSApp.terminate(nil)
    }

    private func startAutoRefresh() {
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else {
                    break
                }
                try? await Task.sleep(for: .seconds(self.refreshInterval))
                await self.refreshNow()
            }
        }
    }

    private func refreshNow() async {
        do {
            let stats = try await service.fetchStats()
            state = .loaded(stats)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else {
            return "0m"
        }

        let totalSeconds = Int(seconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
