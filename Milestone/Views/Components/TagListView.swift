import SwiftUI

// タグを横に並べる。入りきる数だけ出し、入りきらないタグは出さない
struct TagListView: View {
    let tags: [String]

    var body: some View {
        // 全部 → 1つ減らす → … → 0個 の順に試して、最初に横幅に収まったものを使う
        ViewThatFits(in: .horizontal) {
            ForEach((0...tags.count).reversed(), id: \.self) { count in
                HStack(spacing: 6) {
                    ForEach(tags.prefix(count), id: \.self) { tag in
                        Text("#\(tag)")
                            .lineLimit(1)
                            .fixedSize()  // タグの文字を「…」に縮めない
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .overlay(
                                Capsule()
                                    .stroke(Color.appCardBorder, lineWidth: 1)  // うすい紫の枠
                            )
                    }
                }
            }
        }
    }
}

#Preview {
    // 幅を狭くして、入りきらないタグが消えるのを確かめる
    TagListView(tags: ["建築", "サバイバル", "村", "交易所", "スポーン付近"])
        .font(.caption)
        .foregroundStyle(.appTextSecondary)
        .frame(width: 200, alignment: .leading)
        .padding()
}
