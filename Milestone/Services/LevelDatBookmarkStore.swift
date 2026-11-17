import Foundation

enum LevelDatBookmarkStore {
    private static let key = "levelDatBookmarks"

    static func save(_ url: URL, for worldId: String) {

        // ファイルの場所を、「ブックマーク」という Data に変える
        // ブックマーク: 場所と、読んでよいという許可を、いっしょに覚えたデータ
        // resolve()により、もう一度選ばなくても、同じファイルを読める
        guard let data = try? url.bookmarkData() else { return }

        // 保存してある辞書を取る。型は [String: Any],
        // 指定の型として読めるなら、その型にする。読めなければ nil
        var bookmarks =
            UserDefaults.standard.dictionary(forKey: key) as? [String: Data]
            ?? [:]  // 値が「nil」なら、空の辞書 [:]

        // 辞書に、このワールドのブックマークを入れる。「worldId」なければ追加、「worldId」があれば「data」が変更
        bookmarks[worldId] = data

        // 新しい辞書を、key の名前で、端末に保存する
        UserDefaults.standard.set(bookmarks, forKey: key)
    }

    static func resolve(for worldId: String) -> URL? {
        // 保存してある辞書を取る
        let bookmarks =
            UserDefaults.standard.dictionary(forKey: key) as? [String: Data]
            ?? [:]  // 値が「nil」なら、空の辞書 [:]

        guard let data = bookmarks[worldId] else { return nil }

        var isStale = false  // ブックマークが古くなっていないかを受け取る
        do {
            let url = try URL(
                resolvingBookmarkData: data,  // 失敗すればcatch
                bookmarkDataIsStale: &isStale  // &: 結果を変数に値を入れる
            )
            if isStale {
                save(url, for: worldId)  // 新しいブックマークで、上書きする
            }
            return url
        } catch { return nil }
    }
    static func remove(for worldId: String) {
        // 保存してある辞書を取る
        guard
            var bookmarks =
                UserDefaults.standard.dictionary(forKey: key) as? [String: Data]
        else { return }
        // 指定のワールドを削除したものを辞書に変更
        bookmarks.removeValue(forKey: worldId)
        // 新しい辞書を、key の名前で、端末に保存する
        UserDefaults.standard.set(bookmarks, forKey: key)
    }
}
