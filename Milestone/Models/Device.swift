import Foundation

// ワールドを登録した端末の機種（iPhone・iPad だけ）。Firestore には英語の名前（rawValue）を文字で保存する
enum Device: String, Codable {
    case iPhone
    case iPad

    // 画面に出す名前
    var displayName: String {
        switch self {
        case .iPhone: "iPhone"
        case .iPad: "iPad"
        }
    }
}
