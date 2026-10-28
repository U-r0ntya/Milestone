import SwiftUI

// 技術検証用：仮の API から投稿を読んで並べる（確かめたら消す）
struct MockTimelineView: View {
    private let repository: PostRepository = MockAPIPostRepository()

    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                        Button("もう一度試す") {
                            Task { await load() }
                        }
                    }
                } else if posts.isEmpty {
                    Text("まだ投稿がありません")
                } else {
                    List(posts) { post in
                        PostRowForCheck(post: post)
                    }
                }
            }
            .navigationTitle("タイムライン（検証）")
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            posts = try await repository.fetchTimeline()
        } catch {
            // どこで失敗したかわかるように、エラーの中身も出す
            errorMessage = "読み込めませんでした：\(error)"
        }
        isLoading = false
    }
}

// 1件分の表示（確かめるための簡単なもの）
private struct PostRowForCheck: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(post.userName)
                    .font(.headline)
                Spacer()
                // 「2時間前」のように出す
                Text(post.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(post.text)

            if !post.tags.isEmpty {
                Text(post.tags.map { "#\($0)" }.joined(separator: " "))
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            if let version = post.version, let device = post.device {
                Text("\(device.displayName)・\(version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if post.hasJoinInfo {
                Text("参加方法あり")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 16) {
                Label("\(post.replyCount)", systemImage: "bubble.right")
                Label("\(post.likeCount)", systemImage: "heart")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MockTimelineView()
}
