//
//  JsonPlaceHolderService.swift
//  LoggerSpike
//
//  Created by Cong Le on 29/08/2024.
//

import Foundation

enum HttpMethod: String, CaseIterable {
    case get = "GET"
    case post = "POST"
}

enum RequestBodyType: String, CaseIterable {
    case defaultBody = "Default Body"
    case customBody = "Custom Body"
}

enum ContentType: String, CaseIterable {
    case json = "application/json"
    case xml = "application/xml"
}

enum AuthorizationType: String, CaseIterable {
    case bearer = "Bearer Token"
    case basic = "Basic Auth"
}

class JsonPlaceholderService {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [NetworkLoggingProtocol.self] + (configuration.protocolClasses ?? [])
        self.session = URLSession(configuration: configuration)
    }

    func sendRequest(httpMethod: HttpMethod, requestBodyType: RequestBodyType, contentType: ContentType, authorizationType: AuthorizationType, completion: @escaping (Result<Data, Error>) -> Void) {
        let urlString = "https://jsonplaceholder.typicode.com/posts"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.addValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        
        switch authorizationType {
        case .bearer:
            request.addValue("Bearer abcdef123456", forHTTPHeaderField: "Authorization")
        case .basic:
            let credentials = "username:password".data(using: .utf8)?.base64EncodedString() ?? ""
            request.addValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }

        if httpMethod == .post {
            let body: [String: Any] = requestBodyType == .defaultBody ? [
                "title": "foo",
                "body": "bar",
                "userId": 1
            ] : [
                "title": "Custom Title",
                "body": "Custom Body",
                "userId": 2
            ]
            
            let jsonData = try? JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: 404, userInfo: nil)))
                return
            }

            completion(.success(data))
        }
        task.resume()
    }
}

