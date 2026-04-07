import AppKit
import SwiftUI

/// A borderless floating panel anchored to the menu bar status item.
/// Replaces MenuBarExtra for full control over presentation, dismissal, and styling.
final class FloatingPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false

        // Round corners
        if let contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 12
            contentView.layer?.masksToBounds = true
        }
    }

    /// Embed a SwiftUI view as the panel content.
    func setContent<V: View>(_ view: V) {
        let hostingView = NSHostingView(rootView: view)
        contentView = hostingView
    }

    /// Show the panel anchored below the given status item button.
    func show(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonFrame = buttonWindow.frame
        let panelWidth = frame.width
        let panelHeight = frame.height

        // Position: centered below the status item, with a small gap
        let x = buttonFrame.midX - panelWidth / 2
        let y = buttonFrame.minY - panelHeight - 4

        setFrameOrigin(NSPoint(x: x, y: y))
        makeKeyAndOrderFront(nil)
    }

    /// Hide the panel.
    func dismiss() {
        orderOut(nil)
    }

    /// Toggle visibility.
    func toggle(relativeTo button: NSStatusBarButton) {
        if isVisible {
            dismiss()
        } else {
            show(relativeTo: button)
        }
    }

    // MARK: - Dismiss on click outside

    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        // Auto-dismiss when clicking outside the panel
        dismiss()
    }
}
