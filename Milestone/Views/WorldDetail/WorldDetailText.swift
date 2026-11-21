import Foundation

// ワールドの情報の画面に出す、ひとことの文（README の「日数の区切り」「難易度の目安」の決まり）

extension World {
    // ワールドの日数（time は 24000 で 1 日。level.dat に入っていなければ nil）
    var days: Int? {
        time.map { Int($0 / 24000) }
    }

    // 最後に超えた日数の区切り（10・100・300・500・1000・1500・2000・3000、その先は 1000 ごと）
    // まだ 10 日に届いていなければ nil
    var passedMilestone: Int? {
        guard let days, days >= 10 else { return nil }
        if days >= 3000 {
            return days / 1000 * 1000  // 1000 ごと（切り捨て）
        }
        let milestones = [10, 100, 300, 500, 1000, 1500, 2000, 3000]
        return milestones.last { $0 <= days }
    }
}

extension Difficulty {
    // ノーマルとくらべた、敵の攻撃力（イージーとハードだけ）
    var attackRatioText: String? {
        switch self {
        case .easy: "ノーマルの約0.83倍"
        case .hard: "ノーマルの1.5倍"
        case .normal, .peaceful: nil
        }
    }

    // 難易度のタイルの説明（ゾンビの攻撃の目安。ピースフルは敵が出ないので、そのことを書く）
    var zombieDamageText: String? {
        switch self {
        case .peaceful: "モンスターを見つけることができません。"
        case .easy: "ゾンビはハートを1.25個奪う"
        case .normal: "ゾンビはハートを1.5個奪う"
        case .hard: "ゾンビはハートを2.25個奪う"
        }
    }
}

extension BlockPosition {
    // 原点から、いちばん遠い向きへ何ブロックか（例：「原点から東へ128」）
    // マイクラでは、X がプラスで東・マイナスで西、Z がプラスで南・マイナスで北
    var directionFromOrigin: String {
        if x == 0 && z == 0 {
            return "原点の上"
        }
        if abs(x) >= abs(z) {
            return "原点から\(x > 0 ? "東" : "西")へ\(abs(x))"
        } else {
            return "原点から\(z > 0 ? "南" : "北")へ\(abs(z))"
        }
    }
}
