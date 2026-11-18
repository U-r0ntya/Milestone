import SwiftUI

// ワールドの情報のいちばん上（天気アプリの「都市名と気温」の位置）
// ワールド名・何日目か・ランク・難易度と次のランクまでの日数
struct WorldDetailHeader: View {
    let world: World
    let rank: WorldRank?  // サバイバルで日数があるときだけ

    // 3 行目：ランク名（ランクがなければゲームモード）
    private var mainLine: String {
        rank?.title ?? world.gameMode.displayName
    }

    // 4 行目：難易度と、次のランクまであと何日（入っているものだけ「・」でつなぐ）
    private var subLine: String? {
        var parts: [String] = []
        if world.gameMode.showsDifficulty, let difficulty = world.difficulty {
            parts.append(difficulty.displayName)
        }
        if let rank {
            parts.append("\(rank.nextName) まで あと\(rank.daysToNext)日")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ・ ")
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(world.displayName)
                .font(.system(size: 30, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            if let days = world.days {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(days)")
                        .font(.system(size: 76, weight: .light))
                        .tracking(-1.5)
                        .monospacedDigit()
                    Text("日目")
                        .font(.system(size: 26))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }

            Text(mainLine)
                .font(.system(size: 17, weight: .medium))
                .padding(.top, 2)

            if let subLine {
                Text(subLine)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 2)
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.25), radius: 6, y: 1)  // 空の上でも文字が読めるように
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
