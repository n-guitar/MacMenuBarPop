import Cocoa
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
  private var statusItem: NSStatusItem!
  private let popover = NSPopover()
  private let store = MenuBarStore()
  private let loginStore = LoginItemStore()
  private var cancellables = Set<AnyCancellable>()

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)

    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let button = statusItem.button {
      button.image = NSImage(systemSymbolName: "rectangle.grid.1x2", accessibilityDescription: "Menu Bar Pop")
      button.target = self
      button.action = #selector(togglePopover(_:))
    }

    popover.behavior = .transient
    popover.contentSize = NSSize(width: 320, height: 320)
    popover.delegate = self
    popover.contentViewController = NSHostingController(rootView: MenuBarListView(store: store, loginStore: loginStore))

    store.$items
      .receive(on: RunLoop.main)
      .sink { [weak self] items in
        self?.updatePopoverSize(itemCount: items.count)
      }
      .store(in: &cancellables)

    store.refreshAsync()
  }

  @objc private func togglePopover(_ sender: Any?) {
    guard let button = statusItem.button else { return }
    if popover.isShown {
      popover.performClose(sender)
      return
    }

    updatePopoverSize(itemCount: store.items.count)
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    store.ensureTrust()
    store.refreshAsync()
    loginStore.refresh()
  }

  private func updatePopoverSize(itemCount: Int) {
    let rowHeight: CGFloat = 34
    let verticalPadding: CGFloat = 32
    let minHeight: CGFloat = 180
    let maxHeight: CGFloat = 520

    let calculated = verticalPadding + (rowHeight * CGFloat(max(itemCount, 1)))
    let height = min(maxHeight, max(minHeight, calculated))
    popover.contentSize = NSSize(width: 320, height: height)
  }

}
