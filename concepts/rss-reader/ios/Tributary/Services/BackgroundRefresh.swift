import BackgroundTasks
import Foundation
import OSLog

/// Local mode refreshes inside the OS's background budget. iOS decides when; we ask for
/// no sooner than the shortest feed interval. The task body itself lives on the scene as
/// `.backgroundTask(.appRefresh(identifier))` in TributaryApp.
enum BackgroundRefresh {
    static let identifier = "com.flntfnd.tributary.refresh"
    private static let logger = Logger(subsystem: "com.flntfnd.tributary", category: "background")

    static func scheduleNext(after interval: TimeInterval = 30 * 60) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date().addingTimeInterval(interval)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Simulator and some debug configurations refuse background tasks; not fatal.
            logger.debug("Could not schedule refresh: \(error.localizedDescription, privacy: .public)")
        }
    }
}
