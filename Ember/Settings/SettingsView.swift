import Observation
import SwiftUI

/// The page the Settings window shows, kept outside the view so the window can open on a
/// given page.
@Observable
final class SettingsNavigation {
    var page = SettingsPage.general
}

/// The Settings window's content, styled after Atoll's settings: a sidebar with search and
/// the pages in groups, and the selected page as a grouped form.
struct SettingsView: View {
    @Bindable var navigation: SettingsNavigation
    let settings: AppSettings
    let calendar: CalendarModel
    let levels: LevelModel
    let keepAwake: KeepAwakeModel
    let updater: Updater
    let hotKey: GlobalHotKey
    /// The notch's width, for drawings of the panel.
    let notchWidth: CGFloat
    /// Plays a brief activity in the notch, as an example.
    let showExample: (LiveActivity) -> Void
    /// Plays onboarding again.
    let showWelcome: () -> Void
    @State private var searchText = ""

    var body: some View {
        let pages = SettingsSearch.pages(for: searchText)
        NavigationSplitView {
            List(selection: Binding<SettingsPage?>(get: { navigation.page },
                                                   set: { if let page = $0 { navigation.page = page } })) {
                ForEach(SettingsGroup.allCases, id: \.self) { group in
                    let groupPages = pages.filter { $0.group == group }
                    if !groupPages.isEmpty {
                        Section {
                            ForEach(groupPages, id: \.self) { page in
                                SidebarRow(page: page).tag(page)
                            }
                        } header: {
                            if let title = group.title { Text(title) }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .environment(\.defaultMinListRowHeight, 36)
            .overlay {
                if pages.isEmpty { ContentUnavailableView.search(text: searchText) }
            }
            .navigationSplitViewColumnWidth(210)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            detail(for: navigation.page)
                .formStyle(.grouped)
                .toggleStyle(.switch)
                .environment(\.settingsMatches, SettingsSearch.matches(searchText))
                .navigationTitle(navigation.page.title)
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search")
        .frame(width: 700, height: 500)
        .background { SettingsBackground() }
        .onChange(of: searchText) {
            let pages = SettingsSearch.pages(for: searchText)
            if !pages.contains(navigation.page), let first = pages.first {
                navigation.page = first
            }
        }
    }

    @ViewBuilder
    private func detail(for page: SettingsPage) -> some View {
        switch page {
        case .general: GeneralPage(settings: settings, hotKey: hotKey, notchWidth: notchWidth)
        case .glow: GlowPage(settings: settings)
        case .music: MusicPage(settings: settings, showExample: showExample)
        case .timer: TimerPage(settings: settings, showExample: showExample)
        case .calendar: CalendarPage(settings: settings, calendar: calendar, showExample: showExample)
        case .shelf: ShelfPage(settings: settings)
        case .battery: BatteryPage(settings: settings, showExample: showExample)
        case .levels: LevelsPage(levels: levels)
        case .keepAwake: KeepAwakePage(settings: settings, keepAwake: keepAwake)
        case .permissions: PermissionsPage()
        case .feedback: FeedbackPage()
        case .about: AboutPage(updater: updater, showWelcome: showWelcome)
        }
    }
}

/// A sidebar row: the page's icon square and its name.
private struct SidebarRow: View {
    let page: SettingsPage

    var body: some View {
        HStack(spacing: 10) {
            SettingsIcon(page: page)
            Text(page.title)
        }
        .padding(.vertical, 4)
    }
}

/// A white symbol on a rounded square filled with a gradient of the page's colour, with a
/// thin light edge and a soft shadow.
private struct SettingsIcon: View {
    let page: SettingsPage

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(LinearGradient(colors: [page.color, page.color.opacity(0.7)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 26, height: 26)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.7)
                    .blendMode(.plusLighter)
            }
            .shadow(color: page.color.opacity(0.35), radius: 2, y: 1)
            .overlay {
                Image(systemName: page.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }
}

/// Glass on macOS 26 and later; a thin material before.
private struct SettingsBackground: View {
    var body: some View {
        Group {
            if #available(macOS 26.0, *) {
                Color.clear   // only the glass shows, not a filled shape
                    .glassEffect(.clear.tint(.white.opacity(0.1)), in: .rect(cornerRadius: 18))
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .ignoresSafeArea()
    }
}
