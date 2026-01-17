import SwiftUI
import MapKit

struct LocationSearchView: View {
    @State private var viewModel = LocationSearchViewModel()
    @State private var showSearchResults = false

    var body: some View {
        ZStack(alignment: .top) {
            mapView
                .onTapGesture {
                    viewModel.hideSuggestions()
                }

            VStack(spacing: 0) {
                SearchBar(text: $viewModel.searchQuery) {
                    viewModel.hideSuggestions()
                    Task {
                        await viewModel.search()
                        showSearchResults = !viewModel.searchResults.isEmpty
                    }
                } onTextChange: { _ in
                    viewModel.updateSuggestions()
                }
                .padding(.top, 8)

                if viewModel.showSuggestions {
                    suggestionsList
                }

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }
            }

            if let route = viewModel.route {
                VStack {
                    Spacer()
                    RouteInfoView(route: route)
                        .padding()
                }
            }
        }
        .navigationTitle("場所を検索")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSearchResults) {
            searchResultsSheet
        }
        .onAppear {
            viewModel.requestLocationPermission()
        }
    }

    private var mapView: some View {
        Map(position: $viewModel.mapCameraPosition) {
            if let currentLocation = viewModel.currentLocation {
                Annotation("現在地", coordinate: currentLocation) {
                    Image(systemName: "location.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }

            if let selectedPlace = viewModel.selectedPlace {
                Marker(selectedPlace.name, coordinate: selectedPlace.coordinate)
                    .tint(.red)
            }

            if let route = viewModel.route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 5)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var searchResultsSheet: some View {
        NavigationStack {
            Group {
                if viewModel.isSearching {
                    ProgressView("検索中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty {
                    ContentUnavailableView(
                        "検索結果がありません",
                        systemImage: "magnifyingglass",
                        description: Text("別のキーワードで検索してみてください")
                    )
                } else {
                    List(viewModel.searchResults) { place in
                        PlaceListItem(place: place)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Task {
                                    await viewModel.selectPlace(place)
                                    showSearchResults = false
                                }
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("検索結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        showSearchResults = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func errorBanner(message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.red)
            .cornerRadius(8)
            .padding(.top, 8)
    }

    private var suggestionsList: some View {
        VStack(spacing: 0) {
            if viewModel.isSuggesting {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("検索中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.suggestions) { suggestion in
                            SuggestionListItem(suggestion: suggestion)
                                .onTapGesture {
                                    Task {
                                        await viewModel.selectSuggestion(suggestion)
                                        if viewModel.searchResults.count > 1 {
                                            showSearchResults = true
                                        }
                                    }
                                }

                            if suggestion.id != viewModel.suggestions.last?.id {
                                Divider()
                                    .padding(.leading, 36)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 250)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

#Preview {
    NavigationStack {
        LocationSearchView()
    }
}
