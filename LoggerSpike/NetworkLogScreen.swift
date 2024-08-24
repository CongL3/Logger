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
                    let description = StatusCodeInfo.statusShortInfo[log.statusCode ?? 0] ?? ""
                    StatusCodeBadge(statusCode: log.statusCode ?? 0, description: description)
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct StatusCodeBadge: View {
    let statusCode: Int
    let description: String

    var body: some View {
        Text("\(statusCode) \(description)")
            .font(.subheadline)
            .padding(8)
            .background(borderColor.opacity(0.2))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 2)
            )
            .foregroundColor(.black)
    }

    private var borderColor: Color {
        switch statusCode {
        case 200..<300:
            return .green
        case 400..<500:
            return .orange
        case 500..<600:
            return .red
        default:
            return .gray
        }
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

                Text(log.method)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                
                Text("\(log.responseTime) seconds")
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)

                Text(formattedTimestamp(log.timestamp))
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)

                NavigationLink(destination: StatusCodeDetailView(
                    statusCode: log.statusCode ?? 0,
                    statusDescription: StatusCodeInfo.statusCodes[log.statusCode ?? 0] ?? "Unknown Status Code")
                ) {
                    
                    let description = StatusCodeInfo.statusShortInfo[log.statusCode ?? 0] ?? ""
                    StatusCodeBadge(statusCode: log.statusCode ?? 0, description: description)
                }
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
    
    private func formattedTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm, MMM dd, yyyy"
        return formatter.string(from: date)
    }

}

struct StatusCodeInfo {
    static let statusCodes: [Int: String] = [
        200: "OK: The request has succeeded.",
        201: "Created: The request has been fulfilled and resulted in a new resource being created.",
        400: "Bad Request: The server could not understand the request due to invalid syntax.",
        401: "Unauthorized: The client must authenticate itself to get the requested response.",
        404: "Not Found: The server can not find the requested resource.",
        500: "Internal Server Error: The server has encountered a situation it doesn't know how to handle.",
        502: "Bad Gateway: The server was acting as a gateway or proxy and received an invalid response from the upstream server."
    ]
    
    static let statusShortInfo: [Int: String] = [
        200: "OK",
        201: "Created",
        400: "Bad Request",
        401: "Unauthorized",
        404: "Not Found",
        500: "Internal Server Error",
        502: "Bad Gateway"
    ]
}

struct StatusCodeDetailView: View {
    let statusCode: Int
    let statusDescription: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status Code: \(statusCode)")
                .font(.title)
                .bold()

            Text(statusDescription)
                .font(.body)

            Spacer()
        }
        .padding()
        .navigationTitle("Status Code Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
