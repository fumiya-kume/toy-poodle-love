// Tesla Dashboard UI - Group Box for Viewer App
// フォームやセクション用のTeslaスタイルグループボックス

import SwiftUI

// MARK: - Tesla Group Box

/// Teslaスタイルのグループボックス
/// フォーム入力やセクション区切りに使用
struct TeslaGroupBox<Content: View>: View {
    // MARK: - Properties

    let title: String
    @ViewBuilder var content: () -> Content

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text(title)
                .font(TeslaTypography.titleSmall)
                .foregroundStyle(TeslaColors.textPrimary)

            // Divider
            Rectangle()
                .fill(TeslaColors.glassBorder)
                .frame(height: 1)

            // Content
            content()
        }
        .padding(16)
        .background(TeslaColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TeslaColors.glassBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Tesla Form Field

/// Teslaスタイルのフォームフィールド
struct TeslaFormField<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(TeslaTypography.labelMedium)
                .foregroundStyle(TeslaColors.textSecondary)

            content()
        }
    }
}

// MARK: - Tesla Text Field Style

/// Teslaスタイルのテキストフィールド用ViewModifier
struct TeslaTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(TeslaTypography.bodyMedium)
            .padding(10)
            .background(TeslaColors.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(TeslaColors.glassBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

extension View {
    /// Teslaスタイルのテキストフィールドスタイルを適用
    func teslaTextFieldStyle() -> some View {
        modifier(TeslaTextFieldStyle())
    }
}

// MARK: - Tesla Text Editor Style

/// Teslaスタイルのテキストエディタ用ViewModifier
struct TeslaTextEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(TeslaTypography.bodyMedium)
            .scrollContentBackground(.hidden)
            .padding(10)
            .background(TeslaColors.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(TeslaColors.glassBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

extension View {
    /// Teslaスタイルのテキストエディタスタイルを適用
    func teslaTextEditorStyle() -> some View {
        modifier(TeslaTextEditorStyle())
    }
}

// MARK: - Tesla Focusable Text Field Style

/// Teslaスタイルのテキストフィールド用ViewModifier（フォーカス対応）
/// フォーカス時にアクセントカラーのボーダーを表示
struct TeslaFocusableTextFieldStyle: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .textFieldStyle(.plain)
            .font(TeslaTypography.bodyMedium)
            .padding(10)
            .background(TeslaColors.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isFocused ? TeslaColors.accent : TeslaColors.glassBorder,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .animation(TeslaAnimation.quick, value: isFocused)
    }
}

extension View {
    /// Teslaスタイルのテキストフィールドスタイルを適用（フォーカス対応）
    func teslaFocusableTextFieldStyle() -> some View {
        modifier(TeslaFocusableTextFieldStyle())
    }
}

// MARK: - Tesla Focusable Text Editor Style

/// Teslaスタイルのテキストエディタ用ViewModifier（フォーカス対応）
/// フォーカス時にアクセントカラーのボーダーを表示
struct TeslaFocusableTextEditorStyle: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .font(TeslaTypography.bodyMedium)
            .scrollContentBackground(.hidden)
            .padding(10)
            .background(TeslaColors.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isFocused ? TeslaColors.accent : TeslaColors.glassBorder,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .animation(TeslaAnimation.quick, value: isFocused)
    }
}

extension View {
    /// Teslaスタイルのテキストエディタスタイルを適用（フォーカス対応）
    func teslaFocusableTextEditorStyle() -> some View {
        modifier(TeslaFocusableTextEditorStyle())
    }
}

// MARK: - Tesla Primary Button Style

/// Teslaスタイルのプライマリボタン
struct TeslaPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TeslaTypography.labelLarge)
            .foregroundStyle(isEnabled ? .white : TeslaColors.textTertiary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isEnabled ? TeslaColors.accent : TeslaColors.surface)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(TeslaAnimation.quick, value: configuration.isPressed)
    }
}

// MARK: - Tesla Secondary Button Style

/// Teslaスタイルのセカンダリボタン
struct TeslaSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TeslaTypography.labelLarge)
            .foregroundStyle(isEnabled ? TeslaColors.textPrimary : TeslaColors.textTertiary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(TeslaColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(TeslaColors.glassBorder, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(TeslaAnimation.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == TeslaPrimaryButtonStyle {
    static var teslaPrimary: TeslaPrimaryButtonStyle { TeslaPrimaryButtonStyle() }
}

extension ButtonStyle where Self == TeslaSecondaryButtonStyle {
    static var teslaSecondary: TeslaSecondaryButtonStyle { TeslaSecondaryButtonStyle() }
}

// MARK: - Preview

#Preview("Tesla Group Box") {
    ZStack {
        TeslaColors.background

        VStack(spacing: 16) {
            TeslaGroupBox(title: "入力") {
                VStack(alignment: .leading, spacing: 12) {
                    TeslaFormField(label: "出発地") {
                        TextField("例: 東京駅", text: .constant(""))
                            .teslaTextFieldStyle()
                    }

                    TeslaFormField(label: "目的・テーマ") {
                        TextField("例: 観光スポットを巡りたい", text: .constant(""))
                            .teslaTextFieldStyle()
                    }

                    Button("実行") {}
                        .buttonStyle(.teslaPrimary)
                }
            }

            TeslaGroupBox(title: "結果") {
                Text("結果がありません")
                    .font(TeslaTypography.bodyMedium)
                    .foregroundStyle(TeslaColors.textSecondary)
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
    .frame(width: 400, height: 450)
}
