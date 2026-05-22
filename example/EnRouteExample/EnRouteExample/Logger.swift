import Foundation
import os
import Combine

let logger = Logger(initialVerbosity: .debug)

struct LogEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let severity: LogSeverity
    let message: String

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    var consoleFormatted: String {
        "\(formattedTimestamp) [\(severity.rawValue.uppercased())]: \(message)"
    }
}

enum LogSeverity: String, CaseIterable, Comparable {
    case verbose = "Verbose"
    case debug   = "Debug"
    case info    = "Info"
    case warning = "Warning"
    case error   = "Error"

    private var order: Int {
        switch self {
        case .verbose: return 0
        case .debug:   return 1
        case .info:    return 2
        case .warning: return 3
        case .error:   return 4
        }
    }

    static func < (lhs: LogSeverity, rhs: LogSeverity) -> Bool {
        return lhs.order < rhs.order
    }

    static func == (lhs: LogSeverity, rhs: LogSeverity) -> Bool {
        return lhs.order == rhs.order
    }
}

class Logger: ObservableObject {

    @Published var consoleVerbosity: LogSeverity = .info {
        didSet {
            debug("Logger: Console verbosity set to \(consoleVerbosity.rawValue)")
        }
    }

    @Published private(set) var collectedEvents: [LogEvent] = []
    private let maxCollectedEvents: Int = 1000

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.glympse.enrouteexample"
    private let osLogger: os.Logger

    init(initialVerbosity: LogSeverity = .info) {
        self.consoleVerbosity = initialVerbosity
        self.osLogger = os.Logger(subsystem: Logger.subsystem, category: "AppActivity")
        log(.info, "AppLogger initialized. Console verbosity: \(initialVerbosity.rawValue).")
    }

    /// Logs an event with the specified severity and message.
    /// The event is stored and may be printed to the console based on current verbosity.
    ///
    /// - Parameters:
    ///   - severity: The severity level of the log event (e.g., .error, .info).
    ///   - message: The descriptive message for the log event.
    ///   - file: The file where the log originated (automatically captured).
    ///   - function: The function where the log originated (automatically captured).
    ///   - line: The line number where the log originated (automatically captured).
    func log(_ severity: LogSeverity,
             _ message: String,
             file: String = #file,
             function: String = #function,
             line: Int = #line) {

        let event = LogEvent(timestamp: Date(), severity: severity, message: message)
        
        addCollectedEvent(event)

        if severity >= consoleVerbosity {
            var contextualMessage: String = ""
            if ( consoleVerbosity == .verbose ) {
                contextualMessage = "[\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)] \(message)"
            } else {
                contextualMessage = "[\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(message)"
            }
            switch severity {
                
            case .verbose:
                osLogger.trace("\(contextualMessage, privacy: .public)")
            case .debug:
                osLogger.debug("\(contextualMessage, privacy: .public)")
            case .info:
                osLogger.info("\(contextualMessage, privacy: .public)")
            case .warning:
                osLogger.warning("\(contextualMessage, privacy: .public)")
            case .error:
                osLogger.error("\(contextualMessage, privacy: .public)")
            }
        }
    }

    // Convenience methods for each severity level
    func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.verbose, message, file: file, function: function, line: line)
    }
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, file: file, function: function, line: line)
    }
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, file: file, function: function, line: line)
    }

    private func addCollectedEvent(_ event: LogEvent) {
        DispatchQueue.main.async {
            self.collectedEvents.append(event)
            // Trim old events if the collection exceeds the maximum limit
            if self.collectedEvents.count > self.maxCollectedEvents {
                self.collectedEvents.removeFirst(self.collectedEvents.count - self.maxCollectedEvents)
            }
        }
    }

    func clearCollectedEvents() {
        DispatchQueue.main.async {
            self.collectedEvents.removeAll()
            self.log(.info, "Collected log events cleared.")
        }
    }

    func setConsoleVerbosity(to newVerbosity: LogSeverity) {
        self.consoleVerbosity = newVerbosity
    }

    func getConsoleVerbosity() -> LogSeverity {
        return self.consoleVerbosity
    }
}

