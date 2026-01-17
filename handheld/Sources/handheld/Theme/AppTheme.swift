import SwiftUI

enum AppTheme {
    // トイプードルをイメージした暖かい色調
    static let primaryColor = Color(red: 0.8, green: 0.52, blue: 0.42)      // アプリコット
    static let secondaryColor = Color(red: 0.96, green: 0.87, blue: 0.82)   // クリーム
    static let accentColor = Color(red: 0.55, green: 0.36, blue: 0.32)      // ブラウン

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [secondaryColor.opacity(0.6), Color(uiColor: .systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
