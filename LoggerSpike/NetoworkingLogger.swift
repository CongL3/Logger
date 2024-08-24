//
//  Logger.swift
//  LoggerSpike
//
//  Created by Cong Le on 21/08/2024.
//

import Foundation

class NetworkLoggingProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        NetoworkingLogger.shared.logRequest(request)
        
        let newRequest = (self.request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        let task = URLSession.shared.dataTask(with: newRequest as URLRequest) { [weak self] data, response, error in
            NetoworkingLogger.shared.logResponse(response, data: data, error: error, request: self?.request)
            self?.client?.urlProtocol(self!, didReceive: response!, cacheStoragePolicy: .notAllowed)
            if let data = data {
                self?.client?.urlProtocol(self!, didLoad: data)
            }
            if let error = error {
                self?.client?.urlProtocol(self!, didFailWithError: error)
            }
            self?.client?.urlProtocolDidFinishLoading(self!)
        }
        task.resume()
    }

    override func stopLoading() {}
}

class NetoworkingLogger {
    static let shared = NetoworkingLogger()

    struct NetworkLog: Identifiable {
        let id = UUID()
        let url: String
        let statusCode: Int?
        let responseTime: Double
        let error: String?
        let timestamp: Date
        let method: String
        let requestHeaders: [String: String]?
        let responseHeaders: [String: String]?
        let requestBody: String?
        let responseBody: String?
    }

    private var logs: [NetworkLog] = []
    private let maxLogs: Int = 100
    private var requestStartTime: Date?

    func logRequest(_ request: URLRequest) {
        print("\n----- [REQUEST START] -----")
        print("➡️ [REQUEST] \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
        
        requestStartTime = Date()

        let headers = request.allHTTPHeaderFields
        var bodyString: String? = nil
        
        if let body = request.httpBody {
            bodyString = String(data: body, encoding: .utf8)
            print("JSON BODY: \(bodyString ?? "Failed to decode body as UTF-8")")
        } else if request.httpBodyStream != nil {
            print("Request body is a stream. Unable to log directly.")
        } else {
            print("No body found in the request.")
        }

        print("----- [REQUEST END] -----\n")
    }

    func logResponse(_ response: URLResponse?, data: Data?, error: Error?, request: URLRequest?) {
        print("\n----- [RESPONSE START] -----")
        
        guard let httpResponse = response as? HTTPURLResponse else { return }

        let url = response?.url?.absoluteString ?? "Unknown URL"
        let statusCode = httpResponse.statusCode
        let responseTime = Date().timeIntervalSince(requestStartTime ?? Date())
        
        print("⬅️ [RESPONSE] \(statusCode) \(url)")
        
        let responseHeaders = httpResponse.allHeaderFields as? [String: String]
        var responseBody: String? = nil
        if let data = data, let dataString = String(data: data, encoding: .utf8) {
            print("Data: \(dataString)")
            responseBody = dataString
        }

        if let error = error {
            print("Error: \(error.localizedDescription)")
        }
        
        print("----- [RESPONSE END] -----\n")

        let method = request?.httpMethod ?? "Unknown Method"
        let requestHeaders = request?.allHTTPHeaderFields
        var requestBody: String? = nil
        if let body = request?.httpBody {
            requestBody = String(data: body, encoding: .utf8)
        }

        let log = NetworkLog(
            url: url,
            statusCode: statusCode,
            responseTime: responseTime,
            error: error?.localizedDescription,
            timestamp: Date(),
            method: method,
            requestHeaders: requestHeaders,
            responseHeaders: responseHeaders,
            requestBody: requestBody,
            responseBody: responseBody
        )

        addLog(log)
    }

    private func addLog(_ log: NetworkLog) {
        if logs.count >= maxLogs {
            logs.removeFirst()
        }
        logs.append(log)
    }

    func getAllLogs() -> [NetworkLog] {
        return logs
    }
}
