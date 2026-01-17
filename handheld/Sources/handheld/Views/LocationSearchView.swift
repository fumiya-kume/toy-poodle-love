import SwiftUI
import MapKit

struct LocationSearchView: View {
    @State private var viewModel = LocationSearchViewModel()
    @State private var showSearchResults = false
    @State private var showNavigationLookAroundSheet = false
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            mapView
                .onTapGesture {
                    isSearchFieldFocused = false
                    viewModel.hideSuggestions()
                }
                .onChange(of: viewModel.locationManager.isTracking) { _, isTracking in
                    if isTracking, let location = viewModel.currentLocation {
                        viewModel.updateNavigationForLocation(location)
                    }
                }
                .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                    guard !viewModel.isUserInteractingWithMap else { return }
                    if viewModel.isNavigationMode, let location = viewModel.currentLocation {
                        viewModel.updateNavigationForLocation(location)
                    }
                }

            if !viewModel.isNavigationMode {
                VStack(spacing: 0) {
                    SearchBar(
                        text: $viewModel.searchQuery,
                        onSearch: {
                            viewModel.hideSuggestions()
                            Task {
                                await viewModel.search()
                                showSearchResults = !viewModel.searchResults.isEmpty
                            }
                        },
                        onTextChange: { _ in
                            viewModel.updateSuggestions()
                        },
                        isFocused: $isSearchFieldFocused
                    )
                    .padding(.top, 8)

                    if viewModel.showSuggestions {
                        suggestionsList
                    }

                    if let locationErrorMessage = viewModel.locationErrorMessage {
                        errorBanner(message: locationErrorMessage)
                    }
                }
            }

            // Look Aroundプレビューカード（通常モード）
            if !viewModel.isNavigationMode && (viewModel.showLookAround || viewModel.isLoadingLookAround) {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        LookAroundPreviewCard(
                            scene: viewModel.currentLookAroundScene,
                            locationName: viewModel.lookAroundLocationName,
                            isLoading: viewModel.isLoadingLookAround,
                            onTap: {
                                viewModel.openLookAroundSheet()
                            },
                            onClose: {
                                viewModel.dismissLookAround()
                            },
                            onAutoDrive: {
                                viewModel.showAutoDriveSheet = true
                                Task {
                                    await viewModel.startAutoDrive()
                                }
                            }
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, viewModel.route != nil ? 160 : 16)
                }
                .animation(.spring(response: 0.3), value: viewModel.showLookAround)
            }

            // ルート情報（通常モード）
            if !viewModel.isNavigationMode, let route = viewModel.route {
                VStack {
                    Spacer()
                    RouteInfoView(
                        route: route,
                        transportType: $viewModel.transportType,
                        hasLookAroundAvailable: viewModel.hasLookAroundAvailable,
                        onLookAroundTap: {
                            viewModel.showLookAroundCard()
                        },
                        onTransportTypeChange: {
                            Task {
                                await viewModel.recalculateRouteWithTransportType()
                            }
                        },
                        onStartNavigation: {
                            Task {
                                await viewModel.startNavigation()
                            }
                        },
                        onStartAutoDrive: {
                            viewModel.showAutoDriveSheet = true
                            Task {
                                await viewModel.startAutoDrive()
                            }
                        }
                    )
                    .padding()
                }
            }

            // ナビゲーションモード
            if viewModel.isNavigationMode {
                NavigationOverlayView(
                    currentStep: viewModel.currentNavigationStep,
                    distanceToNextStep: viewModel.formattedDistanceToNextStep,
                    onStopNavigation: {
                        viewModel.stopNavigation()
                    },
                    onLookAroundTap: {
                        showNavigationLookAroundSheet = true
                    }
                )
                .padding(.top, 60)

                // ナビモード中のLook Aroundプレビュー（200m以内で自動表示）
                if viewModel.shouldShowNavigationLookAround,
                   let step = viewModel.currentNavigationStep,
                   step.lookAroundScene != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            LookAroundPreviewCard(
                                scene: step.lookAroundScene,
                                locationName: step.instructions.isEmpty ? "次の曲がり角" : step.instructions,
                                isLoading: step.isLookAroundLoading,
                                onTap: {
                                    showNavigationLookAroundSheet = true
                                },
                                onClose: {
                                    viewModel.shouldShowNavigationLookAround = false
                                }
                            )
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationTitle("場所を検索")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSearchResults) {
            searchResultsSheet
        }
        .sheet(isPresented: $viewModel.showLookAroundSheet) {
            LookAroundSheetView(
                selectedTarget: $viewModel.lookAroundTarget,
                destinationScene: viewModel.destinationLookAroundScene,
                nextStepScene: viewModel.nextStepLookAroundScene,
                destinationName: viewModel.selectedPlace?.name ?? "目的地",
                hasNextStep: viewModel.hasNextStep
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNavigationLookAroundSheet) {
            NavigationLookAroundSheetView(
                navigationSteps: viewModel.navigationSteps,
                selectedStepIndex: $viewModel.currentNavigationStepIndex
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showAutoDriveSheet) {
            AutoDriveSheetView(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { viewModel.alertError != nil },
                set: { if !$0 { viewModel.alertError = nil } }
            ),
            presenting: viewModel.alertError
        ) { _ in
            Button("OK") {
                viewModel.alertError = nil
            }
        } message: { error in
            Text(error.localizedDescription)
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
        .onMapCameraChange(frequency: .continuous) { _ in
            viewModel.isUserInteractingWithMap = true
        }
        .onMapCameraChange(frequency: .onEnd) { _ in
            viewModel.isUserInteractingWithMap = false
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
                                    .padding(.leading, 48)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: 500, maxHeight: 250)
            }
        }
        .frame(maxWidth: 500)
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
