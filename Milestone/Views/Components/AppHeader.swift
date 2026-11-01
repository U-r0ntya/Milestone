import SwiftUI

// 各タブの画面に、濃い紫の帯と白いタイトルを付ける
struct AppHeader: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)                           // 画面の背景
            .navigationTitle(title)                                    // 帯のタイトル
            .navigationBarTitleDisplayMode(.inline)                    // タイトルを帯の中央に小さく
            .toolbarBackground(Color.appFrame, for: .navigationBar)    // 帯を濃い紫に
            .toolbarBackground(.visible, for: .navigationBar)          // 帯の色をいつも表示
            .toolbarColorScheme(.dark, for: .navigationBar)            // 帯の文字を白に
    }
}

// .appHeader("タイトル") と1行で付けられるようにする
extension View {
    func appHeader(_ title: String) -> some View {
        modifier(AppHeader(title: title))
    }
}
