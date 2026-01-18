import SwiftUI
import AVKit

struct VideoPlayerView: NSViewRepresentable {
    enum Style {
        case main
        case overlay
    }

    let player: AVPlayer?
    let style: Style

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        configure(view)
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
        configure(nsView)
    }

    private func configure(_ view: AVPlayerView) {
        view.controlsStyle = .none
        view.videoGravity = .resizeAspect
        view.showsFullScreenToggleButton = false

        if style == .overlay {
            view.wantsLayer = true
            view.layer?.backgroundColor = .clear
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        VideoPlayerView(player: nil, style: .main)
            .frame(width: 640, height: 360)

        VideoPlayerView(player: nil, style: .overlay)
            .frame(width: 640, height: 360)
            .opacity(0.5)
    }
}
