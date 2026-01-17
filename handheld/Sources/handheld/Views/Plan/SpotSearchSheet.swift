import SwiftUI
import MapKit

struct SpotSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Place) -> Void

    @State private var searchQuery = ""
    @State private var searchResults: [Place] = []
    @State private var isSearching = false

    private let searchService = LocationSearchService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("スポットを検索", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            Task {
                                await search()
                            }
                        }
                    if isSearching {
                        ProgressView()
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))

                if searchResults.isEmpty && !isSearching {
                    ContentUnavailableView(
                        "スポットを検索",
                        systemImage: "magnifyingglass",
                        description: Text("追加したいスポットを検索してください")
                    )
                } else {
                    List(searchResults) { place in
                        Button {
                            onSelect(place)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.red)
                                VStack(alignment: .leading) {
                                    Text(place.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text(place.address)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("スポット追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func search() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        do {
            searchResults = try await searchService.search(query: searchQuery, region: nil)
        } catch {
            searchResults = []
        }
        isSearching = false
    }
}

#Preview {
    SpotSearchSheet(onSelect: { _ in })
}
