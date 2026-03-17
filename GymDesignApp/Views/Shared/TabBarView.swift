import SwiftUI

/// The primary tab identifiers used throughout the app.
enum AppTab: Int, CaseIterable, Identifiable {
    case home, design, catalog, community, profile

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .home:      return "Home"
        case .design:    return "Design"
        case .catalog:   return "Catalog"
        case .community: return "Community"
        case .profile:   return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home:      return "house.fill"
        case .design:    return "cube.fill"
        case .catalog:   return "square.grid.2x2.fill"
        case .community: return "person.3.fill"
        case .profile:   return "person.circle.fill"
        }
    }
}

/// Custom floating glassmorphism tab bar with animated selection indicator.
struct TabBarView: View {
    @State private var selectedTab: AppTab = .home
    @Namespace private var tabNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Content
            Group {
                switch selectedTab {
                case .home:
                    HomeViewPlaceholder()
                case .design:
                    ARDesignViewPlaceholder()
                case .catalog:
                    CatalogViewPlaceholder()
                case .community:
                    CommunityGalleryViewPlaceholder()
                case .profile:
                    ProfileViewPlaceholder()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Floating Tab Bar
            floatingTabBar
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Tab Bar

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabItem(for: tab)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
    }

    // MARK: - Single Tab Item

    private func tabItem(for tab: AppTab) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selectedTab == tab {
                        Capsule()
                            .fill(Color.appAccent.opacity(0.18))
                            .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                            .frame(width: 48, height: 32)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selectedTab == tab ? Color.appAccent : Color.appTextTertiary)
                        .symbolEffect(.bounce, value: selectedTab == tab)
                }
                .frame(height: 32)

                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? Color.appAccent : Color.appTextTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Views (replaced once real views exist)

private struct HomeViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Home").foregroundStyle(.white)
        }
    }
}

private struct ARDesignViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("AR Design").foregroundStyle(.white)
        }
    }
}

private struct CatalogViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Catalog").foregroundStyle(.white)
        }
    }
}

private struct CommunityGalleryViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Community").foregroundStyle(.white)
        }
    }
}

private struct ProfileViewPlaceholder: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("Profile").foregroundStyle(.white)
        }
    }
}

#Preview {
    TabBarView()
        .preferredColorScheme(.dark)
}
