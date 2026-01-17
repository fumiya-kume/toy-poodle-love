import Foundation

extension TimeInterval {
    /// 時間を「X時間Y分」形式でフォーマットする。
    ///
    /// - 60分未満: "30分"
    /// - 60分以上: "1時間30分" または "2時間"
    ///
    /// ## 使用例
    ///
    /// ```swift
    /// let duration: TimeInterval = 5400  // 90分
    /// print(duration.formattedDuration)  // "1時間30分"
    /// ```
    var formattedDuration: String {
        let minutes = Int(self / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)時間\(remainingMinutes)分"
            } else {
                return "\(hours)時間"
            }
        } else {
            return "\(minutes)分"
        }
    }
}
