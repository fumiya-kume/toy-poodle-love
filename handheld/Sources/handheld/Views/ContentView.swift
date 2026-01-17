import SwiftUI

struct ContentView: View {
    @State private var viewModel = ContentViewModel()
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // ヒーローセクション
                    HeroSection()
                        .padding(.top, 40)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)

                    // ウェルカムメッセージ
                    Text(viewModel.message)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.accentColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 15)

                    // フィーチャーカード群
                    VStack(spacing: 16) {
                        NavigationLink {
                            LocationSearchView()
                        } label: {
                            FeatureCard(
                                icon: "magnifyingglass",
                                title: "場所を検索",
                                description: "お散歩コースを探しましょう"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            PlanGeneratorView()
                        } label: {
                            FeatureCard(
                                icon: "wand.and.stars",
                                title: "プラン作成",
                                description: "AIが観光プランを提案"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            FavoritesView()
                        } label: {
                            FeatureCard(
                                icon: "heart.fill",
                                title: "お気に入り",
                                description: "保存した場所を確認"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)

                    Spacer(minLength: 40)
                }
                #if targetEnvironment(macCatalyst)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
                #endif
            }
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Toy Poodle Love")
                        .font(.headline)
                        .foregroundStyle(AppTheme.accentColor)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                    hasAppeared = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
