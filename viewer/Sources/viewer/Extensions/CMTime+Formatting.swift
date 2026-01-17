import AVFoundation

extension CMTime {
    var formattedString: String {
        guard isValid && !isIndefinite else { return "--:--" }

        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    var shortFormattedString: String {
        guard isValid && !isIndefinite else { return "-:--" }

        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60

        return String(format: "%d:%02d", minutes, secs)
    }
}
