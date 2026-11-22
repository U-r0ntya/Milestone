import SwiftUI

// 2 列に並べる正方形のタイル（天気アプリの形式：見出し・大きな値・下にひとこと）
struct WorldInfoTile: View {
    let title: String
    let systemImage: String
    let value: String  // 大きな値（改行も使える）
    var valueSize: CGFloat = 26
    var emphasis: String? = nil  // ひとことの上に出す、太字の行（難易度の「ゾンビはハートを〇個奪う」）
    var note: String? = nil  // いちばん下のひとこと
    var noteSize: CGFloat = 13

    var body: some View {
        // 幅に合わせた正方形の枠を作り、その上に、見出しがくっつくカードを重ねる
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                WorldStickyCard(title: title, systemImage: systemImage) {
                    content
                }
            }
            .accessibilityElement(children: .combine)
    }

    // 見出しの下の中身（大きな値・ひとこと）
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(size: valueSize))
                .monospacedDigit()
                .lineSpacing(2)
                .minimumScaleFactor(0.6)
                .padding(.top, 4)

            Spacer(minLength: 4)

            if let emphasis {
                // 1 行に入れば 1 行、入らなければ 2 行にする
                ViewThatFits(in: .horizontal) {
                    Text(emphasis)
                        .lineLimit(1)
                    Text(emphasis)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .font(.system(size: 12, weight: .bold))
            }
            if let note {
                Text(note)
                    .font(.system(size: noteSize))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)  // 正方形の高さいっぱいに広げる
    }
}
