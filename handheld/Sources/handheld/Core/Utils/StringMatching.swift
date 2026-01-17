import Foundation

/// 文字列マッチングユーティリティ
enum StringMatching {
    /// Levenshtein距離を計算
    /// - Parameters:
    ///   - s1: 比較元の文字列
    ///   - s2: 比較先の文字列
    /// - Returns: 編集距離
    static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1.lowercased())
        let s2 = Array(s2.lowercased())

        let m = s1.count
        let n = s2.count

        // 空文字列の場合
        if m == 0 { return n }
        if n == 0 { return m }

        var dist = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { dist[i][0] = i }
        for j in 0...n { dist[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = s1[i - 1] == s2[j - 1] ? 0 : 1
                dist[i][j] = min(
                    dist[i - 1][j] + 1,      // 削除
                    dist[i - 1][j - 1] + cost, // 置換
                    dist[i][j - 1] + 1       // 挿入
                )
            }
        }

        return dist[m][n]
    }

    /// 類似度スコアを計算 (0.0 - 1.0)
    /// - Parameters:
    ///   - s1: 比較元の文字列
    ///   - s2: 比較先の文字列
    /// - Returns: 類似度スコア (1.0 = 完全一致, 0.0 = 完全不一致)
    static func similarityScore(_ s1: String, _ s2: String) -> Double {
        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        guard maxLength > 0 else { return 1.0 }
        return 1.0 - (Double(distance) / Double(maxLength))
    }

    /// 文字列を正規化する (記号除去、小文字化)
    /// - Parameter string: 正規化する文字列
    /// - Returns: 正規化された文字列
    static func normalize(_ string: String) -> String {
        string
            .lowercased()
            .replacingOccurrences(
                of: "[\\s\\-\\_\\.\\(\\)\\[\\]「」『』【】（）]",
                with: "",
                options: .regularExpression
            )
    }

    /// 2つの文字列がファジーマッチするかを判定
    /// - Parameters:
    ///   - s1: 比較元の文字列
    ///   - s2: 比較先の文字列
    ///   - threshold: 類似度の閾値 (デフォルト: 0.7)
    /// - Returns: マッチする場合は true
    static func fuzzyMatch(_ s1: String, _ s2: String, threshold: Double = 0.7) -> Bool {
        let normalizedS1 = normalize(s1)
        let normalizedS2 = normalize(s2)
        return similarityScore(normalizedS1, normalizedS2) >= threshold
    }
}
