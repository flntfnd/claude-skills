# Navigation and Component Patterns

## Contents

- [iOS Navigation](#ios-navigation)
- [iPadOS Navigation](#ipados-navigation)
- [macOS Navigation](#macos-navigation)
- [Toolbar](#toolbar)
- [Floating Action](#floating-action)
- [Sheet](#sheet)
- [Sheet Morphing from Toolbar](#sheet-morphing-from-toolbar)

## iOS Navigation

Tab bar collapses on scroll down, expands on scroll up. This is automatic with `.tabBarMinimizeBehavior(.onScrollDown)`.

Search gets a dedicated tab role that places a floating button at bottom-right for reachability:

```swift
Tab("Search", systemImage: "magnifyingglass", role: .search) {
    SearchView()
}
```

Navigation is push-based. Sheets are modal and inset in iOS 26 with automatic glass backgrounds. Don't apply custom `presentationBackground` -- let the system handle it.

## iPadOS Navigation

Sidebar navigation. Floating glass sidebar with ambient reflection. Use `NavigationSplitView` and let the system apply the sidebar glass treatment.

```swift
NavigationSplitView {
    List(items) { item in
        NavigationLink(item.name, value: item)
    }
    .backgroundExtensionEffect()
} detail: {
    DetailView()
}
```

Stage Manager is a real use case on iPad. Don't assume full-screen layout.

## macOS Navigation

Concentric corner radius: window corners and contained elements must align. Use `.rect(cornerRadius: .containerConcentric)`.

Sidebar is persistent and ambient-reflective. Menu bar is transparent in macOS Tahoe 26. Design the toolbar for the new floating toolbar pattern, not the old attached toolbar.

## Toolbar

Toolbars get Liquid Glass automatically when compiled with Xcode 26. `.confirmationAction` placement gets `.glassProminent` automatically. Don't override it.

```swift
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Cancel", systemImage: "xmark") { }
    }
    ToolbarItem(placement: .confirmationAction) {
        Button("Done", systemImage: "checkmark") { }
    }
}
```

## Floating Action

```swift
GlassEffectContainer(spacing: 16) {
    VStack(spacing: 12) {
        if isExpanded {
            ForEach(actions, id: \.id) { action in
                Button { } label: {
                    Image(systemName: action.icon)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .tint(action.color)
                .glassEffectID(action.id, in: namespace)
            }
        }
        Button {
            withAnimation(.bouncy(duration: 0.35)) { isExpanded.toggle() }
        } label: {
            Image(systemName: isExpanded ? "xmark" : "plus")
                .font(.title2.bold())
                .frame(width: 56, height: 56)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(.blue)
        .glassEffectID("toggle", in: namespace)
    }
}
```

## Sheet

Sheets in iOS 26 get automatic inset glass backgrounds. Don't fight this.

```swift
.sheet(isPresented: $showSheet) {
    SheetContent()
        .presentationDetents([.medium, .large])
        .scrollContentBackground(.hidden)
}
```

## Sheet Morphing from Toolbar

```swift
Button("Info") { showInfo = true }
    .matchedTransitionSource(id: "info", in: transition)

.sheet(isPresented: $showInfo) {
    InfoSheet()
        .navigationTransition(.zoom(sourceID: "info", in: transition))
}
```
