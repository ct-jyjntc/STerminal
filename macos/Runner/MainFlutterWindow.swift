import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    let preferredSize = NSSize(width: 1100, height: 720)
    let minimumSize = NSSize(width: 900, height: 600)
    self.setContentSize(preferredSize)
    self.minSize = minimumSize

    if let screenFrame = NSScreen.main?.visibleFrame {
      let originX = screenFrame.origin.x + (screenFrame.size.width - preferredSize.width) / 2
      let originY = screenFrame.origin.y + (screenFrame.size.height - preferredSize.height) / 2
      let centeredFrame = NSRect(origin: NSPoint(x: originX, y: originY), size: preferredSize)
      self.setFrame(centeredFrame, display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
