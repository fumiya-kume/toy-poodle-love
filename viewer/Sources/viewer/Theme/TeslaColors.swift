// Tesla Dashboard UI - Color Palette for Viewer App
// macOS 14.0+ (Sonoma) 向けダークテーマカラーパレット

import SwiftUI

// MARK: - Tesla Colors

/// Tesla Dashboard UI のカラーパレット
/// ダークテーマ専用で、高コントラスト・高視認性を実現
enum TeslaColors {

    // MARK: - Background Colors

    /// メイン背景色 (#141416)
    static let background = Color(red: 0.078, green: 0.078, blue: 0.086)

    /// カード・パネル背景色 (#1E1E22)
    static let surface = Color(red: 0.118, green: 0.118, blue: 0.133)

    /// 浮き上がった要素の背景色 (#28282C)
    static let surfaceElevated = Color(red: 0.157, green: 0.157, blue: 0.173)

    // MARK: - Accent Colors

    /// Tesla Blue - 主要アクション色・メインビデオ (#3399FF)
    static let accent = Color(red: 0.2, green: 0.6, blue: 1.0)

    /// 正常ステータス (#4DD966)
    static let statusGreen = Color(red: 0.302, green: 0.851, blue: 0.400)

    /// オーバーレイビデオ・注意喚起 (#FF9933)
    static let statusOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    /// エラー・緊急 (#F24D4D)
    static let statusRed = Color(red: 0.949, green: 0.302, blue: 0.302)

    // MARK: - Text Colors

    /// メインテキスト (#FFFFFF)
    static let textPrimary = Color.white

    /// サブテキスト (#B3B3B3)
    static let textSecondary = Color(white: 0.7)

    /// 補助テキスト (#808080)
    static let textTertiary = Color(white: 0.5)

    /// 無効テキスト (#4D4D4D)
    static let textDisabled = Color(white: 0.3)

    // MARK: - Glassmorphism

    /// ガラスモーフィズム背景 (#FFFFFF with 8% opacity)
    static let glassBackground = Color.white.opacity(0.08)

    /// ガラスモーフィズム背景（強調） (#FFFFFF with 16% opacity)
    static let glassBackgroundElevated = Color.white.opacity(0.16)

    /// ガラスモーフィズム境界線 (#FFFFFF with 12% opacity)
    static let glassBorder = Color.white.opacity(0.12)

    // MARK: - Semantic Colors (Video Player)

    /// メインビデオ進捗バー
    static let mainVideoColor = accent

    /// オーバーレイビデオ進捗バー
    static let overlayVideoColor = statusOrange
}

// MARK: - Color Scheme

/// テーマで使用するカラースキーム
struct TeslaColorScheme: Sendable {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let accent: Color
    let statusGreen: Color
    let statusOrange: Color
    let statusRed: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let glassBackground: Color
    let glassBorder: Color

    /// ダークテーマ（デフォルト）
    static let dark = TeslaColorScheme(
        background: TeslaColors.background,
        surface: TeslaColors.surface,
        surfaceElevated: TeslaColors.surfaceElevated,
        accent: TeslaColors.accent,
        statusGreen: TeslaColors.statusGreen,
        statusOrange: TeslaColors.statusOrange,
        statusRed: TeslaColors.statusRed,
        textPrimary: TeslaColors.textPrimary,
        textSecondary: TeslaColors.textSecondary,
        textTertiary: TeslaColors.textTertiary,
        glassBackground: TeslaColors.glassBackground,
        glassBorder: TeslaColors.glassBorder
    )
}

// MARK: - Glassmorphism Modifier

/// ガラスモーフィズム効果を適用するViewModifier
struct TeslaGlassmorphismModifier: ViewModifier {
    var opacity: CGFloat = 0.16
    var cornerRadius: CGFloat = 16
    var showBorder: Bool = true

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(opacity))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if showBorder {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(TeslaColors.glassBorder, lineWidth: 1)
                }
            }
    }
}

extension View {
    /// ガラスモーフィズム効果を適用
    /// - Parameters:
    ///   - opacity: 背景の不透明度（デフォルト: 0.16）
    ///   - cornerRadius: 角丸半径（デフォルト: 16）
    ///   - showBorder: 境界線を表示するか（デフォルト: true）
    func teslaGlassmorphism(
        opacity: CGFloat = 0.16,
        cornerRadius: CGFloat = 16,
        showBorder: Bool = true
    ) -> some View {
        modifier(TeslaGlassmorphismModifier(
            opacity: opacity,
            cornerRadius: cornerRadius,
            showBorder: showBorder
        ))
    }
}

// MARK: - Preview

#Preview("Tesla Colors") {
    ScrollView {
        VStack(spacing: 24) {
            // Background Colors
            VStack(alignment: .leading, spacing: 12) {
                Text("Background Colors")
                    .font(.headline)
                    .foregroundStyle(TeslaColors.textPrimary)

                HStack(spacing: 12) {
                    ColorSwatch(color: TeslaColors.background, name: "Background")
                    ColorSwatch(color: TeslaColors.surface, name: "Surface")
                    ColorSwatch(color: TeslaColors.surfaceElevated, name: "Elevated")
                }
            }

            // Accent Colors
            VStack(alignment: .leading, spacing: 12) {
                Text("Accent Colors")
                    .font(.headline)
                    .foregroundStyle(TeslaColors.textPrimary)

                HStack(spacing: 12) {
                    ColorSwatch(color: TeslaColors.accent, name: "Accent")
                    ColorSwatch(color: TeslaColors.statusGreen, name: "Green")
                    ColorSwatch(color: TeslaColors.statusOrange, name: "Orange")
                    ColorSwatch(color: TeslaColors.statusRed, name: "Red")
                }
            }

            // Video Colors
            VStack(alignment: .leading, spacing: 12) {
                Text("Video Colors")
                    .font(.headline)
                    .foregroundStyle(TeslaColors.textPrimary)

                HStack(spacing: 12) {
                    ColorSwatch(color: TeslaColors.mainVideoColor, name: "Main")
                    ColorSwatch(color: TeslaColors.overlayVideoColor, name: "Overlay")
                }
            }

            // Glassmorphism
            VStack(alignment: .leading, spacing: 12) {
                Text("Glassmorphism")
                    .font(.headline)
                    .foregroundStyle(TeslaColors.textPrimary)

                HStack {
                    Text("Glassmorphism Effect")
                        .foregroundStyle(TeslaColors.textPrimary)
                        .padding()
                        .teslaGlassmorphism()
                }
            }
        }
        .padding(24)
    }
    .background(TeslaColors.background)
}

// Helper view for preview
private struct ColorSwatch: View {
    let color: Color
    let name: String

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(TeslaColors.glassBorder, lineWidth: 1)
                }

            Text(name)
                .font(.caption2)
                .foregroundStyle(TeslaColors.textSecondary)
        }
    }
}
