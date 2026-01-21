// Tesla Dashboard UI - Loading Spinner for Viewer App
// カスタムローディングスピナー
// Reduce Motion対応

import SwiftUI

// MARK: - Tesla Loading Spinner

/// Tesla風ローディングスピナー
struct TeslaLoadingSpinner: View {
    // MARK: - Properties

    var size: CGFloat = 32
    var color: Color = TeslaColors.accent
    var lineWidth: CGFloat = 3
    var label: String? = nil

    // MARK: - State

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background Circle
                Circle()
                    .stroke(
                        TeslaColors.surface,
                        lineWidth: lineWidth
                    )
                    .frame(width: size, height: size)

                // Animated Arc
                Circle()
                    .trim(from: 0, to: reduceMotion ? 1.0 : 0.7)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(reduceMotion ? 0 : (isAnimating ? 360 : 0)))
                    .animation(
                        reduceMotion ? .none : Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }

            // Label
            if let label = label {
                Text(label)
                    .font(TeslaTypography.labelMedium)
                    .foregroundStyle(TeslaColors.textSecondary)
            }
        }
        .onAppear {
            if !reduceMotion {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "読み込み中")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Size Presets

extension TeslaLoadingSpinner {
    /// 小さいスピナー（16pt）
    static var small: TeslaLoadingSpinner {
        TeslaLoadingSpinner(size: 16, lineWidth: 2)
    }

    /// 中サイズスピナー（32pt）
    static var medium: TeslaLoadingSpinner {
        TeslaLoadingSpinner(size: 32, lineWidth: 3)
    }

    /// 大きいスピナー（48pt）
    static var large: TeslaLoadingSpinner {
        TeslaLoadingSpinner(size: 48, lineWidth: 4)
    }

    /// ラベル付きスピナー
    static func withLabel(_ label: String, size: CGFloat = 32) -> TeslaLoadingSpinner {
        TeslaLoadingSpinner(size: size, label: label)
    }
}

// MARK: - Loading Overlay

/// ローディングオーバーレイ
struct TeslaLoadingOverlay: View {
    var label: String? = nil
    var isPresented: Bool = true

    var body: some View {
        if isPresented {
            ZStack {
                // Background Blur
                TeslaColors.background.opacity(0.8)
                    .ignoresSafeArea()

                // Spinner
                VStack(spacing: 16) {
                    TeslaLoadingSpinner.large

                    if let label = label {
                        Text(label)
                            .font(TeslaTypography.bodyMedium)
                            .foregroundStyle(TeslaColors.textPrimary)
                    }
                }
                .padding(32)
                .teslaGlassmorphism()
            }
            .transition(.opacity)
        }
    }
}

// MARK: - View Extension

extension View {
    /// ローディングオーバーレイを表示
    func teslaLoadingOverlay(
        isPresented: Bool,
        label: String? = nil
    ) -> some View {
        ZStack {
            self
            TeslaLoadingOverlay(label: label, isPresented: isPresented)
        }
    }
}

// MARK: - Preview

#Preview("Tesla Loading Spinner") {
    VStack(spacing: 40) {
        // Size Variants
        VStack(alignment: .leading, spacing: 24) {
            Text("Size Variants")
                .font(TeslaTypography.headlineSmall)
                .foregroundStyle(TeslaColors.textPrimary)

            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    TeslaLoadingSpinner.small
                    Text("Small")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }

                VStack(spacing: 8) {
                    TeslaLoadingSpinner.medium
                    Text("Medium")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }

                VStack(spacing: 8) {
                    TeslaLoadingSpinner.large
                    Text("Large")
                        .font(TeslaTypography.labelSmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }
            }
        }

        Divider()
            .background(TeslaColors.glassBorder)

        // Color Variants
        VStack(alignment: .leading, spacing: 24) {
            Text("Color Variants")
                .font(TeslaTypography.headlineSmall)
                .foregroundStyle(TeslaColors.textPrimary)

            HStack(spacing: 40) {
                TeslaLoadingSpinner(color: TeslaColors.accent)
                TeslaLoadingSpinner(color: TeslaColors.statusGreen)
                TeslaLoadingSpinner(color: TeslaColors.statusOrange)
            }
        }

        Divider()
            .background(TeslaColors.glassBorder)

        // With Label
        VStack(alignment: .leading, spacing: 24) {
            Text("With Label")
                .font(TeslaTypography.headlineSmall)
                .foregroundStyle(TeslaColors.textPrimary)

            TeslaLoadingSpinner.withLabel("Loading...")
        }
    }
    .padding(24)
    .background(TeslaColors.background)
}
