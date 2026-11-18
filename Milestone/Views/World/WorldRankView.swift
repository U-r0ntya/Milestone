import SwiftUI

// サブ看板のランクの表示：ランク名・次までの日数・進み具合のバー・減点の説明
struct WorldRankView: View {
    let rank: WorldRank
    var isGlass: Bool = false  // 一覧のガラスの上に置くか（文字を白にする）

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 上の段：ランク名と、次まであと何日
            HStack(alignment: .firstTextBaseline) {
                Text(rank.title)
                    .font(.headline)
                    .foregroundStyle(isGlass ? .white : Color.appTextPrimary)
                Spacer(minLength: 8)
                Text("\(rank.nextName) まで あと\(rank.daysToNext)日")
                    .font(.caption)
                    .foregroundStyle(secondaryColor)
            }

            // 進み具合のバー
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(isGlass ? Color.white.opacity(0.2) : Color.primary.opacity(0.1))  // 下地
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
                    .foregroundStyle(secondaryColor)
            }
        }
    }

    // 小さい文字の色
    private var secondaryColor: Color {
        isGlass ? .white.opacity(0.78) : Color.appTextSecondary
    }
}
