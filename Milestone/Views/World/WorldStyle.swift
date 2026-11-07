import SwiftUI

// ワールドの一覧で使う色とアイコン（ゲームモード・難易度ごと）
// 色は Assets.xcassets/Colors/World の Color Set（ライト・ダークで自動で切りかわる）

extension GameMode {
    // 大看板の背景の色
    var bannerColor: Color {
        switch self {
        case .survival: Color.appModeSurvival
        case .creative: Color.appModeCreative
        case .adventure: Color.appModeAdventure
        case .spectator: Color.appModeSpectator
        }
    }

    // サブ看板の背景の色（薄い色）
    var tintColor: Color {
        switch self {
        case .survival: Color.appModeSurvivalTint
        case .creative: Color.appModeCreativeTint
        case .adventure: Color.appModeAdventureTint
        case .spectator: Color.appModeSpectatorTint
        }
    }

    // サブ看板の強調文字の色
    var accentColor: Color {
        switch self {
        case .survival: Color.appModeSurvivalAccent
        case .creative: Color.appModeCreativeAccent
        case .adventure: Color.appModeAdventureAccent
        case .spectator: Color.appModeSpectatorAccent
        }
    }

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

extension Difficulty {
    // 難易度のラベルの背景の色
    var labelBackgroundColor: Color {
        switch self {
        case .peaceful: Color.appDifficultyPeacefulBackground
        case .easy: Color.appDifficultyEasyBackground
        case .normal: Color.appDifficultyNormalBackground
        case .hard: Color.appDifficultyHardBackground
        }
    }

    // 難易度のラベルの文字の色
    var labelTextColor: Color {
        switch self {
        case .peaceful: Color.appDifficultyPeacefulText
        case .easy: Color.appDifficultyEasyText
        case .normal: Color.appDifficultyNormalText
        case .hard: Color.appDifficultyHardText
        }
    }
}
