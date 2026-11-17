import Foundation

// ワールドの情報で使う型。Firestore には英語の名前（rawValue）を文字で保存する
// level.dat の数字から、これらの型に変える処理は、Services/LevelDatParser.swift にある
//
// enum に付けているもの
// - String：各 case に文字の値（rawValue）を付ける。書かなければ case の名前そのまま（.survival → "survival"）
// - Codable：Firestore や JSON と変換できる。enum は rawValue の文字で保存・読み込みされる
// - CaseIterable：全部の case の一覧（GameMode.allCases）が使える。Picker で全部並べるのに使う

// ゲームモード
enum GameMode: String, Codable, CaseIterable {
    case survival
    case creative
    case adventure
    case spectator

    // 画面に出す名前
    var displayName: String {
        switch self {
        case .survival: "サバイバル"
        case .creative: "クリエイティブ"
        case .adventure: "アドベンチャー"
        case .spectator: "スペクテイター"
        }
    }
}

// 難易度
enum Difficulty: String, Codable, CaseIterable {
    case peaceful
    case easy
    case normal
    case hard

    // 画面に出す名前
    var displayName: String {
        switch self {
        case .peaceful: "ピース"
        case .easy: "イージー"
        case .normal: "ノーマル"
        case .hard: "ハード"
        }
    }
}

// ワールドの種類
enum WorldType: String, Codable, CaseIterable {
    case legacy
    case infinite
    case flat

    // 画面に出す名前
    var displayName: String {
        switch self {
        case .legacy: "旧式"
        case .infinite: "無限"
        case .flat: "フラット"
        }
    }
}

// プレイヤーの権限
enum PermissionLevel: String, Codable, CaseIterable {
    case visitor
    case member
    case `operator`  // operator は Swift のキーワードなので ` で囲む

    // 画面に出す名前
    var displayName: String {
        switch self {
        case .visitor: "訪問者"
        case .member: "メンバー"
        case .operator: "オペレーター"
        }
    }
}

// ブロックの位置（スポーン地点など）
struct BlockPosition: Codable, Hashable {
    let x: Int
    let y: Int
    let z: Int
}
