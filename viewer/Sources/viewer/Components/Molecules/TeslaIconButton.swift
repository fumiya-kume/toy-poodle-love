// Tesla Dashboard UI - Icon Button for Viewer App
// ガラスモーフィズム効果のアイコンボタン
// macOS向けホバーエフェクト対応

import SwiftUI

// MARK: - Tesla Icon Button

/// Tesla風アイコンボタン
/// ガラスモーフィズム効果と押下時のスケールアニメーション、ホバーエフェクト付き
struct TeslaIconButton: View {
    // MARK: - Properties

    let icon: TeslaIcon
    var label: String? = nil
    var isSelected: Bool = false
    var isDisabled: Bool = false
    var size: TeslaIconButtonSize = .medium
    var showLabel: Bool = false
    let action: () -> Void

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            VStack(spacing: size.labelSpacing) {
                // Icon Container
                ZStack {
                    // Background
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: size.circleSize, height: size.circleSize)

                    // Border (when not selected)
                    if !isSelected && !isHovered {
                        Circle()
                            .stroke(TeslaColors.glassBorder, lineWidth: 1)
                            .frame(width: size.circleSize, height: size.circleSize)
                    }

                    // Hover highlight
                    if isHovered && !isSelected {
                        Circle()
                            .fill(TeslaColors.glassBackgroundElevated)
                            .frame(width: size.circleSize, height: size.circleSize)
                    }

                    // Icon
                    TeslaIconView(
                        icon: icon,
                        size: size.iconSize,
                        color: iconColor
                    )
                }

                // Label (optional)
                if showLabel, let label = label {
                    Text(label)
                        .font(size.labelFont)
                        .foregroundStyle(labelColor)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(TeslaIconButtonStyle(reduceMotion: reduceMotion))
        .disabled(isDisabled)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(label ?? icon.accessibilityLabel)
        .accessibilityHint(isSelected ? "選択済み" : "ダブルタップで選択")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        if isDisabled {
            return TeslaColors.glassBackground.opacity(0.5)
        }
        return isSelected ? TeslaColors.accent : TeslaColors.glassBackground
    }

    private var iconColor: Color {
        if isDisabled {
            return TeslaColors.textDisabled
        }
        return isSelected ? .white : TeslaColors.textSecondary
    }

    private var labelColor: Color {
        if isDisabled {
            return TeslaColors.textDisabled
        }
        return isSelected ? TeslaColors.accent : TeslaColors.textSecondary
    }
}

// MARK: - Button Size

/// アイコンボタンのサイズ
enum TeslaIconButtonSize {
    case small
    case medium
    case large

    var circleSize: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 44
        case .large: return 56
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 18
        case .large: return 24
        }
    }

    var labelSpacing: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }

    var labelFont: Font {
        switch self {
        case .small: return TeslaTypography.labelSmall
        case .medium: return TeslaTypography.labelSmall
        case .large: return TeslaTypography.labelMedium
        }
    }
}

// MARK: - Button Style

/// Tesla風ボタンスタイル
struct TeslaIconButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(
                reduceMotion ? .none : TeslaAnimation.quick,
                value: configuration.isPressed
            )
    }
}

// MARK: - Convenience Initializers

extension TeslaIconButton {
    /// 基本的な初期化（ラベルなし）
    init(
        icon: TeslaIcon,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = nil
        self.isSelected = false
        self.isDisabled = false
        self.size = .medium
        self.showLabel = false
        self.action = action
    }

    /// 選択状態を指定して初期化
    init(
        icon: TeslaIcon,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = nil
        self.isSelected = isSelected
        self.isDisabled = false
        self.size = .medium
        self.showLabel = false
        self.action = action
    }

    /// サイズを指定して初期化
    init(
        icon: TeslaIcon,
        size: TeslaIconButtonSize,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = nil
        self.isSelected = false
        self.isDisabled = false
        self.size = size
        self.showLabel = false
        self.action = action
    }
}

// MARK: - Preview

#Preview("Tesla Icon Button") {
    struct IconButtonPreview: View {
        @State private var selectedIndex: Int? = 0

        let items: [(icon: TeslaIcon, label: String)] = [
            (.play, "再生"),
            (.pause, "停止"),
            (.skipBackward, "戻る"),
            (.skipForward, "進む"),
            (.volumeOn, "音量"),
            (.sync, "同期")
        ]

        var body: some View {
            VStack(spacing: 32) {
                // Size Variants
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sizes")
                        .font(TeslaTypography.headlineSmall)
                        .foregroundStyle(TeslaColors.textPrimary)

                    HStack(spacing: 24) {
                        TeslaIconButton(
                            icon: .play,
                            label: "Small",
                            size: .small,
                            showLabel: true
                        ) {}

                        TeslaIconButton(
                            icon: .play,
                            label: "Medium",
                            size: .medium,
                            showLabel: true
                        ) {}

                        TeslaIconButton(
                            icon: .play,
                            label: "Large",
                            size: .large,
                            showLabel: true
                        ) {}
                    }
                }

                Divider()
                    .background(TeslaColors.glassBorder)

                // States
                VStack(alignment: .leading, spacing: 16) {
                    Text("States")
                        .font(TeslaTypography.headlineSmall)
                        .foregroundStyle(TeslaColors.textPrimary)

                    HStack(spacing: 24) {
                        TeslaIconButton(
                            icon: .play,
                            label: "Default",
                            showLabel: true
                        ) {}

                        TeslaIconButton(
                            icon: .play,
                            label: "Selected",
                            isSelected: true,
                            showLabel: true
                        ) {}

                        TeslaIconButton(
                            icon: .play,
                            label: "Disabled",
                            isDisabled: true,
                            showLabel: true
                        ) {}
                    }
                }

                Divider()
                    .background(TeslaColors.glassBorder)

                // Playback Controls (No Labels)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Video Controls (Icon Only)")
                        .font(TeslaTypography.headlineSmall)
                        .foregroundStyle(TeslaColors.textPrimary)

                    HStack(spacing: 12) {
                        ForEach(items.indices, id: \.self) { index in
                            TeslaIconButton(
                                icon: items[index].icon,
                                isSelected: selectedIndex == index,
                                size: index == 0 ? .large : .medium
                            ) {
                                selectedIndex = index
                            }
                        }
                    }
                }
            }
            .padding(24)
            .background(TeslaColors.background)
        }
    }

    return IconButtonPreview()
}
