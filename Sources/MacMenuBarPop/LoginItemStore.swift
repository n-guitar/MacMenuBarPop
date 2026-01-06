import Foundation
import ServiceManagement

final class LoginItemStore: ObservableObject {
  @Published private(set) var isEnabled: Bool = SMAppService.mainApp.status == .enabled

  func refresh() {
    isEnabled = SMAppService.mainApp.status == .enabled
  }

  func setEnabled(_ enabled: Bool) {
    let service = SMAppService.mainApp
    do {
      if enabled {
        try service.register()
      } else {
        try service.unregister()
      }
    } catch {
      print("Login item update failed: \(error.localizedDescription)")
    }
    refresh()
  }
}
