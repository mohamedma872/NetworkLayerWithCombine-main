import Alamofire
import Combine
import Foundation

// MARK: - ViewModel

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
}

extension ViewModel {
    // MARK: - Register User

    // Call your API for registration from network manager
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
