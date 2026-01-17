import SwiftUI
import MapKit

struct InputStep1View: View {
    @Bindable var viewModel: PlanGeneratorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("どのエリアで観光しますか？")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("地名を入力", text: $viewModel.locationQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            Task {
                                await viewModel.searchLocation()
                            }
                        }
                    if viewModel.isSearchingLocation {
                        ProgressView()
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !viewModel.locationSuggestions.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(viewModel.locationSuggestions) { place in
                            Button {
                                viewModel.selectLocation(place)
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
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)

                            if place.id != viewModel.locationSuggestions.last?.id {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let selected = viewModel.selectedLocation {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(selected.name)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                RadiusPicker(selectedRadius: $viewModel.searchRadius)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .onChange(of: viewModel.locationQuery) { _, _ in
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                await viewModel.searchLocation()
            }
        }
    }
}

#Preview {
    InputStep1View(viewModel: PlanGeneratorViewModel())
        .padding()
}
