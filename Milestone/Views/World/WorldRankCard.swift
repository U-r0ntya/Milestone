import SwiftUI

// ランクのカード（横長）：ランク名・次まで何日・進み具合のバー・バーの両はしの日数
// 右上の i のボタンを押すと、ランクの説明をふき出しで出す
struct WorldRankCard: View {
    let rank: WorldRank
    @State private var isShowingInfo = false  // ランクの説明を出しているか

    var body: some View {
        WorldStickyCard(title: "ランク") {
            infoButton
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                // ランク名と、次まであと何日
                HStack(alignment: .firstTextBaseline) {
                    Text(rank.title)
                        .font(.system(size: 22, weight: .bold))
                    Spacer(minLength: 8)
                    Text("\(rank.nextName) まで あと\(rank.daysToNext)日")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.85))
                }

                // 進み具合のバー
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.22))  // 下地
                        Capsule()
                            .fill(rank.tier.color)
                            .frame(width: proxy.size.width * rank.progress)  // 割合のぶんだけ塗る
                    }
                }
                .frame(height: 10)
                .padding(.top, 10)
                .accessibilityElement()
                .accessibilityLabel("次のランクまで")
                .accessibilityValue("\(Int(rank.progress * 100))パーセント")

                // バーの左はし（今のランク）・割合・右はし（次のランク）
                HStack {
                    Text("\(rank.shortName) \(rank.days(toReach: rank.startPoints))日")
                    Spacer()
                    Text("\(Int(rank.progress * 100))%")
                    Spacer()
                    Text("\(rank.nextName) \(rank.days(toReach: rank.goalPoints))日")
                }
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 8)
                .accessibilityHidden(true)  // バーの読み上げと重なるので、読まない

                // 減点しているときだけ、説明を出す
                if rank.multiplier < 1 {
                    Text("チートやクリエイティブを使ったので、日数の点は ×\(rank.multiplier.formatted())")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 6)
                }
            }
        }
    }

    // 右上の説明のボタン（見出しといっしょに、上にくっつく）
    private var infoButton: some View {
        Button {
            isShowingInfo = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 44, height: 44)  // 押しやすい大きさ
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, -12)  // アイコンの右はしを、カードの右の余白にそろえる
        .accessibilityLabel("ランクの説明")
        // ふき出し（iPhone でも、全画面ではなく、ボタンから出るふき出しにする）
        .popover(isPresented: $isShowingInfo, arrowEdge: .top) {
            WorldRankInfoView(currentTier: rank.tier)
                .presentationCompactAdaptation(.popover)
        }
    }
}

// ランクの説明（ふき出しの中身）：ランクの決まり方・必要な日数・日数のかけ算
struct WorldRankInfoView: View {
    let currentTier: WorldRank.Tier  // 今のランク（表で目立たせる）

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ランクとは")
                .font(.headline)

            Text("サバイバルのワールドで、遊んだ日数からランクが決まります。")
                .font(.subheadline)

            // ランクと必要な日数の表
            VStack(spacing: 6) {
                ForEach(WorldRank.Tier.allCases, id: \.self) { tier in
                    HStack {
                        Circle()
                            .fill(tier.color)
                            .frame(width: 10, height: 10)
                        Text(tier.displayName)
                        Spacer(minLength: 16)
                        Text(tier == .netherite ? "\(tier.requiredPoints)日〜" : "\(tier.requiredPoints)日")
                            .monospacedDigit()
                    }
                    .font(.subheadline.weight(tier == currentTier ? .bold : .regular))
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(tier == currentTier ? .isSelected : [])
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("ネザライトからは、365日ごとに Lv. が上がります（上限はありません）。")
                Text("チートが有効なら日数は ×0.5、クリエイティブやチートを使ったことがあれば、さらに ×0.5 になります。")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)  // 文を省略せずに、折り返して全部出す
        }
        .padding(20)
        .frame(width: 300)
    }
}
