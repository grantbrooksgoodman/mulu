//
//  SignInController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 18/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

/* Third-party Frameworks */
import Firebase
import FirebaseAuth

class SignInController: UIViewController, MFMailComposeViewControllerDelegate
{
    //==================================================//

    /* MARK: Interface Builder UI Elements */

    //UIButtons
    @IBOutlet var forgotPasswordButton: UIButton!
    @IBOutlet var signInButton:         UIButton!
    @IBOutlet var signUpButton:         UIButton!

    //UITextFields
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var usernameTextField: UITextField!

    //==================================================//

    /* MARK: Class-level Variable Declarations */

    var buildInstance: Build!

    //==================================================//
    
    /* MARK: State Variables */
    
    var firstTry = true
    
    //==================================================//

    /* MARK: Initializer Function */

    func initializeController()
    {
        lastInitializedController = self
        buildInstance = Build(self)
    }

    //==================================================//

    /* MARK: Overridden Functions */

    override func viewDidLoad()
    {
        super.viewDidLoad()

        view.setBackground(withImageNamed: "Gradient.png")

        if let email = UserDefaults.standard.value(forKey: "email") as? String,
           let password = UserDefaults.standard.value(forKey: "password") as? String
        {
            usernameTextField.text = email
            passwordTextField.text = password
        }

        if let agreed = UserDefaults.standard.value(forKey: "agreedToLicense") as? Bool
        {
            agreedToLicense = agreed
        }

        usernameTextField.delegate = self
        passwordTextField.delegate = self

        usernameTextField.tag = aTagFor("usernameTextField")
        passwordTextField.tag = aTagFor("passwordTextField")
        signInButton.tag = aTagFor("signInButton")

        let bottomButtonAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue]

        let signUpString = NSAttributedString(string: "Sign up", attributes: bottomButtonAttributes)
        let forgotPasswordString = NSAttributedString(string: "Forgot password?", attributes: bottomButtonAttributes)

        signUpButton.setAttributedTitle(signUpString, for: .normal)
        forgotPasswordButton.setAttributedTitle(forgotPasswordString, for: .normal)

        signInButton.layer.cornerRadius = 5

        for view in view.subviews
        {
            view.alpha = 0
        }

        #warning("DEBUG ONLY!")
        //usernameTextField.text = "admin@getmulu.com"
        //passwordTextField.text = "123456"

        if !signedOut
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) { self.signInButton(self.signInButton!) }
        }
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        initializeController()

        currentFile = #file
        buildInfoController?.view.isHidden = !preReleaseApplication

        buildInfoController?.customYOffset = 30
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        usernameTextField.addGreyUnderline()
        passwordTextField.addGreyUnderline()

        UIView.animate(withDuration: 0.15) {
            for view in self.view.subviews
            {
                view.alpha = view.tag == aTagFor("signInButton") ? 0.6 : 1
            }
        }
    }

    override func prepare(for _: UIStoryboardSegue, sender _: Any?)
    {}

    //==================================================//

    /* MARK: Interface Builder Actions */

    @IBAction func forgotPasswordButton(_: Any)
    {
        performSegue(withIdentifier: "ForgotPasswordFromSignInSegue", sender: self)
    }

    @IBAction func signUpButton(_: Any)
    {
        performSegue(withIdentifier: "SignUpFromSignInSegue", sender: self)
    }

    @IBAction func signInButton(_: Any)
    {
        guard usernameTextField.text!.lowercasedTrimmingWhitespace != "" && passwordTextField.text!.lowercasedTrimmingWhitespace != "" else
        {
            if (self.firstTry) {
                self.firstTry = false
            } else {
                let message = "Please evaluate all fields before signing in."

                AlertKit().errorAlertController(title:                       "Enter Full Credentials",
                                                message:                     message,
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               false,
                                                extraInfo:                   nil,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)

                report(message, errorCode: nil, isFatal: false, metadata: [#file, #function, #line]);
                return
            }
            return
        }

        guard usernameTextField.text!.isValidEmail else
        {
            let message = "The e-mail address is improperly formatted. Please try again."

            AlertKit().errorAlertController(title:                       "Invalid E-mail",
                                            message:                     message,
                                            dismissButtonTitle:          "OK",
                                            additionalSelectors:         nil,
                                            preferredAdditionalSelector: nil,
                                            canFileReport:               false,
                                            extraInfo:                   nil,
                                            metadata:                    [#file, #function, #line],
                                            networkDependent:            false)

            report(message, errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return
        }

        guard passwordTextField.text!.count > 5 else
        {
            let message = "Passwords must be 6 or more characters. Please try again."

            AlertKit().errorAlertController(title:                       "Invalid Password Length",
                                            message:                     message,
                                            dismissButtonTitle:          "OK",
                                            additionalSelectors:         nil,
                                            preferredAdditionalSelector: nil,
                                            canFileReport:               false,
                                            extraInfo:                   nil,
                                            metadata:                    [#file, #function, #line],
                                            networkDependent:            false)

            report(message, errorCode: nil, isFatal: false, metadata: [#file, #function, #line]); return
        }

        //signInRandomUser()

        showProgressHUD()

        Auth.auth().signIn(withEmail: usernameTextField.text!, password: passwordTextField.text!) { returnedResult, returnedError in
            if let result = returnedResult
            {
                UserSerializer().getUser(withIdentifier: result.user.uid) { returnedUser, errorDescriptor in
                    if let user = returnedUser
                    {
                        currentUser = user

                        if let token = pushToken
                        {
                            currentUser!.updatePushTokens(token) { errorDescriptor in
                                if let error = errorDescriptor
                                {
                                    report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                                }
                            }
                        }

                        currentUser!.deSerializeAssociatedTeams { returnedTeams, errorDescriptor in
                            if let teams = returnedTeams
                            {
                                hideHUD(delay: nil)

                                if let deSerializedTeams = user.DSAssociatedTeams
                                {
                                    for team in deSerializedTeams
                                    {
                                        team.setDSParticipants()

                                        if let associatedTournament = team.associatedTournament
                                        {
                                            Messaging.messaging().subscribe(toTopic: associatedTournament.name!.replacingOccurrences(of: " ", with: "_"))

                                            associatedTournament.setDSTeams()
                                        }
                                    }
                                }

                                if let email = UserDefaults.standard.value(forKey: "email") as? String,
                                   email != self.usernameTextField.text!
                                {
                                    UserDefaults.standard.removeObject(forKey: "skippedChallenges")
                                    UserDefaults.standard.removeObject(forKey: "agreedToLicense")
                                    agreedToLicense = false
                                }

                                UserDefaults.standard.setValue(self.usernameTextField.text!, forKey: "email")
                                UserDefaults.standard.setValue(self.passwordTextField.text!, forKey: "password")

                                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                                    if teams.count > 1
                                    {
                                        let actionSheet = UIAlertController(title: "Select Team", message: "Select the team you would like to sign in to.", preferredStyle: .actionSheet)

                                        for team in teams.sorted(by: { $0.name < $1.name })
                                        {
                                            let teamAction = UIAlertAction(title: team.name!, style: .default) { _ in
                                                currentTeam = team

//                                                if self.usernameTextField.text == "admin@getmulu.com"
//                                                {
//                                                    self.presentAdminConsoleAlert()
//                                                }
//                                                else
//                                                {
                                                if agreedToLicense
                                                {
                                                    self.performSegue(withIdentifier: "TabBarFromSignInSegue", sender: self)
                                                }
                                                else { self.performSegue(withIdentifier: "LicenseFromSignInSegue", sender: self) }
//                                                }
                                            }

                                            actionSheet.addAction(teamAction)
                                        }

                                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                                            // It will dismiss action sheet
                                        }

                                        actionSheet.addAction(cancelAction)

                                        self.present(actionSheet, animated: true, completion: nil)
                                    }
                                    else
                                    {
                                        currentTeam = teams[0]

//                                        if self.usernameTextField.text == "admin@getmulu.com"
//                                        {
//                                            self.presentAdminConsoleAlert()
//                                        }
//                                        else
//                                        {
                                        if agreedToLicense
                                        {
                                            self.performSegue(withIdentifier: "TabBarFromSignInSegue", sender: self)
                                        }
                                        else { self.performSegue(withIdentifier: "LicenseFromSignInSegue", sender: self) }
//                                        }
                                    }
                                }
                            }
                            else if let error = errorDescriptor
                            {
                                if error == "This User is not a member of any Team."
                                {
                                    UserDefaults.standard.setValue(self.usernameTextField.text!, forKey: "email")
                                    UserDefaults.standard.setValue(self.passwordTextField.text!, forKey: "password")

//                                    if self.usernameTextField.text == "admin@getmulu.com"
//                                    {
//                                        self.performSegue(withIdentifier: "CMSSegue", sender: self)
//                                    }
//                                    else {
                                    self.presentWaitlistAlert() //}
                                }
                                else
                                {
                                    AlertKit().errorAlertController(title:                       nil,
                                                                    message:                     error,
                                                                    dismissButtonTitle:          "OK",
                                                                    additionalSelectors:         nil,
                                                                    preferredAdditionalSelector: nil,
                                                                    canFileReport:               true,
                                                                    extraInfo:                   nil,
                                                                    metadata:                    [#file, #function, #line],
                                                                    networkDependent:            false)

                                    report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                                }
                            }
                        }
                    }
                    else if let error = errorDescriptor
                    {
                        AlertKit().errorAlertController(title:                       nil,
                                                        message:                     error,
                                                        dismissButtonTitle:          "OK",
                                                        additionalSelectors:         nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport:               true,
                                                        extraInfo:                   nil,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            false)

                        report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                    }
                }
            }
            else if let error = returnedError
            {
                let message = errorInfo(error)

                var alertMessage = errorInfo(error)

                if alertMessage.hasPrefix("There is no user")
                {
                    alertMessage = "There doesn't seem to be a user with those credentials. Please verify your entries and try again."
                }
                else if alertMessage.hasPrefix("The password is invalid")
                {
                    alertMessage = "The password was incorrect. Please try again."
                }

                AlertKit().errorAlertController(title:                       "Sign In Failed",
                                                message:                     alertMessage,
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               true,
                                                extraInfo:                   message,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            true)

                report(message, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
            else
            {
                AlertKit().errorAlertController(title:                       nil,
                                                message:                     nil,
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               false,
                                                extraInfo:                   nil,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)

                report("An unknown error occurred.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
        }
    }

    func presentAdminConsoleAlert()
    {
        #warning("DEBUG ONLY!")
        AlertKit().optionAlertController(title: "Select User Type",
                                         message: "Please select the console you would like to sign-in to.",
                                         cancelButtonTitle: nil,
                                         additionalButtons: [("Administrator", false), ("Layman User", false)],
                                         preferredActionIndex: nil,
                                         networkDependent: true) { selectedIndex in
            if let index = selectedIndex
            {
                if index == 0
                {
                    self.performSegue(withIdentifier: "CMSSegue", sender: self)
                }
                else if index == 1
                {
                    self.performSegue(withIdentifier: "TabBarFromSignInSegue", sender: self)
                }
            }
        }
    }

    //==================================================//

    /* MARK: Other Functions */

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        buildInstance.handleMailComposition(withController: controller, withResult: result, withError: error)
    }

    @objc func presentJoinCodeAlert()
    {
        let textFieldAttributes: [AlertKit.AlertControllerTextFieldAttribute: Any] =
            [.capitalisationType:  UITextAutocapitalizationType.none,
             .correctionType:      UITextAutocorrectionType.no,
             .editingMode:         UITextField.ViewMode.never,
             .keyboardAppearance:  UIKeyboardAppearance.default,
             .keyboardType:        UIKeyboardType.default,
             .placeholderText:     "",
             .sampleText:          "",
             .textAlignment:       NSTextAlignment.center]

        AlertKit().textAlertController(title: "Join Code", message: "Enter your team's 2-word join code below.", cancelButtonTitle: nil, additionalButtons: [("Join Team", false)], preferredActionIndex: 0, textFieldAttributes: textFieldAttributes, networkDependent: true) { returnedString, selectedIndex in
            if let index = selectedIndex, index == 0
            {
                if let string = returnedString, string.lowercasedTrimmingWhitespace != ""
                {
                    guard string.trimmingBorderedWhitespace.components(separatedBy: " ").count == 2 else
                    { AlertKit().errorAlertController(title: "Invalid Format",
                                                      message: "Join codes consist of 2 words only. Please try again.",
                                                      dismissButtonTitle: "Cancel",
                                                      additionalSelectors: ["Try Again": #selector(SignInController.presentJoinCodeAlert)],
                                                      preferredAdditionalSelector: 0,
                                                      canFileReport: false,
                                                      extraInfo: nil,
                                                      metadata: [#file, #function, #line],
                                                      networkDependent: true); return }

                    self.tryToJoin(teamWithCode: string.trimmingBorderedWhitespace)
                }
                else
                {
                    AlertKit().errorAlertController(title: "Nothing Entered",
                                                    message: "No text was entered. Please try again.",
                                                    dismissButtonTitle: "Cancel",
                                                    additionalSelectors: ["Try Again": #selector(SignInController.presentJoinCodeAlert)],
                                                    preferredAdditionalSelector: 0,
                                                    canFileReport: false,
                                                    extraInfo: nil,
                                                    metadata: [#file, #function, #line],
                                                    networkDependent: true)
                }
            }
        }
    }

    func presentWaitlistAlert()
    {
        AlertKit().optionAlertController(title: "On Waitlist", message: "You are currently on the waitlist to be added to a team.\n\nYou may also add yourself to a team if you know its join code.", cancelButtonTitle: "Continue Waiting", additionalButtons: [("Enter Join Code", false)], preferredActionIndex: 0, networkDependent: true) { selectedIndex in
            if let index = selectedIndex, index == 0
            {
                self.presentJoinCodeAlert()
            }
        }
    }

    func signInRandomUser()
    {
        showProgressHUD()

        UserSerializer().getRandomUsers(amountToGet: 1) { returnedIdentifiers, errorDescriptor in
            if let identifiers = returnedIdentifiers
            {
                UserSerializer().getUser(withIdentifier: identifiers[0]) { returnedUser, errorDescriptor in
                    if let user = returnedUser
                    {
                        currentUser = user

                        print("Signing in as \(user.firstName!) \(user.lastName!).")
                        print("Identifier: \(user.associatedIdentifier!)")

                        currentUser!.deSerializeAssociatedTeams { returnedTeams, errorDescriptor in
                            if let teams = returnedTeams
                            {
                                hideHUD(delay: nil)

                                if let deSerializedTeams = user.DSAssociatedTeams
                                {
                                    for team in deSerializedTeams
                                    {
                                        team.setDSParticipants()

                                        if let associatedTournament = team.associatedTournament
                                        {
                                            associatedTournament.setDSTeams()
                                        }
                                    }
                                }

                                if let email = UserDefaults.standard.value(forKey: "email") as? String,
                                   email != self.usernameTextField.text!
                                {
                                    UserDefaults.standard.removeObject(forKey: "skippedChallenges")
                                }

                                UserDefaults.standard.setValue(self.usernameTextField.text!, forKey: "email")
                                UserDefaults.standard.setValue(self.passwordTextField.text!, forKey: "password")

                                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                                    if teams.count > 1
                                    {
                                        let actionSheet = UIAlertController(title: "Select Team", message: "Select the team you would like to sign in to.", preferredStyle: .actionSheet)

                                        for team in teams.sorted(by: { $0.name < $1.name })
                                        {
                                            let teamAction = UIAlertAction(title: team.name!, style: .default) { _ in

                                                currentTeam = team

                                                self.performSegue(withIdentifier: "TabBarFromSignInSegue", sender: self)
                                            }

                                            actionSheet.addAction(teamAction)
                                        }

                                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }

                                        actionSheet.addAction(cancelAction)

                                        self.present(actionSheet, animated: true, completion: nil)
                                    }
                                    else
                                    {
                                        currentTeam = teams[0]

                                        self.performSegue(withIdentifier: "TabBarFromSignInSegue", sender: self)
                                    }
                                }
                            }
                            else if let error = errorDescriptor
                            {
                                if error == "This User is not a member of any Team."
                                {
                                    self.presentWaitlistAlert()
                                }
                                else
                                {
                                    AlertKit().errorAlertController(title:                       nil,
                                                                    message:                     error,
                                                                    dismissButtonTitle:          "OK",
                                                                    additionalSelectors:         nil,
                                                                    preferredAdditionalSelector: nil,
                                                                    canFileReport:               true,
                                                                    extraInfo:                   nil,
                                                                    metadata:                    [#file, #function, #line],
                                                                    networkDependent:            false)

                                    report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                                }
                            }
                        }
                    }
                    else if let error = errorDescriptor
                    {
                        AlertKit().errorAlertController(title:                       nil,
                                                        message:                     error,
                                                        dismissButtonTitle:          "OK",
                                                        additionalSelectors:         nil,
                                                        preferredAdditionalSelector: nil,
                                                        canFileReport:               true,
                                                        extraInfo:                   nil,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            false)

                        report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                    }
                }
            }
            else if let error = errorDescriptor
            {
                AlertKit().errorAlertController(title:                       nil,
                                                message:                     error,
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               true,
                                                extraInfo:                   nil,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)

                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
            else
            {
                AlertKit().errorAlertController(title:                       nil,
                                                message:                     nil,
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         nil,
                                                preferredAdditionalSelector: nil,
                                                canFileReport:               true,
                                                extraInfo:                   "No User identifiers, but no error either.",
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)

                report("No User identifiers, but no error either.", errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
        }
    }

    func tryToJoin(teamWithCode: String)
    {
        guard currentUser != nil else
        { report("No «currentUser»!", errorCode: nil, isFatal: true, metadata: [#file, #function, #line]); return }

        TeamSerializer().getTeam(byJoinCode: teamWithCode) { returnedIdentifier, errorDescriptor in
            if let identifier = returnedIdentifier
            {
                TeamSerializer().addUser(currentUser.associatedIdentifier, toTeam: identifier) { errorDescriptor in
                    if let error = errorDescriptor
                    {
                        AlertKit().errorAlertController(title:                       nil,
                                                        message:                     error,
                                                        dismissButtonTitle:          "OK",
                                                        additionalSelectors:         ["Try Again": #selector(SignInController.presentJoinCodeAlert)],
                                                        preferredAdditionalSelector: 0,
                                                        canFileReport:               true,
                                                        extraInfo:                   nil,
                                                        metadata:                    [#file, #function, #line],
                                                        networkDependent:            false)

                        report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
                    }
                    else
                    {
                        flashSuccessHUD(text: "Successfully added to team.", for: 1, delay: nil) { self.signInButton(self.signInButton as Any) }
                    }
                }
            }
            else if let error = errorDescriptor
            {
                AlertKit().errorAlertController(title:                       nil,
                                                message:                     error,
                                                dismissButtonTitle:          "OK",
                                                additionalSelectors:         ["Try Again": #selector(SignInController.presentJoinCodeAlert)],
                                                preferredAdditionalSelector: 0,
                                                canFileReport:               true,
                                                extraInfo:                   nil,
                                                metadata:                    [#file, #function, #line],
                                                networkDependent:            false)

                report(error, errorCode: nil, isFatal: false, metadata: [#file, #function, #line])
            }
        }
    }
}

//==================================================//

/* MARK: Extensions */

/**/

/* MARK: UITextFieldDelegate */
extension SignInController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField.tag == aTagFor("usernameTextField")
        {
            passwordTextField.becomeFirstResponder()
        }
        else { passwordTextField.resignFirstResponder() }

        return true
    }
}

//--------------------------------------------------//

/* MARK: UITextField */
extension UITextField
{
    func addGreyUnderline()
    {
        let bottomLine = CALayer()

        bottomLine.frame = CGRect(x: 0, y: frame.size.height - 1, width: frame.size.width, height: 2)
        bottomLine.backgroundColor = UIColor(hex: 0xB0B0B0).cgColor

        borderStyle = .none

        layer.addSublayer(bottomLine)
    }
}
