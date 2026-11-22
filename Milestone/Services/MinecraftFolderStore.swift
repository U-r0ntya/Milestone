import Foundation

// 選んだ「Minecraft」フォルダの場所を、ブックマークにして覚えておく係（端末の中だけ）
// 一度選べば、全部の更新や、ワールドの情報の画面の更新で、選びなおさずに読める
enum MinecraftFolderStore {
    private static let key = "minecraftFolderBookmark"

    // 覚える（読む許可を取っているあいだに呼ぶ）
    static func save(_ url: URL) {
        guard let data = try? url.bookmarkData() else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    // 覚えた場所（まだ選んでいなければ nil）
    static func resolve() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        var isStale = false  // ブックマークが古くなっていないか
        guard
            let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
        else { return nil }
        if isStale, url.startAccessingSecurityScopedResource() {
            save(url)  // 新しいブックマークで、上書きする
            url.stopAccessingSecurityScopedResource()
        }
        return url
    }
}
