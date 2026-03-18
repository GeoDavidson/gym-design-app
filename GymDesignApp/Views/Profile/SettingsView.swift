import SwiftUI

// MARK: - Settings View

struct SettingsView: View {

    // MARK: State

    @State private var displayName: String = "Alex Johnson"
    @State private var email: String = "designer@gymdesign.app"
    @State private var measurementUnit: MeasurementUnit = .metric
    @State private var hapticsEnabled: Bool = true
    @State private var notificationsEnabled: Bool = true
    @State private var showDeleteAccountAlert: Bool = false

    // MARK: Body

    var body: some View {
        List {
            accountSection
            preferencesSection
            aboutSection
            dangerZoneSection
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Account", role: .destructive) {
                // TODO: Implement account deletion
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
    }

    // MARK: Account Section

    private var accountSection: some View {
        Section {
            settingsRow(icon: "person.fill", iconColor: AppTheme.accent) {
                HStack {
                    Text("Display Name")
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    TextField("Name", text: $displayName)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            settingsRow(icon: "envelope.fill", iconColor: .blue) {
                HStack {
                    Text("Email")
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text(email)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        } header: {
            Text("Account")
                .foregroundStyle(AppTheme.textSecondary)
        }
        .listRowBackground(AppTheme.surface)
    }

    // MARK: Preferences Section

    private var preferencesSection: some View {
        Section {
            settingsRow(icon: "ruler.fill", iconColor: .green) {
                HStack {
                    Text("Measurement Unit")
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Picker("", selection: $measurementUnit) {
                        ForEach(MeasurementUnit.allCases) { unit in
                            Text(unit == .metric ? "Metric" : "Imperial")
                                .tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.accent)
                }
            }

            settingsRow(icon: "hand.tap.fill", iconColor: .purple) {
                Toggle(isOn: $hapticsEnabled) {
                    Text("Haptic Feedback")
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .tint(AppTheme.accent)
            }

            settingsRow(icon: "bell.fill", iconColor: .orange) {
                Toggle(isOn: $notificationsEnabled) {
                    Text("Notifications")
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .tint(AppTheme.accent)
            }
        } header: {
            Text("Preferences")
                .foregroundStyle(AppTheme.textSecondary)
        }
        .listRowBackground(AppTheme.surface)
    }

    // MARK: About Section

    private var aboutSection: some View {
        Section {
            settingsRow(icon: "info.circle.fill", iconColor: AppTheme.textSecondary) {
                HStack {
                    Text("App Version")
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("\(AppConstants.App.version) (\(AppConstants.App.buildNumber))")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            NavigationLink {
                aboutPlaceholder("Terms of Service")
            } label: {
                settingsRow(icon: "doc.text.fill", iconColor: AppTheme.textSecondary) {
                    Text("Terms of Service")
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            NavigationLink {
                aboutPlaceholder("Privacy Policy")
            } label: {
                settingsRow(icon: "lock.fill", iconColor: AppTheme.textSecondary) {
                    Text("Privacy Policy")
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }

            NavigationLink {
                aboutPlaceholder("Open Source Licenses")
            } label: {
                settingsRow(icon: "book.closed.fill", iconColor: AppTheme.textSecondary) {
                    Text("Licenses")
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        } header: {
            Text("About")
                .foregroundStyle(AppTheme.textSecondary)
        }
        .listRowBackground(AppTheme.surface)
    }

    // MARK: Danger Zone Section

    private var dangerZoneSection: some View {
        Section {
            Button {
                showDeleteAccountAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.error)
                        .frame(width: 28, height: 28)

                    Text("Delete Account")
                        .foregroundStyle(AppTheme.error)

                    Spacer()
                }
            }
        } header: {
            Text("Danger Zone")
                .foregroundStyle(AppTheme.error.opacity(0.8))
        }
        .listRowBackground(AppTheme.surface)
    }

    // MARK: Helpers

    private func settingsRow<Content: View>(
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))

            content()
        }
        .font(AppTheme.body)
    }

    private func aboutPlaceholder(_ title: String) -> some View {
        ScrollView {
            Text("Content for \(title) will be displayed here.")
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(AppTheme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .preferredColorScheme(.dark)
}
