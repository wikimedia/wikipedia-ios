import SwiftUI
import WMFComponents

struct ToggleTextFieldRow: View {
    let title: String
    let trailingLabel: String?
    @Binding var isOn: Bool
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .frame(width: 40)

            Text(title)

            TextField("", text: $text)
                .keyboardType(.numberPad)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
                .frame(width: 55)
                .disabled(!isOn)
                .opacity(isOn ? 1 : 0.4)

            if let trailing = trailingLabel {
                Text(trailing)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation { isOn.toggle() }
        }
    }
}

struct DatabasePopulationView: View {
    @StateObject private var viewModel = DatabasePopulationViewModel()

    var body: some View {
        Form {
            Section(header: Text("Saved Articles")) {
                ToggleTextFieldRow(
                    title: "Create",
                    trailingLabel: "lists",
                    isOn: $viewModel.createLists,
                    text: $viewModel.listLimitString
                )

                ToggleTextFieldRow(
                    title: "Add",
                    trailingLabel: "saved articles to every list",
                    isOn: $viewModel.addEntries,
                    text: $viewModel.entryLimitString
                )

                HStack {
                    Toggle("", isOn: $viewModel.randomizeAcrossLanguages)
                        .labelsHidden()
                        .frame(width: 40)
                        .disabled(!viewModel.addEntries)
                        .opacity(viewModel.addEntries ? 1 : 0.4)

                    Text("Randomize across languages")
                    Spacer()
                }
            }
            
            // MARK: - Add Viewed Articles Section
            Section(header: Text("Viewed Articles")) {
                ToggleTextFieldRow(
                    title: "Add",
                    trailingLabel: "viewed articles",
                    isOn: $viewModel.addViewedArticles,
                    text: $viewModel.viewedArticlesCountString
                )

                HStack {
                    Toggle("", isOn: $viewModel.randomizeViewedAcrossLanguages)
                        .labelsHidden()
                        .frame(width: 40)
                        .disabled(!viewModel.addViewedArticles)
                        .opacity(viewModel.addViewedArticles ? 1 : 0.4)

                    Text("Randomize across languages")
                    Spacer()
                }
            }
            
            // MARK: - Viewed Article Date Range
            if viewModel.addViewedArticles {
                Section(header: Text("Viewed Article Dates")) {
                    Picker("", selection: $viewModel.viewedDateRange) {
                        ForEach(DatabasePopulationViewModel.ViewedDateRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.automatic)
                }
            }

            // MARK: - Centered Button Section
            Section {
                HStack {
                    Spacer()

                    Button {
                        Task { await viewModel.doIt() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Do it")
                        }
                    }
                    .disabled(viewModel.isLoading)

                    Spacer()
                }
            }
        }
    }
}

