import SwiftUI

enum FileCategory: String, CaseIterable {
    case application = "Application"
    case preferences = "Preferences"
    case applicationSupport = "Application Support"
    case caches = "Caches"
    case logs = "Logs"
    case containers = "Containers"
    case savedState = "Saved State"
    case webkit = "WebKit"
    case cookies = "Cookies"
    case launchAgents = "Launch Agents"
    case launchDaemons = "Launch Daemons"
    case other = "Other"

    var icon: String {
        switch self {
        case .application: return "app.fill"
        case .preferences: return "gearshape.fill"
        case .applicationSupport: return "folder.fill"
        case .caches: return "internaldrive.fill"
        case .logs: return "doc.text.fill"
        case .containers: return "shippingbox.fill"
        case .savedState: return "clock.fill"
        case .webkit: return "globe"
        case .cookies: return "chart.pie.fill"
        case .launchAgents: return "play.circle.fill"
        case .launchDaemons: return "gearshape.2.fill"
        case .other: return "questionmark.folder.fill"
        }
    }

    var color: Color {
        switch self {
        case .application: return .blue
        case .preferences: return .orange
        case .applicationSupport: return .purple
        case .caches: return .gray
        case .logs: return .brown
        case .containers: return .indigo
        case .savedState: return .cyan
        case .webkit: return .green
        case .cookies: return .pink
        case .launchAgents: return .yellow
        case .launchDaemons: return .red
        case .other: return .secondary
        }
    }
}
