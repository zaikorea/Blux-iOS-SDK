//
//  Request.swift
//  BluxClient
//
//  Created by Tommy on 5/21/24.
//

import Foundation

final class HTTPClient {
    static let shared: HTTPClient = .init()

    private enum HTTPMethodWithBody: String {
        case POST
        case PUT
        case PATCH
        case DELETE
    }

    private enum HTTPError: Error {
        case transportError(Error)
        case serverSideError(Int)
    }

    public enum APIBaseURLByStage: String {
        case local = "http://localhost:9000/local"
        case dev = "https://api.blux.ai/dev"
        case stg = "https://api.blux.ai/stg"
        case prod = "https://api.blux.ai/prod"
    }

    private var API_BASE_URL: String = APIBaseURLByStage.prod.rawValue

    // MARK: - Private Methods

    private func createRequest(path: String) -> URLRequest? {
        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            return nil
        }
        guard let url = URL(string: "\(API_BASE_URL)\(path)")
        else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        request.setValue(
            "\(SdkConfig.sdkType)-\(SdkConfig.sdkVersion)",
            forHTTPHeaderField: SdkConfig.bluxSdkInfoHeader)
        request.setValue(
            clientId, forHTTPHeaderField: SdkConfig.bluxClientIdHeader)
        request.setValue(
            SdkConfig.apiKeyInUserDefaults,
            forHTTPHeaderField: SdkConfig.bluxApiKeyHeader)
        request.setValue(
            SdkConfig.apiKeyInUserDefaults,
            forHTTPHeaderField: SdkConfig.bluxAuthorizationHeader)

        return request
    }

    private func createRequestWithBody<T: Codable>(
        method: HTTPMethodWithBody, path: String, body: T
    ) -> URLRequest? {
        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            Logger.error("No Client ID.")
            return nil
        }

        guard let url = URL(string: "\(API_BASE_URL)\(path)")
        else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = try? JSONEncoder().encode(body)
        request.addValue(
            "application/json; charset=UTF-8",
            forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        request.setValue(
            "\(SdkConfig.sdkType)-\(SdkConfig.sdkVersion)",
            forHTTPHeaderField: SdkConfig.bluxSdkInfoHeader)
        request.setValue(clientId, forHTTPHeaderField: "X-BLUX-CLIENT-ID")
        request.setValue(
            UserDefaults(suiteName: SdkConfig.bluxSuiteName)?.string(
                forKey: "bluxAPIKey"), forHTTPHeaderField: "X-BLUX-API-KEY")
        request.setValue(
            UserDefaults(suiteName: SdkConfig.bluxSuiteName)?.string(
                forKey: "bluxAPIKey"), forHTTPHeaderField: "Authorization")

        return request
    }

    private func createAsyncTask<V: Codable>(
        request: URLRequest, completion: @escaping (V?, Error?) -> Void
    ) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            guard let data = data,
                  let response = response as? HTTPURLResponse,
                  error == nil
            else {
                completion(nil, error)
                return
            }

            guard (200 ..< 300) ~= response.statusCode else {
                Logger.error(
                    String(data: data, encoding: .utf8)
                        ?? "\(request.httpMethod!) error")
                completion(nil, HTTPError.serverSideError(response.statusCode))
                return
            }

            // Check is data empty
            if let jsonObject = try? JSONSerialization.jsonObject(
                with: data, options: []),
                let jsonDict = jsonObject as? [String: Any],
                jsonDict.isEmpty
            {
                completion(nil, nil)
                return
            }

            do {
                let responseObject = try JSONDecoder().decode(
                    V.self, from: data)
                completion(responseObject, nil)
            } catch {
                completion(nil, error)
            }
        }

        return task
    }

    // MARK: - Public Methods

    func get<T: Codable>(
        path: String, completion: @escaping (T?, Error?) -> Void
    ) {
        guard let request = createRequest(path: path)
        else { return }

        Logger.verbose("GET Request - path:\(path)")
        let task = createAsyncTask(request: request, completion: completion)
        task.resume()
    }

    func post<T: Codable, V: Codable>(
        path: String, body: T, completion: @escaping (V?, Error?) -> Void
    ) {
        guard let request = createRequestWithBody(method: HTTPMethodWithBody.POST, path: path, body: body)
        else { return }

        Logger.verbose("POST Request - path:\(path) body:\(body)")
        let task = createAsyncTask(request: request, completion: completion)
        task.resume()
    }

    func put<T: Codable, V: Codable>(
        path: String, body: T, completion: @escaping (V?, Error?) -> Void
    ) {
        guard let request = createRequestWithBody(method: HTTPMethodWithBody.PUT, path: path, body: body)
        else { return }

        Logger.verbose("PUT Request - path:\(path) body:\(body)")
        let task = createAsyncTask(request: request, completion: completion)
        task.resume()
    }

    func patch<T: Codable, V: Codable>(
        path: String, body: T, completion: @escaping (V?, Error?) -> Void
    ) {
        guard let request = createRequestWithBody(method: HTTPMethodWithBody.PATCH, path: path, body: body)
        else { return }

        Logger.verbose("PATCH Request - path:\(path) body:\(body)")
        let task = createAsyncTask(request: request, completion: completion)
        task.resume()
    }

    func setAPIStage(_ apiBaseUrl: APIBaseURLByStage) {
        API_BASE_URL = apiBaseUrl.rawValue
    }
}
