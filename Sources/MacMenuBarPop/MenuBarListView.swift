import AppKit
import SwiftUI

struct MenuBarListView: View {
  @ObservedObject var store: MenuBarStore
  @ObservedObject var loginStore: LoginItemStore

  var body: some View {
    ZStack {
      VisualEffectView(material: .popover, blendingMode: .withinWindow, state: .active)
        .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 12) {
        if !store.isTrusted {
          VStack(alignment: .leading, spacing: 8) {
            Text("Accessibility permission required")
              .font(.headline)
            Text("Open System Settings > Privacy & Security > Accessibility and enable this app.")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          Spacer()
        } else if store.isRefreshing && store.items.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            ProgressView()
            Text("Loading menu bar items...")
              .font(.headline)
          }
          Spacer()
        } else if store.items.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("No menu bar items found")
              .font(.headline)
            Text("No right-side menu bar items are available.")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          Spacer()
        } else {
          List(store.items) { item in
            MenuBarRow(item: item) {
              store.press(item)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
          .frame(maxHeight: .infinity)
        }

        Divider()
          .opacity(0.6)
        HStack {
          Toggle("Start at Login", isOn: Binding(get: {
            loginStore.isEnabled
          }, set: { newValue in
            loginStore.setEnabled(newValue)
          }))
          .toggleStyle(.switch)

          Spacer()

          Button("Quit") {
            NSApp.terminate(nil)
          }
        }
      }
      .padding(12)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

struct MenuBarRow: View {
  let item: MenuBarItem
  let action: () -> Void
  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if let icon = item.icon {
          Image(nsImage: icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
        } else {
          Image(systemName: "menubar.arrow.up.rectangle")
        }
        VStack(alignment: .leading, spacing: 2) {
          Text(item.displayTitle)
            .lineLimit(1)
            .truncationMode(.tail)
          if let sourceName = item.sourceName, sourceName != item.displayTitle {
            Text(sourceName)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(1)
              .truncationMode(.tail)
          }
        }
      }
      .padding(.vertical, 4)
      .padding(.horizontal, 6)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(RoundedRectangle(cornerRadius: 6))
    }
    .buttonStyle(.plain)
    .background(
      RoundedRectangle(cornerRadius: 6)
        .fill(Color(NSColor.controlBackgroundColor))
        .opacity(isHovering ? 0.5 : 0.0)
    )
    .onHover { hovering in
      isHovering = hovering
    }
  }
}

struct VisualEffectView: NSViewRepresentable {
  let material: NSVisualEffectView.Material
  let blendingMode: NSVisualEffectView.BlendingMode
  let state: NSVisualEffectView.State

  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = material
    view.blendingMode = blendingMode
    view.state = state
    return view
  }

  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    nsView.material = material
    nsView.blendingMode = blendingMode
    nsView.state = state
  }
}
