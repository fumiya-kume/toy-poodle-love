// Tesla Dashboard UI - Slider for Viewer App
// カスタムスライダーコンポーネント
// 不透明度・音量コントロール用

import SwiftUI

// MARK: - Tesla Slider

/// Tesla風カスタムスライダー
struct TeslaSlider: View {
    // MARK: - Properties

    @Binding var value: Double
    let range: ClosedRange<Double>
    var icon: TeslaIcon? = nil
    var label: String? = nil
    var valueFormatter: ((Double) -> String)? = nil

    // MARK: - State

    @State private var isDragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label and Value
            if label != nil || valueFormatter != nil {
                HStack {
                    if let icon = icon {
                        TeslaIconView(icon: icon, size: 16, color: TeslaColors.textSecondary)
                    }

                    if let label = label {
                        Text(label)
                            .font(TeslaTypography.labelMedium)
                            .foregroundStyle(TeslaColors.textSecondary)
                    }

                    Spacer()

                    if let formatter = valueFormatter {
                        Text(formatter(value))
                            .font(TeslaTypography.labelMedium)
                            .foregroundStyle(TeslaColors.textPrimary)
                    }
                }
            }

            // Slider Track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background Track
                    Capsule()
                        .fill(TeslaColors.surface)
                        .frame(height: 8)

                    // Filled Track
                    Capsule()
                        .fill(TeslaColors.accent)
                        .frame(width: filledWidth(for: geometry.size.width), height: 8)

                    // Thumb
                    Circle()
                        .fill(TeslaColors.textPrimary)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .offset(x: thumbOffset(for: geometry.size.width))
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .animation(
                            reduceMotion ? .none : TeslaAnimation.quick,
                            value: isDragging
                        )
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            updateValue(for: gesture.location.x, width: geometry.size.width)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 24)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "スライダー")
        .accessibilityValue(valueFormatter?(value) ?? "\(Int(value * 100))%")
        .accessibilityAdjustableAction { direction in
            let step = (range.upperBound - range.lowerBound) / 10
            switch direction {
            case .increment:
                value = min(value + step, range.upperBound)
            case .decrement:
                value = max(value - step, range.lowerBound)
            @unknown default:
                break
            }
        }
    }

    // MARK: - Computed Properties

    private var thumbSize: CGFloat { 20 }

    private func normalizedValue() -> Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    private func filledWidth(for totalWidth: CGFloat) -> CGFloat {
        let normalized = normalizedValue()
        return max(0, min(totalWidth, CGFloat(normalized) * totalWidth))
    }

    private func thumbOffset(for totalWidth: CGFloat) -> CGFloat {
        let normalized = normalizedValue()
        let trackWidth = totalWidth - thumbSize
        return CGFloat(normalized) * trackWidth
    }

    private func updateValue(for x: CGFloat, width: CGFloat) {
        let halfThumb = thumbSize / 2
        // サムの中心の有効範囲: [halfThumb, width - halfThumb]
        let minCenter = halfThumb
        let maxCenter = width - halfThumb
        let clampedCenter = max(minCenter, min(maxCenter, x))
        // 正規化: 0.0 ~ 1.0
        let normalized = (clampedCenter - minCenter) / (maxCenter - minCenter)
        value = range.lowerBound + Double(normalized) * (range.upperBound - range.lowerBound)
    }
}

// MARK: - Convenience Initializers

extension TeslaSlider {
    /// パーセント表示スライダー
    static func percentage(
        value: Binding<Double>,
        label: String? = nil,
        icon: TeslaIcon? = nil
    ) -> TeslaSlider {
        TeslaSlider(
            value: value,
            range: 0...1,
            icon: icon,
            label: label,
            valueFormatter: { "\(Int($0 * 100))%" }
        )
    }
}

// MARK: - Preview

#Preview("Tesla Slider") {
    struct SliderPreview: View {
        @State private var opacity: Double = 0.5
        @State private var volume: Double = 0.7
        @State private var progress: Double = 0.3

        var body: some View {
            VStack(spacing: 32) {
                // Opacity Slider
                VStack(alignment: .leading, spacing: 16) {
                    Text("Opacity Control")
                        .font(TeslaTypography.headlineSmall)
                        .foregroundStyle(TeslaColors.textPrimary)

                    TeslaSlider.percentage(
                        value: $opacity,
                        label: "Overlay Opacity",
                        icon: .opacity
                    )
                }

                Divider()
                    .background(TeslaColors.glassBorder)

                // Volume Slider
                VStack(alignment: .leading, spacing: 16) {
                    Text("Volume Control")
                        .font(TeslaTypography.headlineSmall)
                        .foregroundStyle(TeslaColors.textPrimary)

                    TeslaSlider.percentage(
                        value: $volume,
                        label: "Volume",
                        icon: .volumeOn
                    )
                }

                Divider()
                    .background(TeslaColors.glassBorder)

                // Simple Slider
                VStack(alignment: .leading, spacing: 16) {
                    Text("Simple Slider")
                        .font(TeslaTypography.headlineSmall)
                        .foregroundStyle(TeslaColors.textPrimary)

                    TeslaSlider(
                        value: $progress,
                        range: 0...1
                    )
                }

                Spacer()
            }
            .padding(24)
            .background(TeslaColors.background)
        }
    }

    return SliderPreview()
}
