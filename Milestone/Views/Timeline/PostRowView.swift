import SwiftUI

// タイムラインの投稿1件（カード）
struct PostRowView: View {
    let post: Post

    // 名前
    private var nameText: some View {
        Text(post.userName)
            .font(.subheadline.bold())
            .foregroundStyle(.appTextPrimary)
            .lineLimit(1)
    }

    // 機種のラベル（機種が入っているときだけ出す）
    @ViewBuilder
    private var deviceLabel: some View {
        if let device = post.device {
            Text(device.displayName)
                .font(.caption2.bold())
                .foregroundStyle(.appTagText)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.appTagBackground)
                .clipShape(Capsule())
                .lineLimit(1)
        }
    }

    // 投稿した時間（「3時間前」「昨日」の形）
    private var timeText: some View {
        Text(
            post.createdAt.formatted(
                .relative(presentation: .named).locale(
                    Locale(identifier: "ja_JP")
                )
            )
        )
        .font(.caption)
        .foregroundStyle(.appTextSecondary)
        .lineLimit(1)
        .padding(.trailing, 8)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // アイコン（今は全員同じ。本物のアイコンはフェーズ7で付ける）
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundStyle(.appCardBorder)

            VStack(alignment: .leading, spacing: 8) {

                // 上の段：横1列で入りきるならそのまま。名前が長くて入りきらないときは、機種のラベルだけ名前の下に置く
                ViewThatFits(in: .horizontal) {
                    // 案1：名前・機種・時間を横1列
                    HStack(spacing: 8) {
                        nameText
                        deviceLabel
                        timeText
                    }

                    // 案2：機種のラベルだけ下の行に
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            nameText
                            timeText
                        }
                        deviceLabel
                    }
                }

                // 本文
                Text(post.text)
                    .font(.body)
                    .foregroundStyle(.appTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 下の段：返信数・いいね数・タグ（数は今は表示だけ。押せるのはフェーズ5）
                HStack(spacing: 0) {
                    // 返信数
                    HStack(spacing: 4) {  // アイコンと数字のすき間
                        Image(systemName: "bubble.right")
                        Text("\(post.replyCount)")
                    }
                    .padding(.trailing, 16)

                    // いいね数
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                        Text("\(post.likeCount)")
                    }
                    .padding(.trailing, 16)
                    // タグ
                    TagListView(tags: post.tags)
                }
                .font(.footnote)
                .foregroundStyle(.appTextSecondary)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.appCard)  // 背景（ライトは白、ダークは濃い紫）
        .clipShape(RoundedRectangle(cornerRadius: 16))  // 角を丸く切り抜く
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appCardBorder, lineWidth: 1)  // 枠線（うすい紫）
        )
    }
}

#Preview {
    PostRowView(
        post: Post(
            id: "preview1",
            userId: "user1",
            replyToPostId: nil,
            text: "拠点の横に村ができてできてた！交易所にしたい拠点の横に村ができてた！交易所にしたい拠点の横に村ができてた！交易所にしたい",
            imageURLs: [],
            createdAt: Date().addingTimeInterval(-3 * 60 * 60),  // 今から3時間前
            tags: ["建築", "サバイバル", "村", "交易所", "スポーン付近"],
            replyCount: 2,
            likeCount: 5,
            userName: "すてぃーぶあ",
            userIconURL: nil,
            version: "1.21.40",
            device: .nintendoSwitch,
            seed: nil,
            realmsCode: nil,
            serverAddress: nil,
            xboxGamertag: nil
        )
    )
    .padding(.horizontal, 8)
    .background(Color.appBackground)
}
