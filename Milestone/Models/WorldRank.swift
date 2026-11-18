import Foundation

// ワールドのランク（サバイバルだけ）
// World から毎回計算する（Firestore には保存しない）
// 点 = ワールドの日数 × 倍率（小数は切り捨て）。点が増えると 木 → 石 → … → ネザライト と上がり、
// ネザライトからは 365 点ごとに Lv. が上がる（上限なし）
// level.dat に日数（time）が入っていなかったワールドは、画面ではランクを出さない
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

        // 画面に出す名前
        var displayName: String {
            switch self {
            case .wood: "木"
            case .stone: "石"
            case .copper: "銅"
            case .iron: "鉄"
            case .gold: "金"
            case .diamond: "ダイヤ"
            case .netherite: "ネザライト"
            }
        }

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

    let multiplier: Double  // 倍率（1.0・0.5・0.25 のどれか）
    let points: Int  // 点（日数 × 倍率。小数は切り捨て）
    let tier: Tier  // 今のランク
    let level: Int?  // ネザライトの Lv.（ネザライト以外は nil）
    let progress: Double  // 次のランク（ネザライトは次の Lv.）までの割合（0〜1）
    let daysToNext: Int  // 次のランク（ネザライトは次の Lv.）まで、あと何日
    let startPoints: Int  // 今のランク（ネザライトは今の Lv.）になった点
    let goalPoints: Int  // 次のランク（ネザライトは次の Lv.）になる点

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
        self.multiplier = multiplier

        // 点（日数 × 倍率。小数は切り捨て）
        let points = Int(Double(days) * multiplier)
        self.points = points

        // 今のランク：Tier.allCases（木 → ネザライトの順）の中で、必要な点が今の点以下のいちばん後ろのもの
        tier =
            Tier.allCases.last(where: { $0.requiredPoints <= points })
            ?? .wood

        // 次のランク（ネザライトは次の Lv.）の点と、次までの割合
        if tier == .netherite {
            // ネザライトの Lv.：365 点で Lv.1、そこから 365 点ごとに 1 つ上がる（切り捨て）
            let currentLevel = 1 + (points - 365) / 365
            level = currentLevel
            startPoints = currentLevel * 365  // 今の Lv. になった点
            goalPoints = startPoints + 365  // 次の Lv. になる点

            // 割合：今の Lv. に入ってから進んだ点 ÷ 1 つの Lv. の幅（365）
            let progressPoints = (points - 365) % 365  // 今の Lv. に入ってから進んだ点
            progress = Double(progressPoints) / 365.0
        } else {
            level = nil  // ネザライト以外は Lv. なし
            let index = Tier.allCases.firstIndex(of: tier)!  // 今のランクが何番目か（ネザライト以外なら必ず見つかる）
            let nextTier = Tier.allCases[index + 1]  // その次のランク
            startPoints = tier.requiredPoints
            goalPoints = nextTier.requiredPoints

            // 割合：今のランクに入ってから進んだ点 ÷ ランクの幅
            let gained = Double(points - tier.requiredPoints)  // 今のランクに入ってから進んだ点
            let width = Double(nextTier.requiredPoints - tier.requiredPoints)  // ランクの幅
            progress = gained / width
        }

        // 次まであと何日（点の差ではなく、日数で数える）
        // 次の点に届く日数（次の点 ÷ 倍率、切り上げ）から、今の日数を引く
        daysToNext = Int((Double(goalPoints) / multiplier).rounded(.up)) - Int(days)
    }

    // その点に届く日数（点 ÷ 倍率、切り上げ）。ランクのバーの両はしに出す
    func days(toReach points: Int) -> Int {
        Int((Double(points) / multiplier).rounded(.up))
    }

    // ランク名（ネザライトは Lv. を付ける）
    var title: String {
        if let level {
            "ネザライト Lv.\(level)"
        } else {
            "\(tier.displayName)ランク"
        }
    }

    // 今のランクの短い名前（バーの左はしに出す）
    var shortName: String {
        if let level {
            "Lv.\(level)"
        } else {
            tier.displayName
        }
    }

    // 次の目標の名前（ネザライトは次の Lv.、それ以外は次のランク）
    var nextName: String {
        if let level {
            return "Lv.\(level + 1)"
        }
        let tiers = Tier.allCases
        let index = tiers.firstIndex(of: tier)!  // ネザライト以外なら必ず見つかり、次もある
        return tiers[index + 1].displayName
    }
}
