import SwiftUI

// MARK: - Home View

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @Binding var selectedTab: Int

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    greetingSection
                    quickActionsSection
                    recentDesignsSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .refreshable {
                await viewModel.fetchRecentDesigns()
            }
            .onAppear {
                if viewModel.recentDesigns.isEmpty {
                    Task {
                        await viewModel.fetchRecentDesigns()
                    }
                }
            }
        }
    }

    // MARK: Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Welcome back,")
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: AppTheme.Spacing.sm) {
                Text(viewModel.userName)
                    .font(AppTheme.largeTitle)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(AppConstants.App.name)
                    .font(AppTheme.title)
                    .foregroundStyle(AppTheme.accentGradient)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppTheme.Spacing.md)
    }

    // MARK: Quick Actions

    private var quickActionsSection: some View {
        QuickActionGrid(
            actions: viewModel.quickActions,
            onActionTapped: handleQuickAction
        )
    }

    // MARK: Recent Designs

    private var recentDesignsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Recent Designs")
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                NavigationLink {
                    // Placeholder destination for saved designs
                    SavedDesignsGridView()
                } label: {
                    Text("See All")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.accent)
                }
            }

            if viewModel.isLoading {
                loadingPlaceholder
            } else if viewModel.recentDesigns.isEmpty {
                emptyState
            } else {
                recentDesignsScrollView
            }
        }
    }

    private var recentDesignsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: AppTheme.Spacing.md) {
                ForEach(viewModel.recentDesigns) { design in
                    RecentDesignCard(design: design)
                }
            }
        }
    }

    private var loadingPlaceholder: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(AppTheme.surface)
                    .frame(width: 200, height: 240)
                    .shimmer()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary)

            Text("No designs yet")
                .font(AppTheme.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Start by scanning a room or creating a virtual design.")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }

    // MARK: Actions

    private func handleQuickAction(_ action: QuickAction) {
        switch action.title {
        case "AR Scan":
            selectedTab = 1
        case "Virtual Design":
            selectedTab = 2
        case "Catalog":
            selectedTab = 3
        case "AI Advisor":
            selectedTab = 4
        default:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
}
