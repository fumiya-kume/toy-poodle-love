// Tesla Dashboard UI - Alert Card for Viewer App
// エラー・警告表示用カード
// アクセシビリティ対応

import SwiftUI

// MARK: - Alert Type

/// アラートの種類
enum TeslaAlertType: Sendable {
    case info
    case success
    case warning
    case error

    var icon: TeslaIcon {
        switch self {
        case .info: return .info
        case .success: return .checkmark
        case .warning: return .warning
        case .error: return .error
        }
    }

    var color: Color {
        switch self {
        case .info: return TeslaColors.accent
        case .success: return TeslaColors.statusGreen
        case .warning: return TeslaColors.statusOrange
        case .error: return TeslaColors.statusRed
        }
    }

    var accessibilityPrefix: String {
        switch self {
        case .info: return "情報"
        case .success: return "成功"
        case .warning: return "警告"
        case .error: return "エラー"
        }
    }
}

// MARK: - Tesla Alert Card

/// Tesla風アラートカード
struct TeslaAlertCard: View {
    // MARK: - Properties

    let type: TeslaAlertType
    let title: String
    var message: String? = nil
    var onDismiss: (() -> Void)? = nil

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            TeslaIconView(icon: type.icon, size: 20, color: type.color)
                .padding(.top, 2)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(TeslaTypography.titleSmall)
                    .foregroundStyle(TeslaColors.textPrimary)

                if let message = message {
                    Text(message)
                        .font(TeslaTypography.bodySmall)
                        .foregroundStyle(TeslaColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            // Dismiss Button
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    TeslaIconView(icon: .close, size: 16, color: TeslaColors.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("閉じる")
            }
        }
        .padding(16)
        .background(type.color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.accessibilityPrefix): \(title)")
        .accessibilityValue(message ?? "")
    }
}

// MARK: - Convenience Initializers

extension TeslaAlertCard {
    /// エラーアラート
    static func error(
        title: String,
        message: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> TeslaAlertCard {
        TeslaAlertCard(
            type: .error,
            title: title,
            message: message,
            onDismiss: onDismiss
        )
    }

    /// 警告アラート
    static func warning(
        title: String,
        message: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> TeslaAlertCard {
        TeslaAlertCard(
            type: .warning,
            title: title,
            message: message,
            onDismiss: onDismiss
        )
    }

    /// 成功アラート
    static func success(
        title: String,
        message: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> TeslaAlertCard {
        TeslaAlertCard(
            type: .success,
            title: title,
            message: message,
            onDismiss: onDismiss
        )
    }

    /// 情報アラート
    static func info(
        title: String,
        message: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> TeslaAlertCard {
        TeslaAlertCard(
            type: .info,
            title: title,
            message: message,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Alert Modifier

/// アラートを表示するViewModifier
struct TeslaAlertModifier: ViewModifier {
    let alert: TeslaAlertCard?
    let alignment: Alignment

    func body(content: Content) -> some View {
        ZStack(alignment: alignment) {
            content

            if let alert = alert {
                alert
                    .padding()
                    .transition(.move(edge: alignment == .top ? .top : .bottom).combined(with: .opacity))
            }
        }
        .animation(TeslaAnimation.standard, value: alert?.title)
    }
}

extension View {
    /// アラートを表示
    func teslaAlert(
        _ alert: TeslaAlertCard?,
        alignment: Alignment = .top
    ) -> some View {
        modifier(TeslaAlertModifier(alert: alert, alignment: alignment))
    }
}

// MARK: - Preview

#Preview("Tesla Alert Card") {
    VStack(spacing: 24) {
        // All Types
        VStack(alignment: .leading, spacing: 16) {
            Text("Alert Types")
                .font(TeslaTypography.headlineSmall)
                .foregroundStyle(TeslaColors.textPrimary)

            TeslaAlertCard.info(
                title: "Information",
                message: "This is an informational message.",
                onDismiss: {}
            )

            TeslaAlertCard.success(
                title: "Success",
                message: "Operation completed successfully.",
                onDismiss: {}
            )

            TeslaAlertCard.warning(
                title: "Warning",
                message: "Please check your input.",
                onDismiss: {}
            )

            TeslaAlertCard.error(
                title: "Error",
                message: "Failed to load the video file. Please try again.",
                onDismiss: {}
            )
        }

        Divider()
            .background(TeslaColors.glassBorder)

        // Without Message
        VStack(alignment: .leading, spacing: 16) {
            Text("Title Only")
                .font(TeslaTypography.headlineSmall)
                .foregroundStyle(TeslaColors.textPrimary)

            TeslaAlertCard.error(title: "Connection failed")
        }

        Spacer()
    }
    .padding(24)
    .background(TeslaColors.background)
}
