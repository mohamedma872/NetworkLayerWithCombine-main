import UIKit
import Combine

// MARK: - ViewController

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
