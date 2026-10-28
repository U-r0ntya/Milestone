import Foundation

// 機種。Firestore や JSON には英語の名前（rawValue）を文字で保存する
enum Device: String, Codable, CaseIterable {
    case nintendoSwitch
    case playStation
    case xbox
    case iPhone
    case iPad
    case android
    case windows
    case other

    // 画面に出す名前
    var displayName: String {
        switch self {
        case .nintendoSwitch: "Switch"
        case .playStation: "PlayStation"
        case .xbox: "Xbox"
        case .iPhone: "iPhone"
        case .iPad: "iPad"
        case .android: "Android"
        case .windows: "Windows（PC）"
        case .other: "その他"
        }
    }
}

