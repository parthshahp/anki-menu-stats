import Foundation

struct ReviewStats: Equatable {
    let remainingCount: Int
    let studiedSecondsToday: TimeInterval
    let lastUpdated: Date
}
