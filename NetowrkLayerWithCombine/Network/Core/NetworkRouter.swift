import Alamofire
import Foundation

// MARK: - NetworkError

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
    case encodingFailed
    case unknown
}

// MARK: - RequestMethod

enum RequestMethod: String {
    case get
    case post
    case put
    case patch
    case trace
    case delete
}

// MARK: - NetworkRouter

protocol NetworkRouter: URLRequestConvertible {
    var baseURLString: String { get }
    var method: RequestMethod { get }
    var path: String { get }
    var headers: [String: String]? { get }
    var params: [String: Any]? { get }
    var queryParams: [String: Any]? { get }
    var encoding: ParameterEncoding { get }
    var isURLEncoded: Bool { get }
    var isQueryString: Bool { get }
}

// MARK: - NetworkRouter Default Implementation

extension NetworkRouter {
    
    var isURLEncoded: Bool {
        return false
    }
    
    var isQueryString: Bool {
        return false
    }
    
    var headers: [String: String]? {
        return nil
    }
    
    var params: [String: Any]? {
        return nil
    }
    
    var queryParams: [String: Any]? {
        return nil
    }
    
    var encoding: ParameterEncoding {
        return JSONEncoding.default
    }

    func asURLRequest() throws -> URLRequest {
        guard let url = URL(string: baseURLString)?.appendingPathComponent(path) else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue.uppercased()
        
        if let headers = headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        switch method {
        case .get:
            if isQueryString {
                urlRequest = try URLEncoding(destination: .queryString).encode(urlRequest, with: queryParams)
            } else {
                urlRequest = try URLEncoding.default.encode(urlRequest, with: params)
            }
            
        case .post, .put, .patch:
            if isURLEncoded {
                urlRequest = try URLEncoding.default.encode(urlRequest, with: params)
            } else {
                urlRequest = try encoding.encode(urlRequest, with: params)
            }
            
        case .delete:
            if isQueryString {
                urlRequest = try URLEncoding(destination: .queryString).encode(urlRequest, with: queryParams)
            } else {
                urlRequest = try URLEncoding.default.encode(urlRequest, with: params)
            }
            
        default:
            break
        }
        
        return urlRequest
    }
}
