import SwiftUI

// MARK: - Community Gallery View

struct CommunityGalleryView: View {

    @StateObject private var viewModel = CommunityGalleryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter chips
                    filterBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    // Content
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .controlSize(.large)
                            .tint(Color.appAccent)
                        Spacer()
                    } else if viewModel.posts.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        postGrid
                    }
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if viewModel.posts.isEmpty {
                    await viewModel.fetchPosts()
                }
            }
            .refreshable {
                await viewModel.fetchPosts()
            }
            .overlay(alignment: .bottomTrailing) {
                fabButton
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 10) {
            ForEach(GalleryFilter.allCases) { filter in
                Button {
                    viewModel.applyFilter(filter)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: filter.icon)
                            .font(.system(size: 11))
                        Text(filter.displayName)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundStyle(
                        viewModel.selectedFilter == filter
                            ? Color.white
                            : Color.appTextSecondary
                    )
                    .background(
                        viewModel.selectedFilter == filter
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.appAccent, Color.appAccentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                              )
                            : AnyShapeStyle(Color.appSurface),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Post Grid

    private var postGrid: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.posts) { post in
                    NavigationLink(destination: GalleryDetailView(post: post, viewModel: viewModel)) {
                        GalleryPostCard(post: post) {
                            viewModel.toggleLike(postID: post.id)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)  // space for FAB
        }
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            // Future: share own design flow
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appAccentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .shadow(color: Color.appAccent.opacity(0.4), radius: 12, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.appTextTertiary)
            Text("No posts yet")
                .font(.headline)
                .foregroundStyle(Color.appTextSecondary)
            Text("Be the first to share your gym design!")
                .font(.subheadline)
                .foregroundStyle(Color.appTextTertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    CommunityGalleryView()
}
