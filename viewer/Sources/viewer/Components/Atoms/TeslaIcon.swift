// Tesla Dashboard UI - Icons for Viewer App
// SF Symbols ベースのアイコン定義
// ビデオプレイヤー向けに最適化

import SwiftUI

// MARK: - Tesla Icons

/// Tesla Dashboard UI で使用するアイコン定義
/// ビデオプレイヤー向けのアイコンを中心に提供
enum TeslaIcon: String, CaseIterable, Sendable {

    // MARK: - Playback

    /// 再生
    case play = "play.fill"

    /// 一時停止
    case pause = "pause.fill"

    /// 10秒戻る
    case skipBackward = "gobackward.10"

    /// 10秒進む
    case skipForward = "goforward.10"

    /// 最初に戻る
    case goToBeginning = "backward.end.fill"

    /// 最後に進む
    case goToEnd = "forward.end.fill"

    // MARK: - Audio

    /// 音量あり
    case volumeOn = "speaker.wave.2.fill"

    /// 音量（volume のエイリアス）
    case volume = "speaker.wave.2"

    /// ミュート
    case volumeOff = "speaker.slash.fill"

    /// ミュート（muted のエイリアス）
    case muted = "speaker.slash"

    /// 音量（低）
    case volumeLow = "speaker.fill"

    /// TTS（テキスト読み上げ）
    case tts = "waveform.and.person.filled"

    /// 停止
    case stop = "stop.fill"

    // MARK: - Video Controls

    /// 同期
    case sync = "arrow.triangle.2.circlepath"

    /// オーバーレイ
    case overlay = "square.on.square"

    /// 不透明度
    case opacity = "circle.lefthalf.filled"

    /// フルスクリーン
    case fullscreen = "arrow.up.left.and.arrow.down.right"

    /// フルスクリーン解除
    case exitFullscreen = "arrow.down.right.and.arrow.up.left"

    // MARK: - Navigation

    /// ナビゲーション（位置情報）
    case navigation = "location.fill"

    /// 地図
    case map = "map.fill"

    /// ルート
    case route = "arrow.triangle.turn.up.right.diamond.fill"

    /// 検索
    case search = "magnifyingglass"

    // MARK: - Scenario Writer

    /// パイプライン
    case pipeline = "arrow.triangle.branch"

    /// テキスト生成
    case textGeneration = "text.bubble.fill"

    /// 最適化
    case optimize = "wand.and.stars"

    /// 統合
    case integrate = "arrow.triangle.merge"

    /// ジオコード
    case geocode = "mappin.and.ellipse"

    // MARK: - Media

    /// 音楽
    case music = "music.note"

    /// マイク
    case microphone = "mic.fill"

    /// 再生バー
    case playbar = "slider.horizontal.below.rectangle"

    // MARK: - Controls

    /// 設定
    case settings = "gearshape.fill"

    /// 情報
    case info = "info.circle.fill"

    /// コピー
    case copy = "doc.on.doc.fill"

    /// 閉じる
    case close = "xmark"

    // MARK: - Status

    /// チェックマーク
    case checkmark = "checkmark.circle.fill"

    /// 警告
    case warning = "exclamationmark.triangle.fill"

    /// エラー
    case error = "xmark.circle.fill"

    /// ローディング
    case loading = "arrow.2.circlepath"

    // MARK: - UI

    /// 展開
    case expand = "chevron.up"

    /// 折りたたみ
    case collapse = "chevron.down"

    /// 右矢印
    case chevronRight = "chevron.right"

    /// 左矢印
    case chevronLeft = "chevron.left"

    /// メニュー
    case menu = "line.3.horizontal"

    /// プラス
    case plus = "plus"

    /// マイナス
    case minus = "minus"

    // MARK: - Files

    /// ビデオファイル
    case video = "film.fill"

    /// フォルダ
    case folder = "folder.fill"

    /// ドキュメント
    case document = "doc.fill"

    // MARK: - Properties

    /// SF Symbols のシステム名
    var systemName: String { rawValue }

    /// アイコンのローカライズされたラベル（アクセシビリティ用）
    var accessibilityLabel: String {
        switch self {
        case .play: return "再生"
        case .pause: return "一時停止"
        case .skipBackward: return "10秒戻る"
        case .skipForward: return "10秒進む"
        case .goToBeginning: return "最初に戻る"
        case .goToEnd: return "最後に進む"
        case .volumeOn: return "音量"
        case .volume: return "音量"
        case .volumeOff: return "ミュート"
        case .muted: return "ミュート"
        case .volumeLow: return "音量（低）"
        case .tts: return "テキスト読み上げ"
        case .stop: return "停止"
        case .sync: return "同期"
        case .overlay: return "オーバーレイ"
        case .opacity: return "不透明度"
        case .fullscreen: return "フルスクリーン"
        case .exitFullscreen: return "フルスクリーン解除"
        case .navigation: return "ナビゲーション"
        case .map: return "地図"
        case .route: return "ルート"
        case .search: return "検索"
        case .pipeline: return "パイプライン"
        case .textGeneration: return "テキスト生成"
        case .optimize: return "最適化"
        case .integrate: return "統合"
        case .geocode: return "ジオコード"
        case .music: return "音楽"
        case .microphone: return "マイク"
        case .playbar: return "再生バー"
        case .settings: return "設定"
        case .info: return "情報"
        case .copy: return "コピー"
        case .close: return "閉じる"
        case .checkmark: return "完了"
        case .warning: return "警告"
        case .error: return "エラー"
        case .loading: return "読み込み中"
        case .expand: return "展開"
        case .collapse: return "折りたたみ"
        case .chevronRight: return "右"
        case .chevronLeft: return "左"
        case .menu: return "メニュー"
        case .plus: return "追加"
        case .minus: return "削除"
        case .video: return "ビデオ"
        case .folder: return "フォルダ"
        case .document: return "ドキュメント"
        }
    }
}

// MARK: - Icon Group

/// アイコンのカテゴリグループ
enum TeslaIconGroup: String, CaseIterable {
    case playback = "Playback"
    case audio = "Audio"
    case videoControls = "Video Controls"
    case navigation = "Navigation"
    case scenarioWriter = "Scenario Writer"
    case media = "Media"
    case controls = "Controls"
    case status = "Status"
    case ui = "UI"
    case files = "Files"

    /// グループに属するアイコン
    var icons: [TeslaIcon] {
        switch self {
        case .playback:
            return [.play, .pause, .skipBackward, .skipForward, .goToBeginning, .goToEnd]
        case .audio:
            return [.volumeOn, .volume, .volumeOff, .muted, .volumeLow, .tts, .stop]
        case .videoControls:
            return [.sync, .overlay, .opacity, .fullscreen, .exitFullscreen]
        case .navigation:
            return [.navigation, .map, .route, .search]
        case .scenarioWriter:
            return [.pipeline, .textGeneration, .optimize, .integrate, .geocode]
        case .media:
            return [.music, .microphone, .playbar]
        case .controls:
            return [.settings, .info, .copy, .close]
        case .status:
            return [.checkmark, .warning, .error, .loading]
        case .ui:
            return [.expand, .collapse, .chevronRight, .chevronLeft, .menu, .plus, .minus]
        case .files:
            return [.video, .folder, .document]
        }
    }
}

// MARK: - Preview

#Preview("Tesla Icons") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(TeslaIconGroup.allCases, id: \.self) { group in
                VStack(alignment: .leading, spacing: 12) {
                    Text(group.rawValue)
                        .font(TeslaTypography.headlineSmall)
                        .foregroundStyle(TeslaColors.textPrimary)

                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 70))
                    ], spacing: 16) {
                        ForEach(group.icons, id: \.self) { icon in
                            VStack(spacing: 8) {
                                TeslaIconView(icon: icon, size: 24)

                                Text(icon.accessibilityLabel)
                                    .font(TeslaTypography.labelSmall)
                                    .foregroundStyle(TeslaColors.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(width: 70)
                        }
                    }
                }

                if group != TeslaIconGroup.allCases.last {
                    Divider()
                        .background(TeslaColors.glassBorder)
                }
            }
        }
        .padding(24)
    }
    .background(TeslaColors.background)
}
