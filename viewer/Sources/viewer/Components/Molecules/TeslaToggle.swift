// Tesla Dashboard UI - Toggle for Viewer App
// カスタムトグルコンポーネント
// 設定画面用

import SwiftUI

// MARK: - Tesla Toggle

/// Tesla風カスタムトグル
struct TeslaToggle: View {
    // MARK: - Properties

    @Binding var isOn: Bool
    let label: String
    var subtitle: String? = nil

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        HStack {
            // Label
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(TeslaTypography.bodyLarge)
                    .foregroundStyle(TeslaColors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(TeslaTypography.bodySmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                }
            }

            Spacer()

            // Toggle Switch
            Button {
                withAnimation(reduceMotion ? .none : TeslaAnimation.quick) {
                    isOn.toggle()
                }
            } label: {
                ZStack {
                    // Track
                    Capsule()
                        .fill(isOn ? TeslaColors.accent : TeslaColors.surface)
                        .frame(width: 44, height: 26)
                        .overlay {
                            Capsule()
                                .stroke(
                                    isOn ? TeslaColors.accent : TeslaColors.glassBorder,
                                    lineWidth: 1
                                )
                        }

                    // Thumb
                    Circle()
                        .fill(TeslaColors.textPrimary)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(x: isOn ? 9 : -9)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "オン" : "オフ")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("ダブルタップで切り替え")
    }
}

// MARK: - Toggle Style (for standard Toggle)

/// Tesla風トグルスタイル（標準Toggle用）
struct TeslaToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            Button {
                withAnimation(reduceMotion ? .none : TeslaAnimation.quick) {
                    configuration.isOn.toggle()
                }
            } label: {
                ZStack {
                    Capsule()
                        .fill(configuration.isOn ? TeslaColors.accent : TeslaColors.surface)
                        .frame(width: 44, height: 26)
                        .overlay {
                            Capsule()
                                .stroke(
                                    configuration.isOn ? TeslaColors.accent : TeslaColors.glassBorder,
                                    lineWidth: 1
                                )
                        }

                    Circle()
                        .fill(TeslaColors.textPrimary)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(x: configuration.isOn ? 9 : -9)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

extension ToggleStyle where Self == TeslaToggleStyle {
    /// Tesla風トグルスタイル
    static var tesla: TeslaToggleStyle { TeslaToggleStyle() }
}

// MARK: - Preview

#Preview("Tesla Toggle") {
    struct TogglePreview: View {
        @State private var autoPlay = true
        @State private var showControls = true
        @State private var darkMode = true

        var body: some View {
            VStack(spacing: 24) {
                // Custom Toggle
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tesla Toggle")
                        .font(TeslaTypography.headlineSmall)
                        .foregroundStyle(TeslaColors.textPrimary)

                    TeslaToggle(
                        isOn: $autoPlay,
                        label: "Auto-play on launch",
                        subtitle: "Start playback automatically when a video is loaded"
                    )

                    TeslaToggle(
                        isOn: $showControls,
                        label: "Show controls on hover"
                    )
                }
                .padding()
                .teslaCard()

                Divider()
                    .background(TeslaColors.glassBorder)

                // Standard Toggle with Tesla Style
                VStack(alignment: .leading, spacing: 16) {
                    Text("Toggle Style")
                        .font(TeslaTypography.headlineSmall)
                        .foregroundStyle(TeslaColors.textPrimary)

                    Toggle("Dark Mode", isOn: $darkMode)
                        .toggleStyle(.tesla)
                        .font(TeslaTypography.bodyLarge)
                        .foregroundStyle(TeslaColors.textPrimary)
                }
                .padding()
                .teslaCard()

                Spacer()
            }
            .padding(24)
            .background(TeslaColors.background)
        }
    }

    return TogglePreview()
}
