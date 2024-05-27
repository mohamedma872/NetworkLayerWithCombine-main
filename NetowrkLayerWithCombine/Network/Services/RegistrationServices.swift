import Alamofire
import Combine
import Foundation

// MARK: - RegistrationServicesProtocols

protocol RegistrationServicesProtocols {
    func registerUser(username: String, password: String) -> AnyPublisher<RegisterDomainModel, AFError>
}

// MARK: - RegistrationServices

class RegistrationServices {
    // MARK: Lifecycle

    init(apiRequest: APIRequest) {
        self.apiRequest = apiRequest
    }

    deinit {
        debugPrint("RegistrationServices deinited")
    }

    // MARK: Private

    private var apiRequest: APIRequest
}

// MARK: - RegistrationServicesProtocols

extension RegistrationServices: RegistrationServicesProtocols {
    func registerUser(username: String, password: String) -> AnyPublisher<RegisterDomainModel, AFError> {
        return self.apiRequest.request(RegistrationRouter.registerUser(username: username, password: password))
    }
}

// MARK: - RegistrationRouter

extension RegistrationServices {
    enum RegistrationRouter: NetworkRouter {
        case registerUser(username: String, password: String)

        // MARK: Internal

        var baseURLString: String {
            return "https://yourdomain.com/api/v1"
        }

        var path: String {
            return "authentication/register"
        }

        var headers: [String: String]? {
            return RequestHeaderBuilder.shared
                .addAcceptEncodingHeaders(type: .gzip)
                .addAcceptHeaders(type: .applicationJson)
                .addConnectionHeader(type: .keepAlive)
                .addAuthorizationHeader(type: .bearer)
                .addContentTypeHeader(type: .applicationJsonUTF8)
                .build()
        }

        var method: RequestMethod {
            return .post
        }

        var encoding: ParameterEncoding {
            return JSONEncoding.default
        }

        var params: [String: Any]? {
            switch self {
            case .registerUser(let username, let password):
                return ["username": username, "password": password]
            }
        }
    }
}
