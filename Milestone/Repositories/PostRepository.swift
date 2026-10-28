import Foundation

// 投稿を取ってくる係の「約束」（protocol）
// 仮の API でも Firebase でも、この約束どおりに作れば画面からは同じように使える
protocol PostRepository {
    func fetchTimeline() async throws -> [Post]
}

// 仮の API（Gist に置いた JSON）から取ってくる係
struct MockAPIPostRepository: PostRepository {
    // Gist の Raw の URL（版の部分を消した、いつも最新を読む URL）
    let url = URL(string: "https://gist.githubusercontent.com/U-r0ntya/8f58b8cc0e8cb733d6c09938ae56c2a7/raw/posts.json")!

    func fetchTimeline() async throws -> [Post] {
        // 1. URL から JSON を取ってくる
        let (data, response) = try await URLSession.shared.data(from: url)

        // 2. うまく取れたか確かめる（200番台なら成功）
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // 3. JSON を Post の配列に変える
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601   // "2026-10-28T10:00:00Z" を Date に変える
        let posts = try decoder.decode([Post].self, from: data)

        // 4. タイムラインには返信を出さず、新しい順に並べる
        return posts
            .filter { !$0.isReply }
            .sorted { $0.createdAt > $1.createdAt }
    }
}
