import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // The MediaControls bar (3 48px buttons + 2 ~66px time labels + spacers +
    // demo padding ≈ 346px) leaves only ~14px of track at a 360px window, so
    // the labels overlap the bar. The seekbar needs a usable minimum of ~3x
    // the thumb diameter (60px) to read as a bar. Clamp the window so the bar
    // always has room rather than letting the Row compress into overlap.
    self.contentMinSize = NSSize(width: 420, height: 480)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
