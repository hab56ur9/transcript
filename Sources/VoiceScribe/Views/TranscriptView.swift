import SwiftUI

struct TranscriptView: View {
    var body: some View {
        let session = AppComposition.session
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(session.lines.indices, id: \.self) { index in
                        Text(session.lines[index])
                            .font(.system(size: 13))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(index)
                    }
                }
                .padding(12)
                .textSelection(.enabled)
            }
            .onChange(of: session.lines.count) { _, _ in
                if let last = session.lines.indices.last {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
    }
}
