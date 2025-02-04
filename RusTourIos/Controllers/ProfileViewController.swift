//
//  ProfileViewController.swift
//  TravelApp
//
//  Created by seif on 04/02/2025.
//

import UIKit

// MARK: - Models

struct User: Codable {
    var firstName: String
    var lastName: String
    var email: String
    var role: String
    var profileImage: UIImage?
    var notificationsEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case firstName, lastName, email, role, notificationsEnabled
    }
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let role: String
}

// MARK: - Auth Manager

class AuthManager {
    static let shared = AuthManager()
    private init() {}
    
    private let baseURL = "http://localhost:5281/api"
    private var token: String? {
        get { UserDefaults.standard.string(forKey: "jwtToken") }
        set { UserDefaults.standard.setValue(newValue, forKey: "jwtToken") }
    }
    
    var currentUser: User?
    
    var isLoggedIn: Bool {
        return currentUser != nil
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/Auth/login") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        
        let body = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Data"])))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let token = json?["token"] as? String {
                    self.token = token
                    
                    // Fetch user data (optional)
//                    let user = User(fir: "John Doe", email: email, profileImage: UIImage(systemName: "person.circle"), notificationsEnabled: true)
//                    self.currentUser = user
//                    completion(.success(user))
                } else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func register(firstName: String, lastName: String, email: String, password: String, role: String = "User", completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/Auth/register") else { return }

        let registerRequest = RegisterRequest(email: email, password: password, firstName: firstName, lastName: lastName, role: role)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONEncoder().encode(registerRequest)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                self.currentUser = user
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Sign out the user
    func signOut() {
        currentUser = nil
        token = nil
    }
}

// MARK: - ProfileViewController

class ProfileViewController: UIViewController {
    
    // MARK: Views for Not-Signed In state
    
    private let signInRegisterContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let signInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign In", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: Views for Signed-In (Profile) state
    
    /// A scroll view to contain the profile content
    private let profileContainer: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 50
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Editable personal data (for example, email)
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    // Notification toggle
    private let notificationsSwitch: UISwitch = {
        let sw = UISwitch()
        sw.translatesAutoresizingMaskIntoConstraints = false
        return sw
    }()
    
    private let notificationsLabel: UILabel = {
        let label = UILabel()
        label.text = "Enable Notifications"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let saveButton: UIButton = {
       let button = UIButton(type: .system)
       button.setTitle("Save Changes", for: .normal)
       button.backgroundColor = .systemBlue
       button.setTitleColor(.white, for: .normal)
       button.layer.cornerRadius = 8
       button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
       button.translatesAutoresizingMaskIntoConstraints = false
       return button
    }()
    
    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Out", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    // MARK: Setup Methods
    
    private func setupViews() {
        setupSignInRegisterView()
        setupProfileView()
    }
    
    /// Set up the “Sign In / Register” UI
    private func setupSignInRegisterView() {
        view.addSubview(signInRegisterContainer)
        NSLayoutConstraint.activate([
            signInRegisterContainer.topAnchor.constraint(equalTo: view.topAnchor),
            signInRegisterContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            signInRegisterContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            signInRegisterContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add and position the Sign In and Register buttons
        signInRegisterContainer.addSubview(signInButton)
        signInRegisterContainer.addSubview(registerButton)
        
        NSLayoutConstraint.activate([
            signInButton.centerXAnchor.constraint(equalTo: signInRegisterContainer.centerXAnchor),
            signInButton.centerYAnchor.constraint(equalTo: signInRegisterContainer.centerYAnchor, constant: -20),
            signInButton.widthAnchor.constraint(equalToConstant: 200),
            signInButton.heightAnchor.constraint(equalToConstant: 44),
            
            registerButton.centerXAnchor.constraint(equalTo: signInRegisterContainer.centerXAnchor),
            registerButton.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 20),
            registerButton.widthAnchor.constraint(equalToConstant: 200),
            registerButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Button actions
        signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(didTapRegister), for: .touchUpInside)
    }
    
    /// Set up the Profile UI for logged-in users.
    private func setupProfileView() {
        view.addSubview(profileContainer)
        NSLayoutConstraint.activate([
            profileContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            profileContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // A container view for the content inside the scroll view
        let profileContentView = UIView()
        profileContentView.translatesAutoresizingMaskIntoConstraints = false
        profileContainer.addSubview(profileContentView)
        NSLayoutConstraint.activate([
            profileContentView.topAnchor.constraint(equalTo: profileContainer.topAnchor),
            profileContentView.leadingAnchor.constraint(equalTo: profileContainer.leadingAnchor),
            profileContentView.trailingAnchor.constraint(equalTo: profileContainer.trailingAnchor),
            profileContentView.bottomAnchor.constraint(equalTo: profileContainer.bottomAnchor),
            profileContentView.widthAnchor.constraint(equalTo: profileContainer.widthAnchor)
        ])
        
        // Build a vertical stack to arrange the profile image, name, editable email, notification toggle, and save button.
        let stackView = UIStackView(arrangedSubviews: [
            profileImageView,
            nameLabel,
            emailTextField,
            createNotificationView(),
            saveButton,
            signOutButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        profileContentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: profileContentView.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: profileContentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: profileContentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: profileContentView.bottomAnchor, constant: -40)
        ])
        
        // Set fixed sizes
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            emailTextField.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            saveButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            signOutButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            signOutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        emailTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Initially hide the profile view (it will be shown only when the user is logged in)
        profileContainer.isHidden = true
        
        // (Optional) Add a target for the Save button to update user data.
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        
        signOutButton.addTarget(self, action: #selector(didTapSignOut), for: .touchUpInside)
    }
    
    /// Build a container view for the notification label and switch.
    private func createNotificationView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(notificationsLabel)
        container.addSubview(notificationsSwitch)
        notificationsLabel.translatesAutoresizingMaskIntoConstraints = false
        notificationsSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            notificationsLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            notificationsLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            notificationsSwitch.leadingAnchor.constraint(equalTo: notificationsLabel.trailingAnchor, constant: 8),
            notificationsSwitch.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            notificationsSwitch.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            container.heightAnchor.constraint(equalTo: notificationsLabel.heightAnchor)
        ])
        
        return container
    }
    
    // MARK: - UI Update
    
    private func updateUI() {
        let loggedIn = AuthManager.shared.isLoggedIn
        signInRegisterContainer.isHidden = loggedIn
        profileContainer.isHidden = !loggedIn
        
        if loggedIn, let user = AuthManager.shared.currentUser {
            nameLabel.text = user.firstName + " " + user.lastName
            emailTextField.text = user.email
            notificationsSwitch.isOn = user.notificationsEnabled
            profileImageView.image = user.profileImage ?? UIImage(systemName: "person.circle")
        } else {
            nameLabel.text = ""
            emailTextField.text = ""
            notificationsSwitch.isOn = false
            profileImageView.image = UIImage(systemName: "person.circle")
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func didTapSignIn() {
        let signInVC = SignInViewController()
        signInVC.modalPresentationStyle = .formSheet
        signInVC.completion = { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
        present(signInVC, animated: true, completion: nil)
    }
    
    @objc private func didTapRegister() {
        let registerVC = RegisterViewController()
        registerVC.modalPresentationStyle = .formSheet
        registerVC.completion = { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
        present(registerVC, animated: true, completion: nil)
    }
    
    @objc private func didTapSave() {
        // Save updated user data (e.g., email, notifications settings)
        // In your production code, call your API to update user details.
        guard var user = AuthManager.shared.currentUser else { return }
        user.email = emailTextField.text ?? user.email
        user.notificationsEnabled = notificationsSwitch.isOn
        AuthManager.shared.currentUser = user
        showAlert(title: "Success", message: "Your profile has been updated.")
    }
    
    @objc private func didTapSignOut() {
        let alert = UIAlertController(title: "Sign Out",
                                      message: "Are you sure you want to sign out?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { _ in
            AuthManager.shared.signOut()
            self.updateUI()  // Refresh UI to show sign-in/register options
        }))
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default))
        present(alert, animated: true)
    }
}

// MARK: - SignInViewController

class SignInViewController: UIViewController {
    
    /// Completion closure to notify the ProfileViewController after sign in
    var completion: (() -> Void)?
    
    private let emailTextField: UITextField = {
       let tf = UITextField()
       tf.placeholder = "Email"
       tf.borderStyle = .roundedRect
       tf.autocapitalizationType = .none
       tf.keyboardType = .emailAddress
       return tf
    }()
    
    private let passwordTextField: UITextField = {
       let tf = UITextField()
       tf.placeholder = "Password"
       tf.borderStyle = .roundedRect
       tf.isSecureTextEntry = true
       return tf
    }()
    
    private let signInButton: UIButton = {
       let button = UIButton(type: .system)
       button.setTitle("Sign In", for: .normal)
       button.backgroundColor = .systemBlue
       button.setTitleColor(.white, for: .normal)
       button.layer.cornerRadius = 8
       button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
       return button
    }()
    
    private let cancelButton: UIButton = {
       let button = UIButton(type: .system)
       button.setTitle("Cancel", for: .normal)
       button.setTitleColor(.systemRed, for: .normal)
       return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        
        signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
    }
    
    private func setupLayout() {
        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, signInButton, cancelButton])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
        
        emailTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        passwordTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        signInButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    @objc private func didTapSignIn() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter both email and password.")
            return
        }
        
        AuthManager.shared.signIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.dismiss(animated: true, completion: {
                        self?.completion?()
                    })
                case .failure(let error):
                    self?.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func didTapCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Sign In Error",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default))
        present(alert, animated: true)
    }
}

// MARK: - RegisterViewController

class RegisterViewController: UIViewController {
    
    /// Completion closure to notify the ProfileViewController after a successful registration
    var completion: (() -> Void)?
    
    private let firstnNameTextField: UITextField = {
       let tf = UITextField()
       tf.placeholder = "First Name"
       tf.borderStyle = .roundedRect
       return tf
    }()
    
    private let LastNameTextField: UITextField = {
       let tf = UITextField()
       tf.placeholder = "Last Name"
       tf.borderStyle = .roundedRect
       return tf
    }()
    
    private let emailTextField: UITextField = {
       let tf = UITextField()
       tf.placeholder = "Email"
       tf.borderStyle = .roundedRect
       tf.autocapitalizationType = .none
       tf.keyboardType = .emailAddress
       return tf
    }()
    
    private let passwordTextField: UITextField = {
       let tf = UITextField()
       tf.placeholder = "Password"
       tf.borderStyle = .roundedRect
       tf.isSecureTextEntry = true
       return tf
    }()
    
    private let registerButton: UIButton = {
       let button = UIButton(type: .system)
       button.setTitle("Register", for: .normal)
       button.backgroundColor = .systemGreen
       button.setTitleColor(.white, for: .normal)
       button.layer.cornerRadius = 8
       button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
       return button
    }()
    
    private let cancelButton: UIButton = {
       let button = UIButton(type: .system)
       button.setTitle("Cancel", for: .normal)
       button.setTitleColor(.systemRed, for: .normal)
       return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        
        registerButton.addTarget(self, action: #selector(didTapRegister), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
    }
    
    private func setupLayout() {
        let stackView = UIStackView(arrangedSubviews: [firstnNameTextField,LastNameTextField, emailTextField, passwordTextField, registerButton, cancelButton])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
        
        firstnNameTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        LastNameTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        emailTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        passwordTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        registerButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    @objc private func didTapRegister() {
        guard let firstName = firstnNameTextField.text, !firstName.isEmpty,
              let lastName = LastNameTextField.text, !lastName.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please fill all fields.")
            return
        }
        
        AuthManager.shared.register(firstName: firstName, lastName: lastName, email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.dismiss(animated: true, completion: {
                        self?.completion?()
                    })
                case .failure(let error):
                    self?.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func didTapCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Register Error",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default))
        present(alert, animated: true)
    }
}
