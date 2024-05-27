import Foundation

class AuthenticationRepository {
    // MARK: - Properties

    private let apiRequest: APIRequest
    lazy var registrationService: RegistrationServices = {
        return RegistrationServices(apiRequest: apiRequest)
    }()

    // MARK: - Lifecycle

    init(apiRequest: APIRequest) {
        self.apiRequest = apiRequest
    }

    deinit {
        debugPrint("AuthenticationRepository deinited")
    }
}
