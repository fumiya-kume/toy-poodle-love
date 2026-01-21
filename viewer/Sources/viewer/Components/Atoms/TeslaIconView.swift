// Tesla Dashboard UI - Icon View for Viewer App
// SF Symbols をTeslaスタイルでレンダリング

import SwiftUI

// MARK: - Tesla Icon View

/// Teslaアイコンを表示するビュー
struct TeslaIconView: View {
    // MARK: - Properties

    let icon: TeslaIcon
    var size: CGFloat = 24
    var color: Color = TeslaColors.textPrimary

    // MARK: - Body

    var body: some View {
        Image(systemName: icon.systemName)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .accessibilityLabel(icon.accessibilityLabel)
    }
}

// MARK: - Convenience Initializers

extension TeslaIconView {
    /// システム名から直接作成
    /// - Parameters:
    ///   - systemName: SF Symbolsのシステム名
    ///   - size: アイコンサイズ
    ///   - color: アイコンカラー
    init(
        systemName: String,
        size: CGFloat = 24,
        color: Color = TeslaColors.textPrimary
    ) {
        // システム名から対応するTeslaIconを検索、見つからない場合はplayをデフォルトに
        self.icon = TeslaIcon.allCases.first { $0.systemName == systemName } ?? .play
        self.size = size
        self.color = color
    }
}

// MARK: - Size Presets

extension TeslaIconView {
    /// 小さいアイコン（16pt）
    static func small(_ icon: TeslaIcon, color: Color = TeslaColors.textPrimary) -> TeslaIconView {
        TeslaIconView(icon: icon, size: 16, color: color)
    }

    /// 中サイズアイコン（24pt）
    static func medium(_ icon: TeslaIcon, color: Color = TeslaColors.textPrimary) -> TeslaIconView {
        TeslaIconView(icon: icon, size: 24, color: color)
    }

    /// 大きいアイコン（32pt）
    static func large(_ icon: TeslaIcon, color: Color = TeslaColors.textPrimary) -> TeslaIconView {
        TeslaIconView(icon: icon, size: 32, color: color)
    }

    /// 特大アイコン（48pt）
    static func extraLarge(_ icon: TeslaIcon, color: Color = TeslaColors.textPrimary) -> TeslaIconView {
        TeslaIconView(icon: icon, size: 48, color: color)
    }
}

// MARK: - Preview

#Preview("Tesla Icon View") {
    VStack(spacing: 32) {
        // Size Variants
        VStack(alignment: .leading, spacing: 16) {
            Text("Size Variants")
                .font(TeslaTypography.headlineSmall)
                .foregroundStyle(TeslaColors.textPrimary)

            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    TeslaIconView.small(.play)
                    Text("Small (16)")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }

                VStack(spacing: 8) {
                    TeslaIconView.medium(.play)
                    Text("Medium (24)")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }

                VStack(spacing: 8) {
                    TeslaIconView.large(.play)
                    Text("Large (32)")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }

                VStack(spacing: 8) {
                    TeslaIconView.extraLarge(.play)
                    Text("XLarge (48)")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }
            }
        }

        Divider()
            .background(TeslaColors.glassBorder)

        // Color Variants
        VStack(alignment: .leading, spacing: 16) {
            Text("Color Variants")
                .font(TeslaTypography.headlineSmall)
                .foregroundStyle(TeslaColors.textPrimary)

            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    TeslaIconView(icon: .play, color: TeslaColors.textPrimary)
                    Text("Primary")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }

                VStack(spacing: 8) {
                    TeslaIconView(icon: .play, color: TeslaColors.accent)
                    Text("Accent")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }

                VStack(spacing: 8) {
                    TeslaIconView(icon: .play, color: TeslaColors.statusGreen)
                    Text("Green")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }

                VStack(spacing: 8) {
                    TeslaIconView(icon: .play, color: TeslaColors.statusOrange)
                    Text("Orange")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }

                VStack(spacing: 8) {
                    TeslaIconView(icon: .play, color: TeslaColors.statusRed)
                    Text("Red")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }
            }
        }

        Divider()
            .background(TeslaColors.glassBorder)

        // Playback Icons
        VStack(alignment: .leading, spacing: 16) {
            Text("Playback Controls")
                .font(TeslaTypography.headlineSmall)
                .foregroundStyle(TeslaColors.textPrimary)

            HStack(spacing: 20) {
                TeslaIconView(icon: .goToBeginning, color: TeslaColors.textSecondary)
                TeslaIconView(icon: .skipBackward, color: TeslaColors.textPrimary)
                TeslaIconView(icon: .play, size: 32, color: TeslaColors.accent)
                TeslaIconView(icon: .skipForward, color: TeslaColors.textPrimary)
                TeslaIconView(icon: .goToEnd, color: TeslaColors.textSecondary)
            }
        }
    }
    .padding(24)
    .background(TeslaColors.background)
}
