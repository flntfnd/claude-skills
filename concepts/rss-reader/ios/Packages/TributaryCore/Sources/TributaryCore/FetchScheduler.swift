import Foundation

/// Decides how often a feed is worth fetching. Mirrors the server scheduler described in
/// CONCEPT.md so a feed behaves the same in local mode: cadence-derived interval, clamped
/// to a floor and ceiling, exponential backoff on errors, Priority lane pinned to the floor.
public enum FetchScheduler {
    public static let floor: TimeInterval = 15 * 60
    public static let ceiling: TimeInterval = 24 * 3600
    public static let priorityInterval: TimeInterval = 15 * 60

    /// Next interval from the observed posting dates (most recent first or any order).
    public static func interval(postDates: [Date], isPriority: Bool, errorCount: Int, now: Date = Date()) -> TimeInterval {
        if errorCount > 0 {
            let backoff = min(ceiling, 30 * 60 * pow(2, Double(min(errorCount, 6) - 1)))
            return backoff
        }
        if isPriority { return priorityInterval }
        let sorted = postDates.sorted(by: >)
        guard sorted.count >= 2 else {
            return sorted.first.map { date in
                // One post: fetch hourly if it was recent, daily if it was long ago.
                now.timeIntervalSince(date) < 7 * 86_400 ? 3600 : ceiling
            } ?? 3600
        }
        let gaps = zip(sorted, sorted.dropFirst()).map { $0.timeIntervalSince($1) }.filter { $0 > 0 }
        guard !gaps.isEmpty else { return 3600 }
        let median = gaps.sorted()[gaps.count / 2]
        // Poll at a quarter of the typical gap so a post is rarely more than that late.
        return min(ceiling, max(floor, median / 4))
    }

    public static func nextFetch(after lastFetch: Date?, interval: TimeInterval, now: Date = Date()) -> Date {
        guard let lastFetch else { return now }
        return lastFetch.addingTimeInterval(interval)
    }
}
