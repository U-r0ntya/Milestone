import SwiftUI

// タイムライン：投稿の一覧（新しい順）と、投稿ボタン
struct TimelineView: View {
    @State private var viewModel = TimelineViewModel()

    var body: some View {
        // 一覧の上に、右下の投稿ボタンを重ねる
        ZStack(alignment: .bottomTrailing) {
            content

            // 投稿ボタン（フェーズ4で投稿新規作成の画面を開く）
            Button {
                // フェーズ4で作る
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 16)
        }
        .task {
            await viewModel.loadPosts()  // 画面を開いたときに読み込む
        }
    }

    // 投稿があるか・読み込み中か・エラーかで、出すものを切り替える
    @ViewBuilder
    private var content: some View {
        if !viewModel.posts.isEmpty {
            // 投稿の一覧
            ScrollView {
                LazyVStack(spacing: 12) {
                    // 引っ張って更新に失敗したときは、前の投稿を残して上にエラーを出す
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ForEach(viewModel.posts) { post in
                        PostRowView(post: post)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
            }
            .refreshable {
                await viewModel.loadPosts()  // 引っ張って更新
            }
        } else if viewModel.isLoading {
            // 初めての読み込み中
            ProgressView()
        } else if let errorMessage = viewModel.errorMessage {
            // 1件も読めずに失敗した
            ContentUnavailableView {
                Label("読み込めませんでした", systemImage: "wifi.exclamationmark")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("もう一度読み込む") {
                    Task { await viewModel.loadPosts() }
                }
                .buttonStyle(.primary)
            }
        } else {
            // 投稿が0件
            ContentUnavailableView(
                "まだ投稿がありません",
                systemImage: "text.bubble",
                description: Text("右下のボタンから、最初の投稿をしてみよう")
            )
        }
    }
}

#Preview {
    NavigationStack {
        TimelineView()
            .appHeader("タイムライン")
    }
}
