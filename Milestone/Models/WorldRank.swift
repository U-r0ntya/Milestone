import Foundation

// ワールドのランク（サバイバルだけ）。一覧のカードの枠とバッジの色に使う
// World から毎回計算する（Firestore には保存しない）
// 点 = ワールドの日数 × 倍率（小数は切り捨て）。点が増えると 木 → 石 → … → ネザライト と上がる
// level.dat に日数（time）が入っていなかったワールドは、ランクを出さない
struct WorldRank {
    // ランクの種類（木 → ネザライト）
    enum Tier: CaseIterable {
        case wood  // 木
        case stone  // 石
        case copper  // 銅
        case iron  // 鉄
        case gold  // 金
        case diamond  // ダイヤ
        case netherite  // ネザライト

        // このランクになるのに必要な点（日数 × 倍率）
        var requiredPoints: Int {
            switch self {
            case .wood: 0
            case .stone: 7
            case .copper: 30
            case .iron: 60
            case .gold: 100
            case .diamond: 200
            case .netherite: 365
            }
        }
    }

    let tier: Tier  // 今のランク

    init(world: World) {
        // 日数（time は 24000 で 1 日。level.dat に入っていなかったときは 0 日）
        let days = (world.time ?? 0) / 24000

        // 倍率：チートが有効なら半分、クリエイティブやチートを使ったなら、さらに半分
        var multiplier = 1.0
        if world.commandsEnabled {
            multiplier *= 0.5
        }
        if world.hasUsedCheats == true {  // nil（わからない）のときは使っていない扱い
            multiplier *= 0.5
        }

        // 点（日数 × 倍率。小数は切り捨て）
        let points = Int(Double(days) * multiplier)

        // 今のランク：Tier.allCases（木 → ネザライトの順）の中で、必要な点が今の点以下のいちばん後ろのもの
        tier =
            Tier.allCases.last(where: { $0.requiredPoints <= points })
            ?? .wood
    }
}
