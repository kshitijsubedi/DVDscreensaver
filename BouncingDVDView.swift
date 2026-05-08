import ScreenSaver
import AppKit

@objc(BouncingDVDView)
final class BouncingDVDView: ScreenSaverView {

    private var logoPosition: CGPoint = .zero
    private var velocity: CGPoint = .zero
    private var colorIndex: Int = 0
    private var logoSize: CGSize = .zero
    private var tintedLogos: [NSImage] = []
    private var lastFrameTime: TimeInterval = 0
    private var configWindow: NSWindow?

    private let bundleID = "com.kshitijsubedi.BouncingDVD"

    private let palette: [NSColor] = [
        NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1),
        NSColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1),
        NSColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 1),
        NSColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1),
        NSColor(red: 0.0, green: 0.9, blue: 0.9, alpha: 1),
        NSColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1),
        NSColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1),
        NSColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 1),
    ]

    private var prefs: UserDefaults {
        UserDefaults(suiteName: bundleID) ?? .standard
    }

    private var logoScale: CGFloat {
        let val = prefs.float(forKey: "logoScale")
        return val > 0 ? CGFloat(val) : 1.0
    }

    private var speedMultiplier: CGFloat {
        let val = prefs.float(forKey: "speedMultiplier")
        return val > 0 ? CGFloat(val) : 1.0
    }

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 60.0
        wantsLayer = true
        loadAndPrepareLogo(frameSize: frame.size)
        setupMotion(frame: frame, isPreview: isPreview)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    private func loadAndPrepareLogo(frameSize: CGSize) {
        let bundle = Bundle(for: BouncingDVDView.self)
        guard let path = bundle.path(forResource: "DVD_logo", ofType: "png"),
              let image = NSImage(contentsOfFile: path) else { return }

        let scaled = CGSize(
            width: image.size.width * logoScale,
            height: image.size.height * logoScale
        )
        let maxLogoWidth = frameSize.width * 0.3
        if scaled.width > maxLogoWidth {
            let fit = maxLogoWidth / scaled.width
            logoSize = CGSize(width: scaled.width * fit, height: scaled.height * fit)
        } else {
            logoSize = scaled
        }

        tintedLogos = palette.map { createTintedLogo(source: image, color: $0) }
        colorIndex = Int.random(in: 0..<palette.count)
    }

    private func createTintedLogo(source: NSImage, color: NSColor) -> NSImage {
        let size = source.size
        let tinted = NSImage(size: size)
        tinted.lockFocus()
        color.setFill()
        NSRect(origin: .zero, size: size).fill()
        source.draw(in: NSRect(origin: .zero, size: size),
                     from: .zero, operation: .destinationIn, fraction: 1.0)
        tinted.unlockFocus()
        return tinted
    }

    private func setupMotion(frame: NSRect, isPreview: Bool) {
        let maxX = max(frame.width - logoSize.width, 1)
        let maxY = max(frame.height - logoSize.height, 1)
        logoPosition = CGPoint(
            x: CGFloat.random(in: 0...maxX),
            y: CGFloat.random(in: 0...maxY)
        )
        let baseSpeed: CGFloat = isPreview ? 1.0 : 2.0
        let speed = baseSpeed * speedMultiplier
        velocity = CGPoint(
            x: speed * (Bool.random() ? 1 : -1),
            y: speed * (Bool.random() ? 1 : -1)
        )
        lastFrameTime = CACurrentMediaTime()
    }

    // MARK: - Drawing

    override func draw(_ rect: NSRect) {
        NSColor.black.setFill()
        rect.fill()

        guard !tintedLogos.isEmpty else { return }
        let logo = tintedLogos[colorIndex]
        let drawRect = NSRect(origin: logoPosition, size: logoSize)
        logo.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    override func animateOneFrame() {
        let now = CACurrentMediaTime()
        let dt = now - lastFrameTime
        lastFrameTime = now

        guard dt > 0, dt < 1.0 else { return }

        let targetDt: CGFloat = 1.0 / 60.0
        let scale = CGFloat(dt) / targetDt

        let oldRect = NSRect(origin: logoPosition, size: logoSize)

        logoPosition.x += velocity.x * scale
        logoPosition.y += velocity.y * scale

        var hitEdge = false

        if logoPosition.x <= 0 {
            logoPosition.x = 0
            velocity.x = abs(velocity.x)
            hitEdge = true
        } else if logoPosition.x + logoSize.width >= bounds.width {
            logoPosition.x = bounds.width - logoSize.width
            velocity.x = -abs(velocity.x)
            hitEdge = true
        }

        if logoPosition.y <= 0 {
            logoPosition.y = 0
            velocity.y = abs(velocity.y)
            hitEdge = true
        } else if logoPosition.y + logoSize.height >= bounds.height {
            logoPosition.y = bounds.height - logoSize.height
            velocity.y = -abs(velocity.y)
            hitEdge = true
        }

        if hitEdge {
            var next = Int.random(in: 0..<palette.count)
            while next == colorIndex && palette.count > 1 {
                next = Int.random(in: 0..<palette.count)
            }
            colorIndex = next
        }

        let newRect = NSRect(origin: logoPosition, size: logoSize)
        let dirtyRect = oldRect.union(newRect).insetBy(dx: -2, dy: -2)
        setNeedsDisplay(dirtyRect)
    }

    // MARK: - Configuration Sheet

    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        configWindow = nil

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 200),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = "Bouncing DVD Options"

        let currentScale = logoScale
        let currentSpeed = speedMultiplier

        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]

        let sizeLabel = makeLabel("Logo Size:", frame: NSRect(x: 20, y: 150, width: 100, height: 20))
        let sizeSlider = NSSlider(frame: NSRect(x: 120, y: 150, width: 160, height: 20))
        sizeSlider.minValue = 0.5
        sizeSlider.maxValue = 3.0
        sizeSlider.doubleValue = Double(currentScale)
        sizeSlider.tag = 1
        sizeSlider.isContinuous = true
        sizeSlider.target = self
        sizeSlider.action = #selector(sliderChanged(_:))

        let sizeValue = makeLabel(String(format: "%.1fx", currentScale),
                                  frame: NSRect(x: 288, y: 150, width: 40, height: 20))
        sizeValue.tag = 101

        let speedLabel = makeLabel("Speed:", frame: NSRect(x: 20, y: 110, width: 100, height: 20))
        let speedSlider = NSSlider(frame: NSRect(x: 120, y: 110, width: 160, height: 20))
        speedSlider.minValue = 0.5
        speedSlider.maxValue = 4.0
        speedSlider.doubleValue = Double(currentSpeed)
        speedSlider.tag = 2
        speedSlider.isContinuous = true
        speedSlider.target = self
        speedSlider.action = #selector(sliderChanged(_:))

        let speedValue = makeLabel(String(format: "%.1fx", currentSpeed),
                                   frame: NSRect(x: 288, y: 110, width: 40, height: 20))
        speedValue.tag = 102

        let cancelButton = NSButton(frame: NSRect(x: 130, y: 20, width: 90, height: 32))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.target = self
        cancelButton.action = #selector(cancelConfig(_:))

        let okButton = NSButton(frame: NSRect(x: 230, y: 20, width: 90, height: 32))
        okButton.title = "OK"
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r"
        okButton.target = self
        okButton.action = #selector(saveConfig(_:))

        for v: NSView in [sizeLabel, sizeSlider, sizeValue, speedLabel, speedSlider, speedValue, cancelButton, okButton] {
            contentView.addSubview(v)
        }

        window.contentView = contentView
        configWindow = window
        return window
    }

    private func makeLabel(_ text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(frame: frame)
        label.stringValue = text
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.textColor = .labelColor
        label.font = .systemFont(ofSize: 13)
        return label
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        guard let contentView = configWindow?.contentView else { return }
        let valueTag = sender.tag + 100
        if let label = contentView.viewWithTag(valueTag) as? NSTextField {
            label.stringValue = String(format: "%.1fx", sender.doubleValue)
        }
    }

    @objc private func saveConfig(_ sender: Any) {
        guard let window = configWindow,
              let contentView = window.contentView else { return }

        if let sizeSlider = contentView.viewWithTag(1) as? NSSlider {
            prefs.set(Float(sizeSlider.doubleValue), forKey: "logoScale")
        }
        if let speedSlider = contentView.viewWithTag(2) as? NSSlider {
            prefs.set(Float(speedSlider.doubleValue), forKey: "speedMultiplier")
        }
        prefs.synchronize()

        window.sheetParent?.endSheet(window)
        configWindow = nil
        loadAndPrepareLogo(frameSize: bounds.size)
        setupMotion(frame: bounds, isPreview: false)
    }

    @objc private func cancelConfig(_ sender: Any) {
        guard let window = configWindow else { return }
        window.sheetParent?.endSheet(window)
        configWindow = nil
    }
}
