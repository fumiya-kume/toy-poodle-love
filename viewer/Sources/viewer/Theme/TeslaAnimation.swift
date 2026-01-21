// Tesla Dashboard UI - Animation for Viewer App
// macOS 14.0+ 向けアニメーション設定

import SwiftUI

// MARK: - Tesla Animation

/// Tesla Dashboard UI のアニメーション設定
enum TeslaAnimation {

    // MARK: - Spring Animations

    /// 標準的なスプリングアニメーション
    static let standard = Animation.spring(response: 0.35, dampingFraction: 0.8)

    /// 素早いスプリングアニメーション（ボタン押下など） - 0.2s
    static let quick = Animation.spring(response: 0.2, dampingFraction: 0.7)

    /// ゆっくりとしたスプリングアニメーション（画面遷移など）
    static let slow = Animation.spring(response: 0.5, dampingFraction: 0.85)

    /// バウンス効果のあるスプリングアニメーション
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)

    // MARK: - Easing Animations

    /// イーズイン・アウト
    static let easeInOut = Animation.easeInOut(duration: 0.25)

    /// イーズアウト（終わりがゆっくり）
    static let easeOut = Animation.easeOut(duration: 0.25)

    /// イーズイン（始まりがゆっくり）
    static let easeIn = Animation.easeIn(duration: 0.2)

    // MARK: - Custom Curves

    /// Tesla風のカスタムイージングカーブ（素早く始まり、ゆっくり終わる）
    static let teslaEase = Animation.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 0.35)

    /// 画面展開用のカスタムカーブ
    static let expand = Animation.timingCurve(0.0, 0.0, 0.2, 1.0, duration: 0.3)

    /// 画面縮小用のカスタムカーブ
    static let collapse = Animation.timingCurve(0.4, 0.0, 1.0, 1.0, duration: 0.25)

    // MARK: - Durations

    /// 短い継続時間
    static let durationShort: Double = 0.15

    /// 標準の継続時間
    static let durationMedium: Double = 0.25

    /// 長い継続時間
    static let durationLong: Double = 0.4
}

// MARK: - Animation Scheme

/// テーマで使用するアニメーションスキーム
struct TeslaAnimationScheme: Sendable {
    let standard: Animation
    let quick: Animation
    let slow: Animation
    let bouncy: Animation

    /// デフォルトスキーム
    static let `default` = TeslaAnimationScheme(
        standard: TeslaAnimation.standard,
        quick: TeslaAnimation.quick,
        slow: TeslaAnimation.slow,
        bouncy: TeslaAnimation.bouncy
    )

    /// Reduce Motion対応スキーム（アニメーションなし）
    static let reduced = TeslaAnimationScheme(
        standard: .linear(duration: 0),
        quick: .linear(duration: 0),
        slow: .linear(duration: 0),
        bouncy: .linear(duration: 0)
    )
}

// MARK: - Pulse Animation Modifier

/// パルスアニメーション（ローディング表示など）
struct TeslaPulseModifier: ViewModifier {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let duration: Double
    let minOpacity: Double
    let maxOpacity: Double

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? maxOpacity : (isAnimating ? maxOpacity : minOpacity))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    /// パルスアニメーションを適用
    /// - Parameters:
    ///   - duration: 1サイクルの時間
    ///   - minOpacity: 最小不透明度
    ///   - maxOpacity: 最大不透明度
    func teslaPulse(
        duration: Double = 1.0,
        minOpacity: Double = 0.4,
        maxOpacity: Double = 1.0
    ) -> some View {
        modifier(TeslaPulseModifier(
            duration: duration,
            minOpacity: minOpacity,
            maxOpacity: maxOpacity
        ))
    }
}

// MARK: - Scale on Press Modifier

/// 押下時のスケールアニメーション
struct TeslaScaleOnPressModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isPressed: Bool
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1.0 : (isPressed ? scale : 1.0))
            .animation(reduceMotion ? .none : TeslaAnimation.quick, value: isPressed)
    }
}

extension View {
    /// 押下時のスケールアニメーションを適用
    /// - Parameters:
    ///   - isPressed: 押下状態
    ///   - scale: 押下時のスケール（デフォルト: 0.92）
    func teslaScaleOnPress(_ isPressed: Bool, scale: CGFloat = 0.92) -> some View {
        modifier(TeslaScaleOnPressModifier(isPressed: isPressed, scale: scale))
    }
}

// MARK: - Hover Effect Modifier (macOS)

/// ホバー時のハイライトエフェクト（macOS向け）
struct TeslaHoverModifier: ViewModifier {
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let highlightColor: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                if isHovered {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(highlightColor)
                }
            }
            .animation(reduceMotion ? .none : TeslaAnimation.quick, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    /// ホバー時のハイライトエフェクトを適用（macOS向け）
    /// - Parameters:
    ///   - highlightColor: ハイライト色（デフォルト: glassBackground）
    ///   - cornerRadius: 角丸半径（デフォルト: 8）
    func teslaHover(
        highlightColor: Color = TeslaColors.glassBackground,
        cornerRadius: CGFloat = 8
    ) -> some View {
        modifier(TeslaHoverModifier(
            highlightColor: highlightColor,
            cornerRadius: cornerRadius
        ))
    }
}

// MARK: - Button Style

/// Tesla風のボタンスタイル（スケールアニメーション付き）
struct TeslaScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? 0.92 : 1.0))
            .animation(reduceMotion ? .none : TeslaAnimation.quick, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Tesla Animations") {
    struct AnimationPreview: View {
        @State private var isExpanded = false

        var body: some View {
            ScrollView {
                VStack(spacing: 32) {
                    // Spring Animations
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Spring Animations")
                            .font(TeslaTypography.headlineSmall)
                            .foregroundStyle(TeslaColors.textPrimary)

                        Button("Toggle Expand") {
                            withAnimation(TeslaAnimation.quick) {
                                isExpanded.toggle()
                            }
                        }
                        .foregroundStyle(TeslaColors.accent)

                        RoundedRectangle(cornerRadius: 16)
                            .fill(TeslaColors.surface)
                            .frame(height: isExpanded ? 200 : 80)
                            .overlay {
                                Text(isExpanded ? "Expanded" : "Collapsed")
                                    .foregroundStyle(TeslaColors.textPrimary)
                            }
                    }

                    Divider()
                        .background(TeslaColors.glassBorder)

                    // Scale on Press
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Scale Button")
                            .font(TeslaTypography.headlineSmall)
                            .foregroundStyle(TeslaColors.textPrimary)

                        Button {
                            // Action
                        } label: {
                            Text("Hold Me")
                                .font(TeslaTypography.labelLarge)
                                .foregroundStyle(TeslaColors.textPrimary)
                                .padding()
                                .teslaGlassmorphism()
                        }
                        .buttonStyle(TeslaScaleButtonStyle())
                    }

                    Divider()
                        .background(TeslaColors.glassBorder)

                    // Pulse Animation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pulse Animation")
                            .font(TeslaTypography.headlineSmall)
                            .foregroundStyle(TeslaColors.textPrimary)

                        HStack(spacing: 16) {
                            Circle()
                                .fill(TeslaColors.accent)
                                .frame(width: 20, height: 20)
                                .teslaPulse()

                            Text("Loading...")
                                .font(TeslaTypography.bodyMedium)
                                .foregroundStyle(TeslaColors.accent)
                        }
                    }

                    Divider()
                        .background(TeslaColors.glassBorder)

                    // Hover Effect
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hover Effect (macOS)")
                            .font(TeslaTypography.headlineSmall)
                            .foregroundStyle(TeslaColors.textPrimary)

                        HStack(spacing: 8) {
                            ForEach(["Item 1", "Item 2", "Item 3"], id: \.self) { item in
                                Text(item)
                                    .font(TeslaTypography.bodyMedium)
                                    .foregroundStyle(TeslaColors.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .teslaHover()
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(TeslaColors.background)
        }
    }

    return AnimationPreview()
}
