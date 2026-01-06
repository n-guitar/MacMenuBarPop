import Foundation
import ApplicationServices

final class MenuBarStore: ObservableObject {
  @Published private(set) var items: [MenuBarItem] = []
  @Published private(set) var isTrusted: Bool = AXIsProcessTrusted()
  @Published private(set) var isRefreshing: Bool = false

  private let scanner = MenuBarScanner()

  func ensureTrust() {
    isTrusted = scanner.checkTrust(prompt: true)
  }

  func refreshAsync() {
    isTrusted = AXIsProcessTrusted()
    guard isTrusted else {
      items = []
      isRefreshing = false
      return
    }
    guard !isRefreshing else { return }
    isRefreshing = true

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      let newItems = self.scanner.fetchItems()
      DispatchQueue.main.async {
        self.items = newItems
        self.isRefreshing = false
      }
    }
  }

  func press(_ item: MenuBarItem) {
    _ = AXUIElementPerformAction(item.element, kAXPressAction as CFString)
  }
}
