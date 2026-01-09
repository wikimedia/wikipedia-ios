//
//  WMFYearInReviewSettingsView.swift
//  WMFComponents
//
//  Created by Marina Azevedo on 08/01/26.
//


import SwiftUI
import WMFComponents

struct WMFYearInReviewSettingsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }

    @StateObject var viewModel: WMFYearInReviewSettingsViewModel

    var body: some View {
        ZStack {
            Color(uiColor: theme.midBackground).ignoresSafeArea()

            List {
                Section {
                    Text(viewModel.descriptionText)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                        .padding(.vertical, 8)
                }
                .textCase(nil)
                .listRowBackground(Color(uiColor: theme.chromeBackground))

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Color(uiColor: theme.chromeBackground))
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue) // keep simple; swap to WMFColor if preferred
                            )

                        Text(viewModel.toggleTitle)
                            .font(Font(WMFFont.for(.headline)))
                            .foregroundStyle(Color(uiColor: theme.text))

                        Spacer()

                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Toggle("", isOn: Binding(
                                get: { viewModel.isEnabled },
                                set: { newValue in
                                    Task { @MainActor in
                                        await viewModel.setEnabled(newValue)
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color(uiColor: theme.chromeBackground))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, theme.preferredColorScheme)
    }
}
