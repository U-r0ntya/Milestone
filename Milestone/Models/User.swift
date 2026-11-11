import Foundation

// ユーザー
// - Codable：Firestore に保存する・読むため（プロパティの名前がそのままフィールドの名前になる）
// - Identifiable：id を持っている（ForEach で id: を書かずに使える）
struct User: Codable, Identifiable {
    let id: String  // ユーザー ID（ログインのときに Firebase が作る uid。画面には出さない）
    let name: String  // ユーザー名（最初は Google の名前。本名が出ないように変えられる）
    let iconURL: String?  // アイコンの URL（ない人には既定のアイコン）
    let device: Device  // 機種（初めてのログインのときに選ぶ。ワールドの登録にも使う）
    let bio: String?  // 自己紹介文（150 文字まで）
    var favoriteWorldId: String? = nil  // お気に入りのワールドの ID（1つだけ。一覧の一番上に出す）
}
