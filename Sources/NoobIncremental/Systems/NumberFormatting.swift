import Foundation

/// Compact display formatting for incremental-game numbers (1.2K, 3.45M, 1.00e33, ...).
enum NumberFormatting {

    private static let suffixes = [
        "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
        "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod"
    ]

    static func format(_ value: Decimal, fractionDigits: Int = 2) -> String {
        format(NSDecimalNumber(decimal: value).doubleValue, fractionDigits: fractionDigits)
    }

    static func format(_ value: Double, fractionDigits: Int = 2) -> String {
        guard value.isFinite else { return "0" }
        let sign = value < 0 ? "-" : ""
        let originalMagnitude = abs(value)

        guard originalMagnitude >= 1000 else {
            return sign + trimmedString(originalMagnitude, fractionDigits: originalMagnitude < 10 ? fractionDigits : max(fractionDigits - 1, 0))
        }

        // Divide by 1000 repeatedly rather than deriving the tier from log10: log10 can land
        // a hair below an exact power of 1000 due to floating-point error and pick the wrong tier.
        let maxTier = suffixes.count - 1
        var magnitude = originalMagnitude
        var tier = 0
        while magnitude >= 1000, tier < maxTier {
            magnitude /= 1000
            tier += 1
        }

        guard magnitude < 1000 else {
            return sign + String(format: "%.\(fractionDigits)e", originalMagnitude)
        }

        var text = trimmedString(magnitude, fractionDigits: fractionDigits)
        // Rounding at `fractionDigits` precision can itself push the scaled value up to 1000
        // (e.g. 999.9996 -> "1000.00"). Bump the tier once more when that happens.
        if let rounded = Double(text), rounded >= 1000 {
            guard tier < maxTier else {
                return sign + String(format: "%.\(fractionDigits)e", originalMagnitude)
            }
            tier += 1
            text = trimmedString(rounded / 1000, fractionDigits: fractionDigits)
        }

        return sign + text + suffixes[tier]
    }

    private static func trimmedString(_ value: Double, fractionDigits: Int) -> String {
        String(format: "%.\(fractionDigits)f", value)
    }
}
