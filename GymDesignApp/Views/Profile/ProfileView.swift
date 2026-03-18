import SwiftUI

// MARK: - Profile View

struct ProfileView: View {

    @StateObject private var viewModel = ProfileViewModel()
    @State private var showSignOutConfirmation = false

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    userHeader
                    statsRow
                    menuSections
                    signOutButton
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                Task {
                    await viewModel.fetchProfile()
                }
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    // MARK: User Header

    private var userHeader: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppTheme.accentGradient)
                    .frame(width: 80, height: 80)

                Text(viewModel.displayInitials)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Name and email
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(viewModel.displayName)
                    .font(AppTheme.title)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(viewModel.email)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.md)
    }

    // MARK: Stats Row

    private var statsRow: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            StatCard(title: "Designs", value: viewModel.designCount)
            StatCard(title: "Submissions", value: viewModel.submissionCount)
            StatCard(title: "Favorites", value: viewModel.favoritesCount)
        }
    }

    // MARK: Menu Sections

    private var menuSections: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ProfileMenuRow(
                icon: "square.grid.2x2.fill",
                iconColor: AppTheme.accent,
                title: "Saved Designs",
                destination: SavedDesignsGridView()
            )

            ProfileMenuRow(
                icon: "paperplane.fill",
                iconColor: .orange,
                title: "My Submissions",
                destination: placeholderView("My Submissions")
            )

            ProfileMenuRow(
                icon: "heart.fill",
                iconColor: .pink,
                title: "Favorites",
                destination: placeholderView("Favorites")
            )

            ProfileMenuRow(
                icon: "gearshape.fill",
                iconColor: AppTheme.textSecondary,
                title: "Settings",
                destination: SettingsView()
            )
        }
    }

    // MARK: Sign Out

    private var signOutButton: some View {
        Button {
            showSignOutConfirmation = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(AppTheme.headline)
            .foregroundStyle(AppTheme.error)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .glassMaterial(cornerRadius: AppTheme.CornerRadius.medium)
        }
        .padding(.top, AppTheme.Spacing.md)
    }

    // MARK: Helpers

    private func placeholderView(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.title)
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(title)
    }
}

// MARK: - Stat Card

private struct StatCard: View {

    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(title)
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .glassMaterial(cornerRadius: AppTheme.CornerRadius.medium)
    }
}

// MARK: - Profile Menu Row

private struct ProfileMenuRow<Destination: View>: View {

    let icon: String
    let iconColor: Color
    let title: String
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                Text(title)
                    .font(AppTheme.body)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(AppTheme.Spacing.md)
            .glassMaterial(cornerRadius: AppTheme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
