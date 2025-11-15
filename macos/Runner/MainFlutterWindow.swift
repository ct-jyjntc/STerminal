import Cocoa
import FlutterMacOS
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    self.isReleasedWhenClosed = false
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    styleMask.insert(.fullSizeContentView)

    let preferredSize = NSSize(width: 1100, height: 720)
    let minimumSize = NSSize(width: 900, height: 600)
    self.setContentSize(preferredSize)
    self.minSize = minimumSize
    self.maxSize = NSSize(width: 2600, height: 1800)

    if let screenFrame = NSScreen.main?.visibleFrame {
      let originX = screenFrame.origin.x + (screenFrame.size.width - preferredSize.width) / 2
      let originY = screenFrame.origin.y + (screenFrame.size.height - preferredSize.height) / 2
      let centeredFrame = NSRect(origin: NSPoint(x: originX, y: originY), size: preferredSize)
      self.setFrame(centeredFrame, display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { [weak self] controller in
      RegisterGeneratedPlugins(registry: controller)
      DispatchQueue.main.async {
        guard let window = controller.view.window else { return }
        window.alphaValue = 0
        window.orderOut(nil)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.minSize = minimumSize
        window.maxSize = NSSize(width: 2600, height: 1800)
        if let strongSelf = self {
          let baseFrame = strongSelf.frame
          let offsetX: CGFloat = 40
          let offsetY: CGFloat = -40
          var newOrigin = NSPoint(
            x: baseFrame.origin.x + offsetX,
            y: baseFrame.origin.y + offsetY
          )
          var proposedFrame = NSRect(origin: newOrigin, size: baseFrame.size)
          if let screenFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
            if proposedFrame.maxX > screenFrame.maxX {
              proposedFrame.origin.x = screenFrame.maxX - proposedFrame.size.width
            }
            if proposedFrame.minX < screenFrame.minX {
              proposedFrame.origin.x = screenFrame.minX
            }
            if proposedFrame.maxY > screenFrame.maxY {
              proposedFrame.origin.y = screenFrame.maxY - proposedFrame.size.height
            }
            if proposedFrame.minY < screenFrame.minY {
              proposedFrame.origin.y = screenFrame.minY
            }
          }
          window.setFrame(proposedFrame, display: true)
        }
        window.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.15
          window.animator().alphaValue = 1
        }
      }
    }

    super.awakeFromNib()
  }
}
