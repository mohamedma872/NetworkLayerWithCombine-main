Here's a comprehensive README file that covers all the provided code, its purpose, and how to use it:

---

# Network Layer with Combine and Alamofire

This project demonstrates a robust network layer implementation using Combine and Alamofire in Swift. It includes a `NetworkManager`, `APIRequest`, `ViewModel`, and a sample `ViewController` to show how to make network requests and handle loading states.

## Table of Contents

1. [Introduction](#introduction)
2. [Components](#components)
    - [NetworkManager](#networkmanager)
    - [APIRequest](#apirequest)
    - [ViewModel](#viewmodel)
    - [ViewController](#viewcontroller)
    - [RegistrationServices](#registrationservices)
    - [RequestHeaderBuilder](#requestheaderbuilder)
3. [Usage](#usage)
4. [Example](#example)

## Introduction

This project demonstrates how to create a reusable and scalable network layer using Alamofire and Combine. It includes mechanisms for managing API requests, handling loading states, and displaying activity indicators during network operations.

## Components

### NetworkManager

`NetworkManager` is a singleton that manages API requests and dependencies like `AuthenticationRepository`.

```swift
import Foundation

class NetworkManager {
    // MARK: - Properties

    static let shared: NetworkManager = {
        let instance = NetworkManager()
        return instance
    }()
    
    lazy var authenticationRepository: AuthenticationRepository = {
        return AuthenticationRepository(apiRequest: apiRequest)
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
```

### APIRequest

`APIRequest` handles making network requests using Alamofire.

```swift
import Alamofire
import Combine
import Foundation
import Swime

protocol APIRequestProtocols {
    func request<T: Decodable & Encodable>(_ endpoint: URLRequestConvertible) -> AnyPublisher<T, AFError>
    func uploadRequest<T: Decodable & Encodable>(_ endpoint: URLRequestConvertible, file: Data?, fileName: String?, progressCompletion: @escaping (Double) -> Void) -> AnyPublisher<T, AFError>
}

class APIRequest {
    // MARK: Lifecycle

    init() {
        let config = URLSessionConfiguration.af.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        self.sessionManager = Session(configuration: config, interceptor: Interceptor(adapter: NetworkAdapter(), retrier: NetworkRetrier(limit: 2, delay: 30)))
    }
    
    deinit {
        debugPrint("APIRequest deinited")
    }

    // MARK: Private

    private var sessionManager: Session
    private let queue = DispatchQueue(label: "network-queue", qos: .userInitiated, attributes: .concurrent)
}

extension APIRequest: APIRequestProtocols {
    func uploadRequest<T: Decodable & Encodable>(_ endpoint: URLRequestConvertible, file: Data?, fileName: String?, progressCompletion: @escaping (Double) -> Void) -> AnyPublisher<T, AFError> {
        do {
            let urlRequest = try endpoint.asURLRequest()
            let request = sessionManager.upload(multipartFormData: { multiPart in
                guard let file = file else { return }
                guard let type = Swime.mimeType(data: file) else { return }
                multiPart.append(file, withName: fileName ?? "file", mimeType: type.mime)
            }, with: urlRequest)
            return request
                .validate()
                .uploadProgress { progress in
                    progressCompletion(progress.fractionCompleted)
                }
                .publishDecodable(type: T.self)
                .value()
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: AFError.createURLRequestFailed(error: error)).eraseToAnyPublisher()
        }
    }

    func request<T: Decodable & Encodable>(_ endpoint: URLRequestConvertible) -> AnyPublisher<T, AFError> {
        do {
            let urlRequest = try endpoint.asURLRequest()
            let request = sessionManager.request(urlRequest)
            return request
                .validate()
                .publishDecodable(type: T.self)
                .value()
                .subscribe(on: queue)
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: AFError.createURLRequestFailed(error: error)).eraseToAnyPublisher()
        }
    }
}
```

### ViewModel

`ViewModel` manages the business logic and state for the `ViewController`.

```swift
import Alamofire
import Combine
import Foundation

class ViewModel {
    // MARK: - Properties

    var error = CurrentValueSubject<AFError?, Never>(nil)
    var registerModel = CurrentValueSubject<RegisterDomainModel?, Never>(nil)
    var loading = CurrentValueSubject<Bool, Never>(false)
    var disposeBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    deinit {
        NetworkManager.destroy()
        debugPrint("ViewModel deinited")
    }

    // MARK: - Register User

    func registerUserWith(username: String, password: String) {
        loading.send(true) // Set loading to true when the request starts

        NetworkManager.shared.authenticationRepository.registrationService
            .registerUser(username: username, password: password)
            .subscribe(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] errorCompletion in
                self?.loading.send(false) // Set loading to false when the request completes
                switch errorCompletion {
                case .failure(let error):
                    self?.error.send(error)
                default:
                    break
                }
            }, receiveValue: { [weak self] model in
                self?.registerModel.send(model)
            })
            .store(in: &self.disposeBag)
    }
}
```

### ViewController

`ViewController` binds to the `ViewModel` and manages the UI, including showing a loading indicator.

```swift
import UIKit
import Combine

class ViewController: UIViewController {
    // MARK: - Properties

    private let viewModel = ViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupActivityIndicator()
        setupBindings()
        registerUser(username: "username", password: "password")
    }

    deinit {
        debugPrint("ViewController deinited")
    }

    // MARK: - Private Methods

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func registerUser(username: String, password: String) {
        viewModel.registerUserWith(username: username, password: password)
    }

    private func setupBindings() {
        bindError()
        bindRegisterModel()
        bindLoading()
    }

    private func bindError() {
        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    // Show your error
                    print("Error: \(error.localizedDescription)")
                }
            }
            .store(in: &cancellables)
    }

    private func bindRegisterModel() {
        viewModel.registerModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] model in
                guard let self = self else { return }
                if let model = model {
                    // Do something with your model
                    print("Model: \(model)")
                }
            }
            .store(in: &cancellables)
    }

    private func bindLoading() {
        viewModel.loading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.activityIndicator.startAnimating()
                } else {
                    self.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }
}
```

### RegistrationServices

`RegistrationServices` handles user registration requests.

```swift
import Alamofire
import Combine
import Foundation

protocol RegistrationServicesProtocols {
    func registerUser(username: String, password: String) -> AnyPublisher<RegisterDomainModel, AFError>
}

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

extension RegistrationServices: RegistrationServicesProtocols {
    func registerUser(username: String, password: String) -> AnyPublisher<RegisterDomainModel, AFError> {
        return self.apiRequest.request(RegistrationRouter.registerUser(username: username, password: password))
    }
}

extension RegistrationServices {
    enum RegistrationRouter: NetworkRouter {
        case registerUser(username: String, password: String)

        var baseURLString: String {
            return "https

://yourdomain.com/api/v1"
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
```

### RequestHeaderBuilder

`RequestHeaderBuilder` builds headers for network requests.

```swift
import Foundation

enum ConnectionHeaders: String {
    case keepAlive = "keep-alive"
    case close = "close"
    var name: String {
        return "connection"
    }
}

enum AcceptHeaders: String {
    case all = "*/*"
    case applicationJson = "application/json"
    case applicationJsonUTF8 = "application/json; charset=utf-8"
    case text = "text/plain"
    case combinedAll = "application/json, text/plain, */*"
    var name: String {
        return "accept"
    }
}

enum ContentTypeHeaders: String {
    case applicationJson = "application/json"
    case applicationJsonUTF8 = "application/json; charset=utf-8"
    case urlEncoded = "application/x-www-form-urlencoded"
    case formData = "multipart/form-data"
    var name: String {
        return "content-type"
    }
}

enum AcceptEncodingHeaders: String {
    case gzip = "gzip"
    case compress = "compress"
    case deflate = "deflate"
    case br = "br"
    case identity = "identity"
    case all = "*"
    var name: String {
        return "accept-encoding"
    }
}

enum AcceptLanguageHeaders: String {
    case en = "en"
    case fa = "fa"
    case all = "*"
    var name: String {
        return "accept-language"
    }
}

enum AuthorizationHeaders: String {
    case basic = "Basic"
    case bearer = "Bearer"
    var name: String {
        return "authorization"
    }
}

class RequestHeaderBuilder {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = RequestHeaderBuilder()

    @discardableResult
    func addContentTypeHeader(type: ContentTypeHeaders) -> RequestHeaderBuilder {
        self.headers.updateValue(type.rawValue, forKey: type.name)
        return self
    }

    @discardableResult
    func addConnectionHeader(type: ConnectionHeaders) -> RequestHeaderBuilder {
        self.headers.updateValue(type.rawValue, forKey: type.name)
        return self
    }

    @discardableResult
    func addAcceptHeaders(type: AcceptHeaders) -> RequestHeaderBuilder {
        self.headers.updateValue(type.rawValue, forKey: type.name)
        return self
    }

    @discardableResult
    func addAcceptLanguageHeaders(type: AcceptLanguageHeaders) -> RequestHeaderBuilder {
        self.headers.updateValue(type.rawValue, forKey: type.name)
        return self
    }

    @discardableResult
    func addAcceptEncodingHeaders(type: AcceptEncodingHeaders) -> RequestHeaderBuilder {
        self.headers.updateValue(type.rawValue, forKey: type.name)
        return self
    }

    @discardableResult
    func addAuthorizationHeader(type: AuthorizationHeaders) -> RequestHeaderBuilder {
        let token = "" // Replace with actual token logic
        self.headers.updateValue("\(type.rawValue) \(token)", forKey: type.name)
        return self
    }

    @discardableResult
    func addCustomHeaders(headers: [String: String]) -> RequestHeaderBuilder {
        for (key, value) in headers {
            self.headers.updateValue(value, forKey: key)
        }
        return self
    }

    @discardableResult
    func addCustomHeader(name: String, value: String) -> RequestHeaderBuilder {
        self.headers.updateValue(value, forKey: name)
        return self
    }

    func build() -> [String: String] {
        return self.headers
    }

    // MARK: Private

    private var headers: [String: String] = .init()
}
```

## Usage

1. **Initialize `NetworkManager` and `APIRequest`**:
    ```swift
    let networkManager = NetworkManager.shared
    let apiRequest = APIRequest()
    ```

2. **Use `ViewModel` to manage state and network requests**:
    ```swift
    let viewModel = ViewModel()
    viewModel.registerUserWith(username: "username", password: "password")
    ```

3. **Bind ViewModel properties to your ViewController**:
    ```swift
    class ViewController: UIViewController {
        private let viewModel = ViewModel()
        private var cancellables = Set<AnyCancellable>()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupBindings()
            viewModel.registerUserWith(username: "username", password: "password")
        }
        
        private func setupBindings() {
            viewModel.error
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in
                    // Handle error
                }
                .store(in: &cancellables)
                
            viewModel.registerModel
                .receive(on: DispatchQueue.main)
                .sink { [weak self] model in
                    // Handle model
                }
                .store(in: &cancellables)
                
            viewModel.loading
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isLoading in
                    // Show or hide loading indicator
                }
                .store(in: &cancellables)
        }
    }
    ```

## Example

An example usage of the provided network layer components in a sample app:

```swift
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let viewController = ViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        return true
    }
}
```

---

This README file covers the purpose of each component, how to use them, and provides an example setup for integrating these components into a project.
