import SwiftUI

// 見出しが上にくっつく、すりガラスのカード（天気アプリと同じ動き）
// スクロールしてカードの上のはしが画面の上（バーの下）に届くと、見出しだけそこに残り、
// 中身はその下にもぐって見えなくなる。カードが最後まで通りすぎたら、見出しもうすくなって消える
// 位置は、ワールドの情報の画面の座標（.worldDetail）で測る。y = 0 がバーの下
struct WorldStickyCard<Accessory: View, Content: View>: View {
    let title: String
    var systemImage: String? = nil
    var contentPadding = EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)  // 中身のまわりの余白
    @ViewBuilder var accessory: Accessory  // 見出しの右に置くもの（ランクの説明のボタンなど）
    @ViewBuilder var content: Content

    @State private var minY: CGFloat = .infinity  // カードの上のはしの位置（画面の座標）
    @State private var height: CGFloat = 0  // カードの高さ

    private var headerHeight: CGFloat { 34 }  // 見出しの場所の高さ（上の余白 14 ＋ 見出し ＋ 下のすき間）

    var body: some View {
        // カードの上のはしが、バーの下を何ポイント通りすぎたか
        let scrolledPast = max(-minY, 0)
        // 見出しを下にずらす量（中身が全部もぐったら、それ以上はずらさない）
        let push = min(scrolledPast, max(height - headerHeight, 0))
        // カードが最後まで通りすぎるときに、うすくして消す
        let fade = height > 0 ? min(max((height - scrolledPast) / headerHeight, 0), 1) : 1

        VStack(alignment: .leading, spacing: 0) {
            // 見出し（バーの下にくっつく）
            HStack(spacing: 0) {
                WorldCaption(title: title, systemImage: systemImage)
                Spacer(minLength: 0)
            }
            .overlay(alignment: .trailing) { accessory }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .frame(height: headerHeight, alignment: .top)
            .offset(y: push)
            .zIndex(1)  // 中身より上にして、右のボタンも押せるようにする

            // 中身（見出しの下にもぐったところは見せない）
            content
                .padding(contentPadding)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .mask(alignment: .top) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: push)
                        Color.black
                    }
                }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        // すりガラスは、上のはしを見出しの位置まで縮める
        .background {
            Color.clear
                .worldGlass()
                .padding(.top, push)
        }
        .opacity(fade)
        // カードの位置と高さを測る（ずらしても、ここで測る位置は変わらない）
        .onGeometryChange(for: CGRect.self) { geometry in
            geometry.frame(in: .worldDetail)
        } action: { frame in
            minY = frame.minY
            height = frame.height
        }
    }
}

// 右に何も置かないカードは、accessory を書かずに作れるようにする
extension WorldStickyCard where Accessory == EmptyView {
    init(
        title: String,
        systemImage: String? = nil,
        contentPadding: EdgeInsets = EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            systemImage: systemImage,
            contentPadding: contentPadding,
            accessory: { EmptyView() },
            content: content
        )
    }
}

// ワールドの情報の画面の座標（バーの下が y = 0）
extension CoordinateSpaceProtocol where Self == NamedCoordinateSpace {
    static var worldDetail: NamedCoordinateSpace { .named("worldDetail") }
}
