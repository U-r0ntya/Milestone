import Foundation

// ワールドの情報の画面を開いた日時を、端末の中（UserDefaults）に覚えておく係
// 一覧の「最近遊んだワールド」の並びに使う。Firestore には書かない（この端末だけの記録）
enum WorldOpenedStore {
    // UserDefaults に保存するときの名前
    private static let key = "worldOpenedDates"

    // 保存してある辞書（ワールドの ID → 開いた日時）を返す
    static func all() -> [String: Date] {
        return UserDefaults.standard.dictionary(forKey: key) as? [String: Date]
            ?? [:]
    }

    // このワールドを開いた日時を保存
    static func record(_ date: Date, for worldId: String) {
        var dates = all() 
        dates[worldId] = date
        UserDefaults.standard.set(dates, forKey: key)
    }

    // このワールドの記録を消す
    static func remove(for worldId: String) {
        var dates = all()
        dates.removeValue(forKey: worldId)
        UserDefaults.standard.set(dates, forKey: key)
    }
}
