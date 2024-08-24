//
//  NetworkLogView.swift
//  LoggerSpike
//
//  Created by Cong Le on 24/08/2024.
//

import SwiftUI

struct NetworkLogScreen: View {
    @State private var selectedLog: Logger.NetworkLog?

    var body: some View {
        List(Logger.shared.getAllLogs()) { log in
            NavigationLink(destination: NetworkLogDetailView(log: log)) {
                VStack(alignment: .leading) {
                    Text(log.url)
                        .font(.headline)
                    Text("Status: \(log.statusCode ?? 0)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct NetworkLogDetailView: View {
    let log: Logger.NetworkLog
    @State private var showFullRequestBody = false
    @State private var showFullResponseBody = false

    var body: some View {
        List {
            Section(header: Text("URL")) {
                Text(log.url)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
            }

            Section(header: Text("Status Code")) {
                Text("\(log.statusCode ?? 0)")
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
            }

            Section(header: Text("Request Headers")) {
                Text(formatDictionary(log.requestHeaders))
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
            }

            Section(header: Text("Request Body")) {
                if let requestBody = log.requestBody, !requestBody.isEmpty {
                    if showFullRequestBody {
                        ScrollView {
                            Text(requestBody)
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                        }
                    } else {
                        Text(requestBody.prefix(1000) + (requestBody.count > 1000 ? "..." : ""))
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled)
                        if requestBody.count > 1000 {
                            Button("Show More") {
                                showFullRequestBody.toggle()
                            }
                        }
                    }
                } else {
                    Text("No Body")
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                }
            }

            Section(header: Text("Response Headers")) {
                Text(formatDictionary(log.responseHeaders))
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
            }

            Section(header: Text("Response Body")) {
                if let responseBody = log.responseBody, !responseBody.isEmpty {
                    if showFullResponseBody {
                        ScrollView {
                            Text(responseBody)
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                        }
                    } else {
                        Text(responseBody.prefix(1000) + (responseBody.count > 1000 ? "..." : ""))
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled)
                        if responseBody.count > 1000 {
                            Button("Show More") {
                                showFullResponseBody.toggle()
                            }
                        }
                    }
                } else {
                    Text("No Body")
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Log Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDictionary(_ dictionary: [String: String]?) -> String {
        guard let dictionary = dictionary else { return "No Data" }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted])
            return String(data: jsonData, encoding: .utf8) ?? "Formatting Error"
        } catch {
            return "Formatting Error"
        }
    }
}
