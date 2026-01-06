import Cocoa
import ApplicationServices

final class MenuBarScanner {
  private let debugEnabled = ProcessInfo.processInfo.environment["AX_DEBUG"] == "1"

  func checkTrust(prompt: Bool) -> Bool {
    guard prompt else {
      return AXIsProcessTrusted()
    }

    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
  }

  func fetchItems() -> [MenuBarItem] {
    if debugEnabled {
      print("[AX DEBUG] AXIsProcessTrusted=\(AXIsProcessTrusted())")
    }
    guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systemuiserver").first else {
      return []
    }

    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    let menuBars = fetchMenuBarElements(from: appElement)
    if debugEnabled {
      debugDump(element: appElement, label: "SystemUIServer root")
    }

    var items: [MenuBarItem] = []
    for menuBar in menuBars {
      items.append(contentsOf: fetchItems(from: menuBar))
      if debugEnabled {
        debugDump(element: menuBar, label: "MenuBar element")
      }
    }
    if items.isEmpty {
      let systemWide = AXUIElementCreateSystemWide()
      if debugEnabled {
        debugDump(element: systemWide, label: "SystemWide root")
        let systemWideMenuBars = fetchMenuBarElements(from: systemWide)
        for menuBar in systemWideMenuBars {
          debugDump(element: menuBar, label: "SystemWide MenuBar element")
        }
      }
      items = fetchItemsByWalkingTree(from: appElement)
      if items.isEmpty {
        items = fetchItemsByWalkingTree(from: systemWide)
      }
      if items.isEmpty {
        items = fetchItemsFromRunningApps()
      }
    }

    let thirdParty = items.filter { !$0.isSystemItem }
    return thirdParty.isEmpty ? items : thirdParty
  }

  private func fetchMenuBarElements(from appElement: AXUIElement) -> [AXUIElement] {
    var results: [AXUIElement] = []

    if let extras: AXUIElement = copyAttribute(appElement, attribute: kAXExtrasMenuBarAttribute) {
      results.append(extras)
    }

    if let menuBar: AXUIElement = copyAttribute(appElement, attribute: kAXMenuBarAttribute) {
      results.append(menuBar)
    }

    if results.isEmpty {
      let children: [AXUIElement] = copyAttribute(appElement, attribute: kAXChildrenAttribute) ?? []
      if let found = children.first(where: { element in
        let role: String? = copyAttribute(element, attribute: kAXRoleAttribute)
        return role == kAXMenuBarRole as String
      }) {
        results.append(found)
      }
    }

    return results
  }

  private func fetchItemsFromRunningApps() -> [MenuBarItem] {
    var results: [MenuBarItem] = []
    for app in NSWorkspace.shared.runningApplications {
      guard app.processIdentifier != 0 else { continue }
      let appElement = AXUIElementCreateApplication(app.processIdentifier)
      guard let extras: AXUIElement = copyAttribute(appElement, attribute: kAXExtrasMenuBarAttribute) else { continue }
      let children: [AXUIElement] = copyAttribute(extras, attribute: kAXChildrenAttribute) ?? []
      let items = children.compactMap { element -> MenuBarItem? in
        let role: String? = copyAttribute(element, attribute: kAXRoleAttribute)
        let subrole: String? = copyAttribute(element, attribute: kAXSubroleAttribute)
        guard isMenuBarItem(role: role, subrole: subrole) else { return nil }
        return makeItem(from: element, sourceName: app.localizedName, sourceBundleID: app.bundleIdentifier, sourceIcon: app.icon)
      }
      if debugEnabled, !items.isEmpty {
        let label = app.bundleIdentifier ?? app.localizedName ?? "pid:\(app.processIdentifier)"
        print("[AX DEBUG] Found \(items.count) items in \(label)")
      }
      results.append(contentsOf: items)
    }
    return results
  }

  private func fetchItems(from menuBar: AXUIElement?) -> [MenuBarItem] {
    guard let menuBar else { return [] }
    let children: [AXUIElement] = copyAttribute(menuBar, attribute: kAXChildrenAttribute) ?? []
    return children.compactMap { element in
      let role: String? = copyAttribute(element, attribute: kAXRoleAttribute)
      let subrole: String? = copyAttribute(element, attribute: kAXSubroleAttribute)
      guard isMenuBarItem(role: role, subrole: subrole) else { return nil }
      return makeItem(from: element, sourceName: nil, sourceBundleID: nil, sourceIcon: nil)
    }
  }

  private func fetchItemsByWalkingTree(from root: AXUIElement) -> [MenuBarItem] {
    var seen = Set<UInt>()
    var results: [MenuBarItem] = []

    func walk(_ element: AXUIElement, depth: Int) {
      if depth > 6 { return }
      let key = UInt(bitPattern: Unmanaged.passUnretained(element).toOpaque())
      if seen.contains(key) { return }
      seen.insert(key)

      let role: String? = copyAttribute(element, attribute: kAXRoleAttribute)
      let subrole: String? = copyAttribute(element, attribute: kAXSubroleAttribute)
      if isMenuBarItem(role: role, subrole: subrole) {
        results.append(makeItem(from: element, sourceName: nil, sourceBundleID: nil, sourceIcon: nil))
        if debugEnabled {
          debugDump(element: element, label: "Found menu bar item")
        }
        return
      }

      let children: [AXUIElement] = copyAttribute(element, attribute: kAXChildrenAttribute) ?? []
      for child in children {
        walk(child, depth: depth + 1)
      }
    }

    walk(root, depth: 0)
    return results
  }

  private func isMenuBarItem(role: String?, subrole: String?) -> Bool {
    if role == kAXMenuBarItemRole as String {
      return true
    }

    guard let subrole = subrole else { return false }
    return subrole == "AXMenuBarExtra" || subrole == "AXStatusItem"
  }

  private func resolveTitle(for element: AXUIElement) -> String {
    let title: String? = copyAttribute(element, attribute: kAXTitleAttribute)
    if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return title
    }

    let description: String? = copyAttribute(element, attribute: kAXDescriptionAttribute)
    if let description, !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return description
    }

    let identifier: String? = copyAttribute(element, attribute: kAXIdentifierAttribute)
    if let identifier, !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return identifier
    }

    return "(Untitled)"
  }

  private func resolveIcon(for element: AXUIElement, fallback: NSImage?) -> NSImage? {
    let imageAttribute = "AXImage"
    if let image: NSImage = copyAttribute(element, attribute: imageAttribute) {
      return image
    }
    if let image: CGImage = copyAttribute(element, attribute: imageAttribute) {
      return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }
    return fallback
  }

  private func makeItem(from element: AXUIElement, sourceName: String?, sourceBundleID: String?, sourceIcon: NSImage?) -> MenuBarItem {
    let title = resolveTitle(for: element)
    let identifier: String? = copyAttribute(element, attribute: kAXIdentifierAttribute)
    let icon = resolveIcon(for: element, fallback: sourceIcon)
    let isSystemItem = (sourceBundleID ?? identifier)?.hasPrefix("com.apple.") == true
    return MenuBarItem(
      element: element,
      title: title,
      sourceName: sourceName,
      sourceBundleID: sourceBundleID,
      icon: icon,
      isSystemItem: isSystemItem
    )
  }

  private func copyAttribute<T>(_ element: AXUIElement, attribute: String) -> T? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
    guard result == .success else {
      if debugEnabled && (attribute == kAXChildrenAttribute || attribute == kAXMenuBarAttribute || attribute == kAXWindowsAttribute || attribute == kAXExtrasMenuBarAttribute) {
        print("[AX DEBUG] copyAttribute failed: \(attribute) -> \(result.rawValue)")
      }
      return nil
    }
    return value as? T
  }

  private func debugDump(element: AXUIElement, label: String) {
    let role: String? = copyAttribute(element, attribute: kAXRoleAttribute)
    let subrole: String? = copyAttribute(element, attribute: kAXSubroleAttribute)
    let title: String? = copyAttribute(element, attribute: kAXTitleAttribute)
    let desc: String? = copyAttribute(element, attribute: kAXDescriptionAttribute)
    let identifier: String? = copyAttribute(element, attribute: kAXIdentifierAttribute)
    let children: [AXUIElement] = copyAttribute(element, attribute: kAXChildrenAttribute) ?? []

    let roleText = role ?? "nil"
    let subroleText = subrole ?? "nil"
    let titleText = title ?? "nil"
    let descText = desc ?? "nil"
    let identifierText = identifier ?? "nil"

    print("[AX DEBUG] \(label)")
    print("  role=\(roleText) subrole=\(subroleText) title=\(titleText) desc=\(descText) id=\(identifierText) children=\(children.count)")
  }
}
