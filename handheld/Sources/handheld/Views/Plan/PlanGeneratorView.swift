import SwiftUI
import SwiftData

struct PlanGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PlanGeneratorViewModel()
    @State private var showCloseConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.generatorState == .completed {
                    PlanResultView(viewModel: viewModel)
                } else if viewModel.generatorState != .idle {
                    GeneratingProgressView(state: viewModel.generatorState)
                } else {
                    VStack(spacing: 0) {
                        StepIndicator(
                            currentStep: viewModel.currentStep.rawValue,
                            totalSteps: PlanGeneratorStep.allCases.count
                        )
                        .padding(.top)

                        stepContent
                            .padding()

                        navigationButtons
                            .padding()
                    }
                }
            }
            .navigationTitle("プラン作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        if viewModel.generatorState == .completed && viewModel.generatedPlan != nil {
                            showCloseConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .confirmationDialog(
                "プランを保存しますか？",
                isPresented: $showCloseConfirmation,
                titleVisibility: .visible
            ) {
                Button("保存する") {
                    viewModel.savePlan(context: modelContext)
                    viewModel.saveFavoriteSpots(context: modelContext)
                    dismiss()
                }
                Button("保存しない", role: .destructive) {
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
            .alert("エラー", isPresented: .init(
                get: { if case .error = viewModel.generatorState { return true } else { return false } },
                set: { if !$0 { viewModel.generatorState = .idle } }
            )) {
                Button("OK") {
                    viewModel.generatorState = .idle
                }
            } message: {
                if case .error(let message) = viewModel.generatorState {
                    Text(message)
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .location:
            InputStep1View(viewModel: viewModel)
        case .category:
            InputStep2View(viewModel: viewModel)
        case .theme:
            InputStep3View(viewModel: viewModel)
        case .confirm:
            InputConfirmView(viewModel: viewModel)
        }
    }

    private var navigationButtons: some View {
        HStack {
            if !viewModel.currentStep.isFirst {
                Button {
                    viewModel.previousStep()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if viewModel.currentStep.isLast {
                Button {
                    Task {
                        await viewModel.generatePlan()
                    }
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("生成")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canProceedToNext)
            } else {
                Button {
                    viewModel.nextStep()
                } label: {
                    HStack {
                        Text("次へ")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canProceedToNext)
            }
        }
    }
}

#Preview {
    PlanGeneratorView()
}
