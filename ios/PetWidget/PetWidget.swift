// Companion Presence home widget — iOS WidgetKit scaffold (P2-6).
//
// NOTE: this source is a ready-to-wire SCAFFOLD. It is intentionally NOT yet
// added to the Xcode project as a Widget Extension target (that requires Xcode
// on macOS + an Apple Developer team + an App Group, which can't be done on a
// Linux host). Founder steps to activate: docs/HOME_WIDGET_FOUNDATION.md §iOS.
//
// It reads the single shared PetStatusSnapshot the Flutter app writes to the
// App Group UserDefaults (key `kindredpaws.widget.snapshot`, written by
// PrefsHomeWidgetService once the App Group is configured) and renders the pet
// name + a warm, never-guilt status line. It shows a pre-rendered mood image,
// never a live rig render (§6.2).

import SwiftUI
import WidgetKit

// MARK: - Shared payload (mirrors PetStatusSnapshot.toMap)

struct PetStatus {
    let name: String
    let mood: String
    let moodImageRef: String

    static let placeholder = PetStatus(
        name: "Your pet", mood: "content", moodImageRef: "puppy_pupKit_content")

    static func load(appGroup: String) -> PetStatus {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let json = defaults.string(forKey: "kindredpaws.widget.snapshot"),
            let data = json.data(using: .utf8),
            let map = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return .placeholder }
        return PetStatus(
            name: map["name"] as? String ?? "Your pet",
            mood: map["mood"] as? String ?? "content",
            moodImageRef: map["preRenderedMoodImageRef"] as? String ?? "")
    }

    var statusLine: String {
        switch mood {
        case "joyful": return "\(name) is over the moon! ✨"
        case "content": return "\(name) is happy and cozy 🐾"
        case "wistful": return "\(name) is thinking of you 💛"
        default: return "\(name) would love a little care 🤍"
        }
    }
}

// MARK: - Timeline

struct PetEntry: TimelineEntry {
    let date: Date
    let status: PetStatus
}

struct PetProvider: TimelineProvider {
    // Replace with your real App Group id (see docs).
    let appGroup = "group.com.kindredpaws.kindredpaws"

    func placeholder(in context: Context) -> PetEntry {
        PetEntry(date: Date(), status: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> Void) {
        completion(PetEntry(date: Date(), status: PetStatus.load(appGroup: appGroup)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> Void) {
        let entry = PetEntry(date: Date(), status: PetStatus.load(appGroup: appGroup))
        // Ambient surface: refresh ~every 30 min (the OS budgets this).
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - View

struct PetWidgetView: View {
    let entry: PetEntry

    var body: some View {
        VStack(spacing: 4) {
            // A pre-rendered mood image drops in here (Assets), not a live render.
            Text(entry.status.name).font(.headline)
            Text(entry.status.statusLine).font(.caption).multilineTextAlignment(.center)
        }
        .padding()
    }
}

@main
struct PetWidget: Widget {
    let kind = "PetWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetProvider()) { entry in
            PetWidgetView(entry: entry)
        }
        .configurationDisplayName("KindredPaws")
        .description("Your companion, right on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
