import SwiftUI

struct ProgressBarView: View {
    let track: Track
    var onSeek: ((Double) -> Void)?

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)
                        .frame(height: 4)

                    Capsule()
                        .fill(.primary)
                        .frame(width: geo.size.width * track.progress, height: 4)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let fraction = max(0, min(1, value.location.x / geo.size.width))
                            onSeek?(fraction)
                        }
                )
            }
            .frame(height: 4)

            HStack {
                Text(track.formattedCurrentTime)
                Spacer()
                Text(track.formattedDuration)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
    }
}
