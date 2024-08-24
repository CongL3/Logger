import Foundation
import SwiftUI


class CrashReporter {
    static let shared = CrashReporter()

    private let crashLogFile: URL

    private init() {
        // Set the file path in the Documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        crashLogFile = documentsDirectory.appendingPathComponent("crash_logs.txt")

        setupExceptionHandlers()
        setupSignalHandlers()
        checkForPreviousCrashes()
    }

    private func setupExceptionHandlers() {
        // Set the uncaught exception handler to a static function
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.handleUncaughtException(exception)
        }
    }

    private func setupSignalHandlers() {
        signal(SIGABRT) { signal in
            CrashReporter.handleSignal(signal)
        }
        signal(SIGILL) { signal in
            CrashReporter.handleSignal(signal)
        }
        signal(SIGSEGV) { signal in
            CrashReporter.handleSignal(signal)
        }
        signal(SIGFPE) { signal in
            CrashReporter.handleSignal(signal)
        }
        signal(SIGBUS) { signal in
            CrashReporter.handleSignal(signal)
        }
        signal(SIGPIPE) { signal in
            CrashReporter.handleSignal(signal)
        }
    }

    private func checkForPreviousCrashes() {
        if let previousCrashReport = getCrashReports(), !previousCrashReport.isEmpty {
            print("Previous crash report found:\n\(previousCrashReport)")
        }
    }

    private func handleException(_ exception: NSException) {
        let crashReport = """
        Crash Report:

        Exception Name: \(exception.name)
        Exception Reason: \(exception.reason ?? "No reason")
        User Info: \(exception.userInfo ?? [:])
        Stack Trace:
        \(exception.callStackSymbols.joined(separator: "\n"))
        """
        saveCrashReport(crashReport)
    }

    private func saveCrashReport(_ report: String) {
        do {
            if FileManager.default.fileExists(atPath: crashLogFile.path) {
                // Append to the existing file
                let fileHandle = try FileHandle(forWritingTo: crashLogFile)
                fileHandle.seekToEndOfFile()
                fileHandle.write(report.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                // Create a new file and write the report
                try report.write(to: crashLogFile, atomically: true, encoding: .utf8)
            }
            print("Crash report saved successfully.")
        } catch {
            print("Failed to save crash report: \(error.localizedDescription)")
        }
    }

    func forceCrash() {
        fatalError("Forced crash for testing")
    }

    func getCrashReports() -> String? {
        do {
            if FileManager.default.fileExists(atPath: crashLogFile.path) {
                return try String(contentsOf: crashLogFile, encoding: .utf8)
            } else {
                print("No crash reports found.")
                return nil
            }
        } catch {
            print("Failed to read crash reports: \(error.localizedDescription)")
            return nil
        }
    }

    func clearCrashReports() {
        do {
            try FileManager.default.removeItem(at: crashLogFile)
            print("Crash reports cleared successfully.")
        } catch {
            print("Failed to clear crash reports: \(error.localizedDescription)")
        }
    }

    // Static function to handle uncaught exceptions
    private static func handleUncaughtException(_ exception: NSException) {
        CrashReporter.shared.handleException(exception)
        UserDefaults.standard.synchronize()
    }

    // Static function to handle signals
    private static func handleSignal(_ signal: Int32) {
        let report = "Crash Report:\nReceived Signal \(signal)\n"
        CrashReporter.shared.saveCrashReport(report)
        exit(signal)
    }
}

struct CrashReportingView: View {
    @State private var crashReports: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Force a Crash")) {
                    Button("Force Crash") {
                        CrashReporter.shared.forceCrash()
                    }
                }

                Section(header: Text("Recent Crashes")) {
                    ScrollView {
                        Text(crashReports)
                            .font(.body)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .onAppear {
                loadCrashReports()
            }
            .navigationTitle("Crash Reporting")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func loadCrashReports() {
        if let reports = CrashReporter.shared.getCrashReports() {
            crashReports = reports
        } else {
            crashReports = "No crash reports available."
        }
    }
}
