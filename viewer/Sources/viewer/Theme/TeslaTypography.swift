// Tesla Dashboard UI - Typography for Viewer App
// macOS 14.0+ 向けタイポグラフィスケール（デスクトップ向けに調整）

import SwiftUI

// MARK: - Tesla Typography

/// Tesla Dashboard UI のタイポグラフィスケール
/// macOS向けに調整された高視認性フォント
enum TeslaTypography {

    // MARK: - Display (時間・数値表示用)

    /// Display Large - 36pt Regular (時間表示)
    static let displayLarge = Font.system(size: 36, weight: .regular, design: .default)

    /// Display Medium - 28pt Regular
    static let displayMedium = Font.system(size: 28, weight: .regular, design: .default)

    /// Display Small - 22pt Regular
    static let displaySmall = Font.system(size: 22, weight: .regular, design: .default)

    // MARK: - Headline (セクション見出し)

    /// Headline Large - 24pt Semibold
    static let headlineLarge = Font.system(size: 24, weight: .semibold, design: .default)

    /// Headline Medium - 20pt Semibold
    static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)

    /// Headline Small - 18pt Semibold
    static let headlineSmall = Font.system(size: 18, weight: .semibold, design: .default)

    // MARK: - Title (サブセクション)

    /// Title Large - 18pt Medium
    static let titleLarge = Font.system(size: 18, weight: .medium, design: .default)

    /// Title Medium - 16pt Medium
    static let titleMedium = Font.system(size: 16, weight: .medium, design: .default)

    /// Title Small - 14pt Medium
    static let titleSmall = Font.system(size: 14, weight: .medium, design: .default)

    // MARK: - Body (本文)

    /// Body Large - 14pt Regular
    static let bodyLarge = Font.system(size: 14, weight: .regular, design: .default)

    /// Body Medium - 13pt Regular
    static let bodyMedium = Font.system(size: 13, weight: .regular, design: .default)

    /// Body Small - 12pt Regular
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Label (ボタン・ラベル)

    /// Label Large - 13pt Medium
    static let labelLarge = Font.system(size: 13, weight: .medium, design: .default)

    /// Label Medium - 12pt Medium
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)

    /// Label Small - 11pt Medium
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Monospaced (数値・時間表示)

    /// Monospaced Large - 36pt Regular Monospaced
    static let monospacedLarge = Font.system(size: 36, weight: .regular, design: .monospaced)

    /// Monospaced Medium - 22pt Regular Monospaced
    static let monospacedMedium = Font.system(size: 22, weight: .regular, design: .monospaced)

    /// Monospaced Small - 14pt Regular Monospaced
    static let monospacedSmall = Font.system(size: 14, weight: .regular, design: .monospaced)
}

// MARK: - Typography Scheme

/// テーマで使用するタイポグラフィスキーム
struct TeslaTypographyScheme: Sendable {
    let displayLarge: Font
    let displayMedium: Font
    let displaySmall: Font
    let headlineLarge: Font
    let headlineMedium: Font
    let headlineSmall: Font
    let titleLarge: Font
    let titleMedium: Font
    let titleSmall: Font
    let bodyLarge: Font
    let bodyMedium: Font
    let bodySmall: Font
    let labelLarge: Font
    let labelMedium: Font
    let labelSmall: Font

    /// デフォルトスキーム（macOS向け）
    static let `default` = TeslaTypographyScheme(
        displayLarge: TeslaTypography.displayLarge,
        displayMedium: TeslaTypography.displayMedium,
        displaySmall: TeslaTypography.displaySmall,
        headlineLarge: TeslaTypography.headlineLarge,
        headlineMedium: TeslaTypography.headlineMedium,
        headlineSmall: TeslaTypography.headlineSmall,
        titleLarge: TeslaTypography.titleLarge,
        titleMedium: TeslaTypography.titleMedium,
        titleSmall: TeslaTypography.titleSmall,
        bodyLarge: TeslaTypography.bodyLarge,
        bodyMedium: TeslaTypography.bodyMedium,
        bodySmall: TeslaTypography.bodySmall,
        labelLarge: TeslaTypography.labelLarge,
        labelMedium: TeslaTypography.labelMedium,
        labelSmall: TeslaTypography.labelSmall
    )
}

// MARK: - Text Style Extensions

extension Text {
    /// Display Large スタイルを適用
    func teslaDisplayLarge() -> Text {
        self.font(TeslaTypography.displayLarge)
    }

    /// Display Medium スタイルを適用
    func teslaDisplayMedium() -> Text {
        self.font(TeslaTypography.displayMedium)
    }

    /// Display Small スタイルを適用
    func teslaDisplaySmall() -> Text {
        self.font(TeslaTypography.displaySmall)
    }

    /// Headline Large スタイルを適用
    func teslaHeadlineLarge() -> Text {
        self.font(TeslaTypography.headlineLarge)
    }

    /// Headline Medium スタイルを適用
    func teslaHeadlineMedium() -> Text {
        self.font(TeslaTypography.headlineMedium)
    }

    /// Headline Small スタイルを適用
    func teslaHeadlineSmall() -> Text {
        self.font(TeslaTypography.headlineSmall)
    }

    /// Title Large スタイルを適用
    func teslaTitleLarge() -> Text {
        self.font(TeslaTypography.titleLarge)
    }

    /// Title Medium スタイルを適用
    func teslaTitleMedium() -> Text {
        self.font(TeslaTypography.titleMedium)
    }

    /// Body Large スタイルを適用
    func teslaBodyLarge() -> Text {
        self.font(TeslaTypography.bodyLarge)
    }

    /// Body Medium スタイルを適用
    func teslaBodyMedium() -> Text {
        self.font(TeslaTypography.bodyMedium)
    }

    /// Label Large スタイルを適用
    func teslaLabelLarge() -> Text {
        self.font(TeslaTypography.labelLarge)
    }

    /// Label Small スタイルを適用
    func teslaLabelSmall() -> Text {
        self.font(TeslaTypography.labelSmall)
    }
}

// MARK: - Preview

#Preview("Tesla Typography - macOS") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // Display
            VStack(alignment: .leading, spacing: 8) {
                Text("Display")
                    .font(TeslaTypography.labelSmall)
                    .foregroundStyle(TeslaColors.textSecondary)

                Text("01:23:45")
                    .font(TeslaTypography.displayLarge)
                    .foregroundStyle(TeslaColors.textPrimary)

                Text("85%")
                    .font(TeslaTypography.displayMedium)
                    .foregroundStyle(TeslaColors.statusGreen)

                Text("340 km")
                    .font(TeslaTypography.displaySmall)
                    .foregroundStyle(TeslaColors.textPrimary)
            }

            Divider()
                .background(TeslaColors.glassBorder)

            // Headline
            VStack(alignment: .leading, spacing: 8) {
                Text("Headline")
                    .font(TeslaTypography.labelSmall)
                    .foregroundStyle(TeslaColors.textSecondary)

                Text("Video Player")
                    .font(TeslaTypography.headlineLarge)
                    .foregroundStyle(TeslaColors.textPrimary)

                Text("Scenario Writer")
                    .font(TeslaTypography.headlineMedium)
                    .foregroundStyle(TeslaColors.textPrimary)

                Text("Quick Actions")
                    .font(TeslaTypography.headlineSmall)
                    .foregroundStyle(TeslaColors.textPrimary)
            }

            Divider()
                .background(TeslaColors.glassBorder)

            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(TeslaTypography.labelSmall)
                    .foregroundStyle(TeslaColors.textSecondary)

                Text("Main Video")
                    .font(TeslaTypography.titleLarge)
                    .foregroundStyle(TeslaColors.textPrimary)

                Text("Overlay Settings")
                    .font(TeslaTypography.titleMedium)
                    .foregroundStyle(TeslaColors.textPrimary)

                Text("Playback Controls")
                    .font(TeslaTypography.titleSmall)
                    .foregroundStyle(TeslaColors.textPrimary)
            }

            Divider()
                .background(TeslaColors.glassBorder)

            // Body
            VStack(alignment: .leading, spacing: 8) {
                Text("Body")
                    .font(TeslaTypography.labelSmall)
                    .foregroundStyle(TeslaColors.textSecondary)

                Text("Drop video files here to start playback.")
                    .font(TeslaTypography.bodyLarge)
                    .foregroundStyle(TeslaColors.textPrimary)

                Text("Supported formats: MP4, MOV, M4V, MPEG4")
                    .font(TeslaTypography.bodyMedium)
                    .foregroundStyle(TeslaColors.textSecondary)

                Text("Last modified: 5 minutes ago")
                    .font(TeslaTypography.bodySmall)
                    .foregroundStyle(TeslaColors.textTertiary)
            }

            Divider()
                .background(TeslaColors.glassBorder)

            // Label
            VStack(alignment: .leading, spacing: 8) {
                Text("Label")
                    .font(TeslaTypography.labelSmall)
                    .foregroundStyle(TeslaColors.textSecondary)

                HStack(spacing: 16) {
                    Text("PLAY")
                        .font(TeslaTypography.labelLarge)
                        .foregroundStyle(TeslaColors.textPrimary)

                    Text("MUTE")
                        .font(TeslaTypography.labelMedium)
                        .foregroundStyle(TeslaColors.textPrimary)

                    Text("SYNC")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }
            }
        }
        .padding(24)
    }
    .background(TeslaColors.background)
}
