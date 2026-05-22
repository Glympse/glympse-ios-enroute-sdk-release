import Foundation
import SwiftUI

struct LogsView: View {
    @ObservedObject private var logCollector = logger
    @State private var autoScrollEnabled: Bool = true
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(logCollector.collectedEvents) { event in
                            LogEventRow(event: event)
                                .id(event.id)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: logCollector.collectedEvents.count) { oldValue, newValue in
                    if autoScrollEnabled, let lastEvent = logCollector.collectedEvents.last {
                        withAnimation(.spring()) {
                            scrollViewProxy.scrollTo(lastEvent.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if autoScrollEnabled, let lastEvent = logCollector.collectedEvents.last {
                       scrollViewProxy.scrollTo(lastEvent.id, anchor: .bottom)
                    }
                }
            }

            Toggle("Auto-scroll to bottom", isOn: $autoScrollEnabled)
                .padding()
                .background(Color(.systemGray6))
        }
    }
}

struct LogEventRow: View {
    let event: LogEvent

    var body: some View {
        VStack(alignment: .leading) {
            Text(event.formattedTimestamp)
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(Color.blue)
            Text(event.message)
                .font(.callout)
            Divider()
        }
    }
}

