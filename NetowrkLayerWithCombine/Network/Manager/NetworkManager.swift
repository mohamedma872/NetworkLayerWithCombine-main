import Foundation

class NetworkManager {
    // MARK: - Properties

    static let shared: NetworkManager = {
        let instance = NetworkManager()
        return instance
    }()
    
    lazy var authenticationRepository: AuthenticationRepository = {
        return AuthenticationRepository(apiRequest: self.apiRequest)
    }()
    
    private lazy var apiRequest: APIRequest = APIRequest()
    
    // MARK: - Lifecycle

    private init() {}
    
    deinit {
        debugPrint("NetworkManager deinited")
    }

    // MARK: - Methods

    class func destroy() {
        // This method is retained for backward compatibility,
        // but the singleton pattern means this method won't actually destroy the shared instance.
        // Implement your own logic if needed to reset the state.
    }
}
