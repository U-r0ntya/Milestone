import SwiftUI

// ワールドの一覧で使う色とアイコン（ゲームモード・難易度ごと）
// 色は Assets.xcassets/Colors/World の Color Set（ライト・ダークで自動で切りかわる）

extension GameMode {
    // 大看板のアイコン（SF Symbols の名前）
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
