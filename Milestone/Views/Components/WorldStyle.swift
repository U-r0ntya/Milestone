import SwiftUI

// ゲームモードのアイコンと、難易度を出すかどうか

extension GameMode {
    // ゲームモードのアイコン（SF Symbols の名前）
    var iconName: String {
        switch self {
        case .survival: "heart.fill"
        case .creative: "infinity"
        case .adventure: "safari"
        case .spectator: "eye"
        }
    }

    // 難易度のラベルを出すモードか（サバイバルとアドベンチャーだけ）
    var showsDifficulty: Bool {
        self == .survival || self == .adventure
    }
}
