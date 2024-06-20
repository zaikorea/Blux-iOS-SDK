//
//  Request.swift
//  BluxClient
//
//  Created by Tommy on 5/21/24.
//

import Foundation

final class HTTPClient {
    static let shared: HTTPClient = HTTPClient()
    
    private static let COLLECTOR_BASE_URL = "https://collector-api.blux.ai"
    private static let CRM_COLLECTOR_BASE_URL = "https://crm-collector-api.blux.ai";
    
    enum HTTPMethodWithBody: String {
        case POST
        case PUT
        case PATCH
        case DELETE
    }
    
    enum HTTPError: Error {
        case transportError(Error)
        case serverSideError(Int)
    }
    
    func createRequest(path: String) -> URLRequest? {
        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            return nil
        }
        guard let url = URL(string: "\(HTTPClient.COLLECTOR_BASE_URL)\(path)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let requestTimestamp = "\(Utils.getCurrentUnixTimestamp())"
        
        request.setValue("\(SdkConfig.sdkType)-\(SdkConfig.sdkVersion)", forHTTPHeaderField: SdkConfig.bluxSdkInfoHeader)
        request.setValue(clientId, forHTTPHeaderField: SdkConfig.bluxClientIdHeader)
        request.setValue("\(SdkConfig.hmacScheme) \(Utils.generateBluxToken(secret: SdkConfig.secretKeyInUserDefaults, path: path, timestamp: requestTimestamp))", forHTTPHeaderField: SdkConfig.bluxAuthorizationHeader)
        request.setValue(requestTimestamp, forHTTPHeaderField: SdkConfig.bluxUnixTimestampHeader)
        
        return request
    }
    
    func createRequestWithBody<T: Codable>(method: HTTPMethodWithBody, path: String, body: T, toCRM: Bool = false) -> URLRequest? {
        guard let clientId = SdkConfig.clientIdInUserDefaults else {
            Logger.error("No Client ID.")
            return nil
        }
        guard let url = URL(string: "\(toCRM ? HTTPClient.CRM_COLLECTOR_BASE_URL : HTTPClient.COLLECTOR_BASE_URL)\(path)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = try? JSONEncoder().encode(body)
        request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let requestTimestamp = "\(Utils.getCurrentUnixTimestamp())"
        
        request.setValue("\(SdkConfig.sdkType)-\(SdkConfig.sdkVersion)", forHTTPHeaderField: SdkConfig.bluxSdkInfoHeader)
        request.setValue(clientId, forHTTPHeaderField: SdkConfig.bluxClientIdHeader)
        request.setValue("\(SdkConfig.hmacScheme) \(Utils.generateBluxToken(secret: SdkConfig.secretKeyInUserDefaults, path: path, timestamp: requestTimestamp))", forHTTPHeaderField: SdkConfig.bluxAuthorizationHeader)
        request.setValue(requestTimestamp, forHTTPHeaderField: SdkConfig.bluxUnixTimestampHeader)
        
        return request
    }
    
    func createAsyncTask<V: Codable>(request: URLRequest, completion: @escaping (V?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data,
                  let response = response as? HTTPURLResponse,
                  error == nil else {
                completion(nil, error)
                return
            }
            
            guard (200 ..< 300) ~= response.statusCode else {
                Logger.error(String(data: data, encoding: .utf8) ?? "\(request.httpMethod!) error")
                completion(nil, HTTPError.serverSideError(response.statusCode))
                return
            }
            
            // Check is data empty
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonDict = jsonObject as? [String: Any],
               jsonDict.isEmpty {
                completion(nil, nil)
                return
            }
            
            do {
                let responseObject = try JSONDecoder().decode(V.self, from: data)
                completion(responseObject, nil)
            } catch let error {
                completion(nil, error)
            }
        }
        
        return task
    }
    
    // MARK: - Methods
    
    func get<T: Codable>(path: String, completion: @escaping (T?, Error?) -> Void) {
        guard let request = self.createRequest(path: path) else {
            return
        }
        
        Logger.verbose("GET Request - path:\(path)")
        
        let task = self.createAsyncTask(request: request, completion: completion)
        
        task.resume()
    }
    
    func post<T: Codable, V: Codable>(path: String, body: T, toCRM: Bool = false, completion: @escaping (V?, Error?) -> Void) {
        guard let request = self.createRequestWithBody(method: HTTPMethodWithBody.POST, path: path, body: body, toCRM: toCRM) else {
            return
        }
        
        Logger.verbose("POST Request - path:\(path) body:\(body)")
        
        let task = createAsyncTask(request: request, completion: completion)
        
        task.resume()
    }
    
    func put<T: Codable, V: Codable>(path: String, body: T, completion: @escaping (V?, Error?) -> Void) {
        guard let request = self.createRequestWithBody(method: HTTPMethodWithBody.PUT, path: path, body: body) else {
            return
        }
        
        Logger.verbose("PUT Request - path:\(path) body:\(body)")
        
        let task = createAsyncTask(request: request, completion: completion)
        
        task.resume()
    }
    
    func patch<T: Codable, V: Codable>(path: String, body: T, completion: @escaping (V?, Error?) -> Void) {
        guard let request = self.createRequestWithBody(method: HTTPMethodWithBody.PATCH, path: path, body: body) else {
            return
        }
        
        Logger.verbose("PATCH Request - path:\(path) body:\(body)")
        
        let task = createAsyncTask(request: request, completion: completion)
        
        task.resume()
    }
}
