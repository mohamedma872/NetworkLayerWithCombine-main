import Alamofire
import Foundation

typealias RetrierCompletion = (RetryResult) -> Void

// MARK: - NetworkRetrier

class NetworkRetrier: RequestRetrier {
    // MARK: Lifecycle

    init(limit: Int, delay: TimeInterval) {
        self.limit = limit
        self.delay = delay
    }

    // MARK: Internal

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping RetrierCompletion) {
        guard request.retryCount < limit else {
            completion(.doNotRetry)
            return
        }
        guard let statusCode = request.response?.statusCode else {
            completion(.doNotRetry)
            return
        }
        switch statusCode {
        case 401:
            // Handle token refresh logic here
            // Example: refreshToken { success in completion(success ? .retry : .doNotRetry) }
            completion(.retryWithDelay(delay))
        default:
            completion(.retryWithDelay(delay))
        }
    }

    // MARK: Private

    private var limit: Int
    private var delay: TimeInterval
}

// MARK: - NetworkAdapter

class NetworkAdapter: RequestAdapter {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var adaptedRequest = urlRequest
        // Replace "token" with your actual token retrieval logic
        guard let token = fetchAuthToken() else {
            return completion(.success(adaptedRequest))
        }
        adaptedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        completion(.success(adaptedRequest))
    }

    // Example function to fetch the auth token
    private func fetchAuthToken() -> String? {
        // Implement your logic to retrieve the token here
        return "your_token"
    }
}
