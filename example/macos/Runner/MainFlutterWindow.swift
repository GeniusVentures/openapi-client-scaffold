import Cocoa
import FlutterMacOS

// Minimum window size, derived from the MediaControls bar: 3 48px buttons +
// 2 ~66px time labels + spacers + demo padding ≈ 346px of fixed content,
// leaving only ~14px of track at a 360px window — labels overlap the bar.
// The seekbar needs a usable minimum of ~3x the thumb diameter (60px) to
// read as a bar. Clamp the window so the bar always has room rather than
// letting the Row compress into overlap.
private let kMinContentWidth: CGFloat = 420
private let kMinContentHeight: CGFloat = 480

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    self.contentMinSize = NSSize(width: kMinContentWidth, height: kMinContentHeight)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
