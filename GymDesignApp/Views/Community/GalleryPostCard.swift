import SwiftUI

// MARK: - Gallery Post Card

struct GalleryPostCard: View {

    let post: CommunityPost
    var onLikeTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail placeholder
            thumbnailView

            // User info
            HStack(spacing: 10) {
                userAvatar
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text(post.relativeDate)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appTextTertiary)
                }
                Spacer()
            }

            // Design name + dimensions
            VStack(alignment: .leading, spacing: 4) {
                Text(post.designName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)

                if !post.roomDimensions.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "ruler")
                            .font(.system(size: 10))
                        Text(post.roomDimensions)
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Color.appTextSecondary)
                }
            }

            // Equipment tags
            if !post.equipmentTags.isEmpty {
                equipmentTags
            }

            // Like + comment bar
            HStack(spacing: 20) {
                // Like button
                Button {
                    onLikeTapped()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundStyle(post.isLiked ? Color.appError : Color.appTextSecondary)
                        Text("\(post.likeCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                .buttonStyle(.plain)

                // Comments
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14))
                    Text("\(post.commentCount)")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.appTextSecondary)

                Spacer()

                // Cost badge
                if let cost = post.formattedCost {
                    Text(cost)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.appAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appAccent.opacity(0.12), in: Capsule())
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Thumbnail

    private var thumbnailView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appSurface, Color.appSurfaceLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "cube.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.appTextTertiary.opacity(0.5))
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - User Avatar

    private var userAvatar: some View {
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
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 30, height: 30)
    }

    // MARK: - Equipment Tags

    private var equipmentTags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(post.equipmentTags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appSurfaceLight, in: Capsule())
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        GalleryPostCard(
            post: CommunityGalleryViewModel.hardcodedMockPosts[0],
            onLikeTapped: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
