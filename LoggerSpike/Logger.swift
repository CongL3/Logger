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
        Logger.shared.logRequest(request)
        
        let newRequest = (self.request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        let task = URLSession.shared.dataTask(with: newRequest as URLRequest) { [weak self] data, response, error in
            Logger.shared.logResponse(response, data: data, error: error)
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

class Logger {
    static let shared = Logger()

    func logRequest(_ request: URLRequest) {
        print("\n----- [REQUEST START] -----")
        print("➡️ [REQUEST] \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
        
        if let headers = request.allHTTPHeaderFields {
            print("Headers: \(headers)")
        }
        
        if let body = request.httpBody {
            if let bodyString = String(data: body, encoding: .utf8) {
                print("JSON BODY: \(bodyString)")
            } else {
                print("Failed to decode body as UTF-8")
            }
        } else if let bodyStream = request.httpBodyStream {
            print("Request body is a stream. Unable to log directly.")
        } else {
            print("No body found in the request.")
        }
        
        print("----- [REQUEST END] -----\n")
    }

    func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        print("\n----- [RESPONSE START] -----")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("⬅️ [RESPONSE] \(httpResponse.statusCode) \(response?.url?.absoluteString ?? "")")
            
            if let headers = httpResponse.allHeaderFields as? [String: Any] {
                print("Headers: \(headers)")
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Data: \(dataString)")
            }
        }
        
        if let error = error {
            print("Error: \(error.localizedDescription)")
        }
        
        print("----- [RESPONSE END] -----\n")
    }
}
