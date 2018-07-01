import Alamofire
import Cocoa
import EntropyKit

class LoginViewController: NSViewController {
    @IBOutlet private var username: NSTextField!
    @IBOutlet private var password: NSSecureTextField!
    @IBOutlet private var homeserver: NSTextField!
    @IBOutlet private var info: NSTextField!
    @IBOutlet private var errorMessageField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        clearError()
        info.stringValue = "\(Bundle.main.applicationName) \(Bundle.main.shortVersion) - \(Bundle.main.copyright)"

        loadDebugLoginFromKeychain()

        username.delegate = self
        password.delegate = self
        homeserver.delegate = self
    }

    private func loadDebugLoginFromKeychain() {
        #if DEBUG
            let query: NSDictionary = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: Bundle.main.applicationName,
                kSecReturnAttributes: kCFBooleanTrue,
                kSecReturnData: kCFBooleanTrue,
                kSecMatchLimit: kSecMatchLimitOne,
            ]

            var dataTypeRef: CFTypeRef?
            let resultCode = SecItemCopyMatching(query, &dataTypeRef)

            switch resultCode {
            case errSecItemNotFound:
                print("Debug login not found.")
            case errSecSuccess:
                let result = dataTypeRef as? [CFString: Any]

                if let username = result?[kSecAttrAccount] as? String {
                    self.username.stringValue = username
                }

                if let data = result?[kSecValueData] as? Data, let password = String(data: data, encoding: .utf8) {
                    self.password.stringValue = password
                }

                if let homeserver = result?[kSecAttrComment] as? String {
                    self.homeserver.stringValue = homeserver
                }
            default:
                print(SecCopyErrorMessageString(resultCode, nil) ?? "Unknown error while accessing Keychain.")
            }
        #endif
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.isExcludedFromWindowsMenu = true
        if Entropy.default.state == .loggedIn {
            startSyncingAndShowMainWindow()
        }
    }

    private func login() {
        clearError()

        let credentialsResult = Validation.validateLoginCredentials(username: username.stringValue, password: password.stringValue, homeserver: homeserver.stringValue)

        guard let credentials = credentialsResult.value else {
            showLoginError(credentialsResult.error)
            return
        }

        username.stringValue = credentials.username
        homeserver.stringValue = credentials.homeserver.absoluteString
        // No need to set the password as we can't validate and thus not change it anyway.

        Entropy.default.login(credentials: credentials) { result in
            if let error = result.error {
                self.showLoginError(error)
                return
            }
            self.startSyncingAndShowMainWindow()
        }
    }

    private func startSyncingAndShowMainWindow() {
        Entropy.default.startSyncing()
        view.window!.close()
        performSegue(withIdentifier: "ShowMainWindow", sender: self)
    }

    @IBAction func onLoginButtonClicked(_: NSButton) {
        login()
    }
}

// MARK: - Error Handling

extension LoginViewController {
    private func clearError() {
        errorMessageField.stringValue = ""
    }

    private func showError(_ error: String) {
        errorMessageField.stringValue = error
    }

    private func showLoginError(_ error: Error?) {
        guard let error = error else {
            return
        }

        switch error {
        case let error as Alamofire.AFError:
            unwrapAFError(error)
        default:
            showError(error.localizedDescription)
        }
    }

    private func unwrapAFError(_ error: Alamofire.AFError) {
        switch error {
        case .invalidURL(url: _):
            showError("Invalid Homeserver URL.")
        case .multipartEncodingFailed(reason: _):
            fallthrough
        case .parameterEncodingFailed(reason: _):
            fallthrough
        case .responseSerializationFailed(reason: _):
            showError("Internal Error.")
        case let .responseValidationFailed(reason):
            switch reason {
            case let .unacceptableStatusCode(code):
                switch code {
                case 403:
                    showError("Incorrect username or password.")
                default:
                    showError(error.localizedDescription)
                }
            default:
                showError("Internal Error.")
            }
        }
    }
}

// MARK: - NSTextFieldDelegate

extension LoginViewController: NSTextFieldDelegate {
    public func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline) {
            login()
            return true
        } else {
            return false
        }
    }
}
