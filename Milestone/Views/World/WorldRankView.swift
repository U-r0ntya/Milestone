import SwiftUI

// サブ看板のランクの表示：ランク名・次までの日数・進み具合のバー・減点の説明
struct WorldRankView: View {
    let rank: WorldRank

    // ランク名（ネザライトは Lv. を付ける）
    private var title: String {
        if let level = rank.level {
            "ネザライト Lv.\(level)"
        } else {
            "\(rank.tier.displayName)ランク"
        }
    }

    // 次の目標の名前（ネザライトは次の Lv.、それ以外は次のランク）
    private var nextName: String {
        if let level = rank.level {
            return "Lv.\(level + 1)"
        }
        let tiers = WorldRank.Tier.allCases
        let index = tiers.firstIndex(of: rank.tier)!  // ネザライト以外なら必ず見つかり、次もある
        return tiers[index + 1].displayName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 上の段：ランク名と、次まであと何日
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer(minLength: 8)
                Text("\(nextName) まで あと\(rank.daysToNext)日")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            // 進み具合のバー
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))  // 下地
                    Capsule()
                        .fill(rank.tier.color)
                        .frame(width: proxy.size.width * rank.progress)  // 割合のぶんだけ塗る
                }
            }
            .frame(height: 8)
            .accessibilityElement()
            .accessibilityLabel("次のランクまで")
            .accessibilityValue("\(Int(rank.progress * 100))パーセント")

            // 減点しているときだけ、説明を出す
            if rank.multiplier < 1 {
                Text("チートやクリエイティブを使ったので、日数の点は ×\(rank.multiplier.formatted())")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }
}
