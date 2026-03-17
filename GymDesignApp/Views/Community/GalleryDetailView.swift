import SwiftUI

// MARK: - Gallery Detail View

struct GalleryDetailView: View {

    let post: CommunityPost
    @ObservedObject var viewModel: CommunityGalleryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedImageIndex = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image gallery
                    imageGallery

                    VStack(alignment: .leading, spacing: 16) {
                        // User info
                        userInfoSection

                        // Design name
                        Text(post.designName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.appTextPrimary)

                        // Dimensions & cost row
                        metricsRow

                        // Description
                        if !post.description.isEmpty {
                            Text(post.description)
                                .font(.system(size: 15))
                                .foregroundStyle(Color.appTextSecondary)
                                .lineSpacing(4)
                        }

                        // Equipment list
                        if !post.equipmentTags.isEmpty {
                            equipmentSection
                        }

                        // Action buttons
                        actionButtons
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: "\(post.designName) by \(post.userName) - GymDesign AR",
                    subject: Text(post.designName),
                    message: Text(post.description)
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
    }

    // MARK: - Image Gallery

    private var imageGallery: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(max(post.imageURLs.count, 1).indices), id: \.self) { index in
                ZStack {
                    LinearGradient(
                        colors: [Color.appSurface, Color.appSurfaceLight.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    VStack(spacing: 8) {
                        Image(systemName: "cube.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.appTextTertiary.opacity(0.4))
                        Text("Design Preview \(index + 1)")
                            .font(.caption)
                            .foregroundStyle(Color.appTextTertiary)
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    // MARK: - User Info

    private var userInfoSection: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appAccent.opacity(0.6), Color.appAccentSecondary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(String(post.userName.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(post.userName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Text(post.relativeDate)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextTertiary)
            }

            Spacer()
        }
    }

    // MARK: - Metrics Row

    private var metricsRow: some View {
        HStack(spacing: 16) {
            // Dimensions
            if !post.roomDimensions.isEmpty {
                metricBadge(icon: "ruler", value: post.roomDimensions)
            }

            // Cost
            if let cost = post.formattedCost {
                metricBadge(icon: "dollarsign.circle", value: cost)
            }

            Spacer()
        }
    }

    private func metricBadge(icon: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.appAccent)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.appSurface, in: Capsule())
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Equipment")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            ForEach(post.equipmentTags, id: \.self) { tag in
                HStack(spacing: 10) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appAccent)
                    Text(tag)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appTextPrimary)
                    Spacer()
                }
                .padding(.vertical, 6)

                if tag != post.equipmentTags.last {
                    Divider().overlay(Color.appDivider)
                }
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Like + Share row
            HStack(spacing: 12) {
                Button {
                    viewModel.toggleLike(postID: post.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        Text(post.isLiked ? "Liked" : "Like")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(post.isLiked ? Color.appError : Color.appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                }

                ShareLink(
                    item: "\(post.designName) - GymDesign AR",
                    subject: Text(post.designName)
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                }
            }

            // Use as Template
            AccentButton(title: "Use as Template", icon: "doc.on.doc") {
                // Future: import design as template
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GalleryDetailView(
            post: CommunityGalleryViewModel.hardcodedMockPosts[1],
            viewModel: CommunityGalleryViewModel()
        )
    }
    .preferredColorScheme(.dark)
}
