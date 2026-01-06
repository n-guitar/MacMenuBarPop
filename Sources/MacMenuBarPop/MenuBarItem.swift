import AppKit
import ApplicationServices
import Foundation

struct MenuBarItem: Identifiable {
  let id = UUID()
  let element: AXUIElement
  let title: String
  let sourceName: String?
  let sourceBundleID: String?
  let icon: NSImage?
  let isSystemItem: Bool

  var displayTitle: String {
    if title != "(Untitled)" {
      return title
    }
    return sourceName ?? title
  }
}
