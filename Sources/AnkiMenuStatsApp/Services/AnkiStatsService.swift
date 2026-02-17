import Foundation

protocol StatsServing: Sendable {
    func fetchStats() async throws -> ReviewStats
}

private struct DeckStatsParams: Encodable {
    let decks: [String]
}

private struct DeckStatsEntry: Decodable {
    let newCount: Int
    let learnCount: Int
    let reviewCount: Int

    enum CodingKeys: String, CodingKey {
        case newCount = "new_count"
        case learnCount = "learn_count"
        case reviewCount = "review_count"
    }
}

struct AnkiStatsService: StatsServing {
    let client: AnkiClient

    init(client: AnkiClient = AnkiClient()) {
        self.client = client
    }

    func fetchStats() async throws -> ReviewStats {
        async let remainingCount = fetchRemainingCount()
        async let collectionStatsHTML: String = client.request(action: "getCollectionStatsHTML")

        let dueCount = try await remainingCount
        let html = try await collectionStatsHTML

        let studiedSecondsToday = parseStudiedTime(from: html)

        return ReviewStats(
            remainingCount: dueCount,
            studiedSecondsToday: studiedSecondsToday,
            lastUpdated: Date()
        )
    }

    private func fetchRemainingCount() async throws -> Int {
        let deckNames: [String] = try await client.request(action: "deckNames")
        let concreteDecks = deckNames.filter { $0 != "All" }

        if concreteDecks.isEmpty {
            return 0
        }

        let statsByDeckID: [String: DeckStatsEntry] = try await client.request(
            action: "getDeckStats",
            params: DeckStatsParams(decks: concreteDecks)
        )

        return statsByDeckID.values.reduce(into: 0) { total, entry in
            total += entry.newCount
            total += entry.learnCount
            total += entry.reviewCount
        }
    }

    private func parseStudiedTime(from html: String) -> TimeInterval {
        let plainText = extractPlainText(from: html)

        let patterns = [
            "Studied\\s+\\d+\\s+cards?\\s+in\\s+(.+?)\\s+today",
            "in\\s+(.+?)\\s+today"
        ]

        for pattern in patterns {
            guard
                let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
                let match = regex.firstMatch(
                    in: plainText,
                    options: [],
                    range: NSRange(plainText.startIndex..., in: plainText)
                ),
                match.numberOfRanges > 1,
                let range = Range(match.range(at: 1), in: plainText)
            else {
                continue
            }

            let durationText = String(plainText[range])
            let seconds = parseDurationString(durationText)
            if seconds > 0 {
                return seconds
            }
        }

        return 0
    }

    private func extractPlainText(from html: String) -> String {
        guard let data = html.data(using: .utf8) else {
            return html
        }

        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) {
            return sanitize(attributed.string)
        }

        return sanitize(html)
    }

    private func sanitize(_ text: String) -> String {
        var sanitized = text
        let formatCharacters = ["\u{2066}", "\u{2067}", "\u{2068}", "\u{2069}", "\u{200E}", "\u{200F}", "\u{00A0}"]
        for character in formatCharacters {
            sanitized = sanitized.replacingOccurrences(of: character, with: " ")
        }

        return sanitized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func parseDurationString(_ input: String) -> TimeInterval {
        let pattern = "([0-9]+(?:\\.[0-9]+)?)\\s*(hours?|hrs?|hr|h|minutes?|mins?|min|m|seconds?|secs?|sec|s)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return 0
        }

        let nsRange = NSRange(input.startIndex..., in: input)
        let matches = regex.matches(in: input, options: [], range: nsRange)

        var total: TimeInterval = 0

        for match in matches {
            guard
                match.numberOfRanges >= 3,
                let amountRange = Range(match.range(at: 1), in: input),
                let unitRange = Range(match.range(at: 2), in: input),
                let amount = Double(input[amountRange])
            else {
                continue
            }

            let unit = input[unitRange].lowercased()
            if unit.hasPrefix("h") {
                total += amount * 3600
            } else if unit.hasPrefix("m") {
                total += amount * 60
            } else {
                total += amount
            }
        }

        return total
    }
}
