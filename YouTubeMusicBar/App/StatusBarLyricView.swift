import AppKit

@MainActor
final class StatusBarLyricView: NSView {

    var onPreferredLengthChanged: ((CGFloat) -> Void)?

    private enum Metrics {
        static let controlHeight: CGFloat = 22
        static let horizontalPadding: CGFloat = 8
        static let iconSize: CGFloat = 14
        static let iconSpacing: CGFloat = 6
        static let labelHeight: CGFloat = 16
        static let labelBuckets: [CGFloat] = [48, 72, 96, 120]
        static let marqueeGap: CGFloat = 24
        static let marqueeSpeed: CGFloat = 28
        static let leadingPause: TimeInterval = 0.7
        static let loopPause: TimeInterval = 0.45
        static func font() -> NSFont {
            NSFont.systemFont(ofSize: 12, weight: .medium)
        }
    }

    private let imageView = NSImageView()
    private let clipView = NSView()
    private let primaryLabel = NSTextField(labelWithString: "")
    private let secondaryLabel = NSTextField(labelWithString: "")

    private var displayText = ""
    private var measuredTextWidth: CGFloat = 0
    private var viewportWidth: CGFloat = 0
    private var preferredLengthValue = NSStatusItem.squareLength
    private var marqueeOffset: CGFloat = 0
    private var marqueePauseRemaining: TimeInterval = 0
    private var lastTickDate = Date()
    private var marqueeTimer: Timer?

    var preferredLength: CGFloat { preferredLengthValue }

    override var intrinsicContentSize: NSSize {
        NSSize(width: preferredLengthValue, height: Metrics.controlHeight)
    }

    override var allowsVibrancy: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func layout() {
        super.layout()

        let height = bounds.height
        let iconX = Metrics.horizontalPadding
        imageView.frame = NSRect(
            x: iconX,
            y: round((height - Metrics.iconSize) * 0.5),
            width: Metrics.iconSize,
            height: Metrics.iconSize
        )

        guard !displayText.isEmpty, viewportWidth > 0 else {
            clipView.frame = .zero
            return
        }

        let textX = imageView.frame.maxX + Metrics.iconSpacing
        clipView.frame = NSRect(
            x: textX,
            y: round((height - Metrics.labelHeight) * 0.5),
            width: viewportWidth,
            height: Metrics.labelHeight
        )

        let labelY = round((clipView.bounds.height - Metrics.labelHeight) * 0.5)
        let labelWidth = max(measuredTextWidth, viewportWidth)

        if shouldMarquee {
            let primaryX = -marqueeOffset
            let secondaryX = primaryX + measuredTextWidth + Metrics.marqueeGap

            primaryLabel.frame = NSRect(x: primaryX, y: labelY, width: measuredTextWidth, height: Metrics.labelHeight)
            secondaryLabel.frame = NSRect(x: secondaryX, y: labelY, width: measuredTextWidth, height: Metrics.labelHeight)
            secondaryLabel.isHidden = false
        } else {
            primaryLabel.frame = NSRect(x: 0, y: labelY, width: labelWidth, height: Metrics.labelHeight)
            secondaryLabel.isHidden = true
        }
    }

    func update(symbolName: String, text: String?) {
        imageView.image = symbolImage(named: symbolName)

        let normalizedText = normalized(text)
        let textDidChange = normalizedText != displayText

        if textDidChange {
            displayText = normalizedText
            measuredTextWidth = textWidth(for: normalizedText)
            viewportWidth = preferredViewportWidth(for: measuredTextWidth)
            primaryLabel.stringValue = normalizedText
            secondaryLabel.stringValue = normalizedText
            marqueeOffset = 0
            marqueePauseRemaining = shouldMarquee ? Metrics.leadingPause : 0
            lastTickDate = Date()
        }

        let newPreferredLength = preferredLength(for: viewportWidth)
        if abs(newPreferredLength - preferredLengthValue) > 0.5 {
            preferredLengthValue = newPreferredLength
            invalidateIntrinsicContentSize()
            onPreferredLengthChanged?(newPreferredLength)
        }

        updateTimerState()
        toolTip = displayText.isEmpty ? nil : displayText
        needsLayout = true
    }

    func stopMarqueeAnimation() {
        marqueeTimer?.invalidate()
        marqueeTimer = nil
        marqueeOffset = 0
        marqueePauseRemaining = 0
    }

    @objc private func handleMarqueeTick() {
        guard shouldMarquee else { return }

        let now = Date()
        let delta = now.timeIntervalSince(lastTickDate)
        lastTickDate = now

        if marqueePauseRemaining > 0 {
            marqueePauseRemaining = max(0, marqueePauseRemaining - delta)
            return
        }

        marqueeOffset += Metrics.marqueeSpeed * CGFloat(delta)
        let cycleWidth = measuredTextWidth + Metrics.marqueeGap

        if marqueeOffset >= cycleWidth {
            marqueeOffset = 0
            marqueePauseRemaining = Metrics.loopPause
        }

        needsLayout = true
    }

    private var shouldMarquee: Bool {
        !displayText.isEmpty && measuredTextWidth > viewportWidth + 0.5
    }

    private func setupView() {
        frame.size.height = Metrics.controlHeight

        imageView.imageScaling = .scaleProportionallyDown
        addSubview(imageView)

        clipView.clipsToBounds = true
        addSubview(clipView)

        configureLabel(primaryLabel)
        configureLabel(secondaryLabel)
        clipView.addSubview(primaryLabel)
        clipView.addSubview(secondaryLabel)
        secondaryLabel.isHidden = true

        update(symbolName: "music.note", text: nil)
    }

    private func configureLabel(_ label: NSTextField) {
        label.font = Metrics.font()
        label.textColor = .labelColor
        label.alignment = .left
        label.lineBreakMode = .byClipping
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        label.maximumNumberOfLines = 1
        label.cell?.usesSingleLineMode = true
        label.cell?.wraps = false
        label.cell?.isScrollable = false
    }

    private func normalized(_ text: String?) -> String {
        guard let text else { return "" }
        return text
            .components(separatedBy: .newlines)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func preferredViewportWidth(for measuredWidth: CGFloat) -> CGFloat {
        guard measuredWidth > 0 else { return 0 }

        for bucket in Metrics.labelBuckets where measuredWidth <= bucket {
            return bucket
        }

        return Metrics.labelBuckets.last ?? 120
    }

    private func preferredLength(for viewportWidth: CGFloat) -> CGFloat {
        guard viewportWidth > 0 else { return NSStatusItem.squareLength }
        return Metrics.horizontalPadding * 2 + Metrics.iconSize + Metrics.iconSpacing + viewportWidth
    }

    private func textWidth(for text: String) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let attributes: [NSAttributedString.Key: Any] = [.font: Metrics.font()]
        return ceil((text as NSString).size(withAttributes: attributes).width)
    }

    private func updateTimerState() {
        if shouldMarquee {
            if marqueeTimer == nil {
                lastTickDate = Date()
                marqueeTimer = Timer.scheduledTimer(
                    timeInterval: 1 / 60,
                    target: self,
                    selector: #selector(handleMarqueeTick),
                    userInfo: nil,
                    repeats: true
                )
                RunLoop.main.add(marqueeTimer!, forMode: .common)
            }
            return
        }

        marqueeTimer?.invalidate()
        marqueeTimer = nil
        marqueeOffset = 0
        marqueePauseRemaining = 0
    }

    private func symbolImage(named symbolName: String) -> NSImage? {
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "YT Music")
        image?.isTemplate = true
        let configuration = NSImage.SymbolConfiguration(pointSize: Metrics.iconSize, weight: .medium)
        return image?.withSymbolConfiguration(configuration)
    }
}
