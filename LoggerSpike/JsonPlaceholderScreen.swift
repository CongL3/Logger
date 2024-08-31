//
//  JsonPlaceholderScreen.swift
//  LoggerSpike
//
//  Created by Cong Le on 29/08/2024.
//

import Foundation
import SwiftUI

struct JsonPlaceholderScreen: View {
    @State private var responseData: Data?
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var httpMethod: HttpMethod = .post
    @State private var requestBodyType: RequestBodyType = .defaultBody
    @State private var contentType: ContentType = .json
    @State private var authorizationType: AuthorizationType = .bearer

    private let jsonPlaceholderService = JsonPlaceholderService()

    var body: some View {
        VStack(spacing: 20) {
            Picker("HTTP Method", selection: $httpMethod) {
                ForEach(HttpMethod.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Picker("Body Type", selection: $requestBodyType) {
                ForEach(RequestBodyType.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(httpMethod == .get)

            Picker("Content-Type", selection: $contentType) {
                ForEach(ContentType.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Picker("Authorization", selection: $authorizationType) {
                ForEach(AuthorizationType.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Button(action: {
                sendRequest()
            }) {
                Text("Send \(httpMethod.rawValue) Request")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isLoading)

            if isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let data = responseData {
                Text("Response Data: \(String(data: data, encoding: .utf8) ?? "No Data")")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }

    private func sendRequest() {
        isLoading = true
        jsonPlaceholderService.sendRequest(httpMethod: httpMethod, requestBodyType: requestBodyType, contentType: contentType, authorizationType: authorizationType) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.responseData = data
                    self.errorMessage = nil
                case .failure(let error):
                    self.responseData = nil
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
}
