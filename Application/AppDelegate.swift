//
//  AppDelegate.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 04/12/2020.
//  Copyright © 2013-2020 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

/* Third-party Frameworks */
import Firebase
import FirebaseStorage
import PKHUD
import Reachability

//==================================================//

/* MARK: Top-level Variable Declarations */

//Booleans
var darkMode                              = false
var isPresentingMailComposeViewController = false
var preReleaseApplication                 = true
var verboseFunctionExposure               = false

//DateFormatters
let masterDateFormatter    = DateFormatter()
let secondaryDateFormatter = DateFormatter()

//Strings
var codeName                  = "Mulu"
var currentFile               = #file
var dmyFirstCompileDateString = "04122020"
var finalName                 = "Mulu Party"
var generatedJoinCode: String?
var pushToken:         String?

//UIViewControllers
var buildInfoController: BuildInfoController?
var lastInitialisedController: UIViewController! = MainController()

//Other Declarations
var appStoreReleaseVersion = 0
var buildType: Build.BuildType = .alpha
var currentTeam: Team!
var currentUser: User!
var dataStorage: StorageReference!
var informationDictionary: [String:String]!
var touchTimer: Timer?

//==================================================//

@UIApplicationMain class AppDelegate: UIResponder, MessagingDelegate, MFMailComposeViewControllerDelegate, UIApplicationDelegate, UIGestureRecognizerDelegate, UNUserNotificationCenterDelegate
{
    //==================================================//
    
    /* MARK: Class-level Variable Declarations */
    
    //Boolean Declarations
    var currentlyAnimating = false
    var hasResigned        = false
    
    //Other Declarations
    let screenSize = UIScreen.main.bounds
    
    var informationDictionary: [String:String] = [:]
    var restrictRotation: UIInterfaceOrientationMask = .portrait
    var window: UIWindow?
    
    //==================================================//
    
    /* MARK: Required Functions */
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        let tapGesture = UITapGestureRecognizer(target: self, action: nil)
        tapGesture.delegate = self
        window?.addGestureRecognizer(tapGesture)
        
        masterDateFormatter.dateFormat = "yyyy-MM-dd"
        masterDateFormatter.locale = Locale(identifier: "en_GB")
        
        secondaryDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        secondaryDateFormatter.locale = Locale(identifier: "en_GB")
        
        //Set the array of information.
        Build(nil)
        
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
        
        dataStorage = Storage.storage().reference()
        
        if #available(iOS 10.0, *)
        {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
        }
        else
        {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
    {
        return self.restrictRotation
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        if currentlyAnimating && hasResigned
        {
            lastInitialisedController.performSegue(withIdentifier: "initialSegue", sender: self)
            currentlyAnimating = false
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
        
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        hasResigned = true
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        
    }
    
    //==================================================//
    
    /* MARK: Other Functions */
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        touchTimer?.invalidate()
        touchTimer = nil
        
        UIView.animate(withDuration: 0.2, animations: { buildInfoController?.view.alpha = 0.35 }) { (_) in
            if touchTimer == nil
            {
                touchTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.touchTimerAction), userInfo: nil, repeats: true)
            }
        }
        
        return false
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String)
    {
        //        let dataDict: [String:String] = ["token": fcmToken]
        //        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        
        pushToken = fcmToken
    }
    
    @objc func touchTimerAction()
    {
        UIView.animate(withDuration: 0.2, animations: {
            if touchTimer != nil
            {
                buildInfoController?.view.alpha = 1
                
                touchTimer?.invalidate()
                touchTimer = nil
            }
        })
    }
}

//==================================================//

/* MARK: Helper Functions */

/**/

/* MARK: Error Processing Functions */
/**
 Converts an instance of `Error` to a formatted string.
 
 - Parameter for: The `Error` whose information will be extracted.
 
 - Returns: A string with the error's localised description and code.
 */
func errorInfo(_ for: Error) -> String
{
    let asNSError = `for` as NSError
    
    return "\(asNSError.localizedDescription) (\(asNSError.code))"
}

/**
 Converts an instance of `NSError` to a formatted string.
 
 - Parameter for: The `NSError` whose information will be extracted.
 
 - Returns: A string with the error's localised description and code.
 */
func errorInfo(_ for: NSError) -> String
{
    return "\(`for`.localizedDescription) (\(`for`.code))"
}

//--------------------------------------------------//

/* MARK: Event Reporting Functions */

///Closes a console stream.
func closeStream(onLine: Int?, withMessage: String?)
{
    if verboseFunctionExposure
    {
        if let closingMessage = withMessage, let lastLine = onLine
        {
            print("[\(lastLine)]: \(closingMessage)\n*------------------------STREAM CLOSED------------------------*\n")
        }
        else { print("*------------------------STREAM CLOSED------------------------*\n") }
    }
}

func fallbackReport(_ text: String, errorCode: Int?, isFatal: Bool)
{
    if let unwrappedErrorCode = errorCode
    {
        print("\n--------------------------------------------------\n[IMPROPERLY FORMATTED METADATA]\n\(text) (\(unwrappedErrorCode))\n--------------------------------------------------\n")
    }
    else { print("\n--------------------------------------------------\n[IMPROPERLY FORMATTED METADATA]\n\(text)\n--------------------------------------------------\n") }
    
    if isFatal
    {
        AlertKit().fatalErrorController()
    }
}

///Logs to the console stream.
func logToStream(forLine: Int, withMessage: String)
{
    if verboseFunctionExposure
    {
        print("[\(forLine)]: \(withMessage)")
    }
}

///Opens a console stream.
func openStream(forFile: String, forFunction: String, forLine: Int?, withMessage: String?)
{
    if verboseFunctionExposure
    {
        let functionTitle = forFunction.components(separatedBy: "(")[0]
        
        if let firstEntry = withMessage
        {
            print("\n*------------------------STREAM OPENED------------------------*\n\(AlertKit().retrieveFileName(forFile: forFile)): \(functionTitle)()\n[\(forLine!)]: \(firstEntry)")
        }
        else
        { print("\n*------------------------STREAM OPENED------------------------*\n\(AlertKit().retrieveFileName(forFile: forFile)): \(functionTitle)()") }
    }
}

/**
 Prints a formatted event report to the console. Also supports displaying a fatal error alert.
 
 - Parameter text: The content of the message to print.
 - Parameter errorCode: An optional error code to include in the report.
 
 - Parameter isFatal: A Boolean representing whether or not to display a fatal error alert along with the event report.
 - Parameter metadata: The metadata Array. Must contain the **file name, function name, and line number** in that order.
 */
func report(_ text: String, errorCode: Int?, isFatal: Bool, metadata: [Any])
{
    guard validateMetadata(metadata) else
    { fallbackReport(text, errorCode: errorCode, isFatal: isFatal); return }
    
    let unformattedFileName = metadata[0] as! String
    let unformattedFunctionName = metadata[1] as! String
    let lineNumber = metadata[2] as! Int
    
    let fileName = AlertKit().retrieveFileName(forFile: unformattedFileName)
    let functionName = unformattedFunctionName.components(separatedBy: "(")[0]
    
    if let unwrappedErrorCode = errorCode
    {
        print("\n--------------------------------------------------\n\(fileName): \(functionName)() [\(lineNumber)]\n\(text) (\(unwrappedErrorCode))\n--------------------------------------------------\n")
        
        if isFatal
        {
            AlertKit().fatalErrorController(extraInfo: "\(text) (\(unwrappedErrorCode))", metadata: [fileName, functionName, lineNumber])
        }
    }
    else
    {
        print("\n--------------------------------------------------\n\(fileName): \(functionName)() [\(lineNumber)]\n\(text)\n--------------------------------------------------\n")
        
        if isFatal
        {
            AlertKit().fatalErrorController(extraInfo: text, metadata: [fileName, functionName, lineNumber])
        }
    }
}

func validateMetadata(_ metadata: [Any]) -> Bool
{
    guard metadata.count == 3 else
    { return false }
    
    guard metadata[0] is String else
    { return false }
    
    guard metadata[1] is String else
    { return false }
    
    guard metadata[2] is Int else
    { return false }
    
    return true
}

//--------------------------------------------------//

/* MARK: First Responder Functions */

///Finds and resigns the first responder.
func findAndResignFirstResponder()
{
    DispatchQueue.main.async {
        if let unwrappedFirstResponder = findFirstResponder(inView: lastInitialisedController.view)
        {
            unwrappedFirstResponder.resignFirstResponder()
        }
    }
}

///Finds the first responder in a given view.
func findFirstResponder(inView view: UIView) -> UIView?
{
    for individualSubview in view.subviews
    {
        if individualSubview.isFirstResponder
        {
            return individualSubview
        }
        
        if let recursiveSubview = findFirstResponder(inView: individualSubview)
        {
            return recursiveSubview
        }
    }
    
    return nil
}

//--------------------------------------------------//

/* MARK: HUD Functions */

///Hides the HUD.
func hideHUD()
{
    DispatchQueue.main.async {
        if PKHUD.sharedHUD.isVisible
        {
            PKHUD.sharedHUD.hide(true)
        }
    }
}

func hideHUD(delay: Double?)
{
    if let delay = delay
    {
        let millisecondDelay = Int(delay * 1000)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(millisecondDelay)) {
            if PKHUD.sharedHUD.isVisible
            {
                PKHUD.sharedHUD.hide(true)
            }
        }
    }
    else
    {
        DispatchQueue.main.async {
            if PKHUD.sharedHUD.isVisible
            {
                PKHUD.sharedHUD.hide(true)
            }
        }
    }
}

func hideHUD(delay: Double?, completion: @escaping() -> Void)
{
    if let delay = delay
    {
        let millisecondDelay = Int(delay * 1000)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(millisecondDelay)) {
            if PKHUD.sharedHUD.isVisible
            {
                PKHUD.sharedHUD.hide(animated: true) { (_) in
                    completion()
                }
            }
        }
    }
    else
    {
        DispatchQueue.main.async {
            if PKHUD.sharedHUD.isVisible
            {
                PKHUD.sharedHUD.hide(true) { (_) in
                    completion()
                }
            }
        }
    }
}

func flashSuccessHUD(text: String?, for: Double, delay: Double?, completion: @escaping() -> Void)
{
    if let delay = delay
    {
        let millisecondDelay = Int(delay * 1000)
        
        if !PKHUD.sharedHUD.isVisible
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(millisecondDelay)) {
                PKHUD.sharedHUD.contentView = PKHUDSuccessView(title: nil, subtitle: text)
                PKHUD.sharedHUD.show(onView: lastInitialisedController.view)
            }
        }
    }
    else
    {
        if !PKHUD.sharedHUD.isVisible
        {
            PKHUD.sharedHUD.contentView = PKHUDSuccessView(title: nil, subtitle: text)
            PKHUD.sharedHUD.show(onView: lastInitialisedController.view)
        }
    }
    
    let flashTime = Int(`for` * 1000)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(flashTime)) {
        hideHUD(delay: 0) {
            completion()
        }
    }
}

///Shows the progress HUD.
func showProgressHUD()
{
    DispatchQueue.main.async {
        if !PKHUD.sharedHUD.isVisible
        {
            PKHUD.sharedHUD.contentView = PKHUDProgressView()
            PKHUD.sharedHUD.show(onView: lastInitialisedController.view)
        }
    }
}

func showProgressHUD(text: String?, delay: Double?)
{
    if let delay = delay
    {
        let millisecondDelay = Int(delay * 1000)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(millisecondDelay)) {
            if !PKHUD.sharedHUD.isVisible
            {
                PKHUD.sharedHUD.contentView = PKHUDProgressView(title: nil, subtitle: text)
                PKHUD.sharedHUD.show(onView: lastInitialisedController.view)
            }
        }
    }
    else
    {
        DispatchQueue.main.async {
            if !PKHUD.sharedHUD.isVisible
            {
                PKHUD.sharedHUD.contentView = PKHUDProgressView(title: nil, subtitle: text)
                PKHUD.sharedHUD.show(onView: lastInitialisedController.view)
            }
        }
    }
}

func showSuccessHUD(text: String?, delay: Double?)
{
    if let delay = delay
    {
        let millisecondDelay = Int(delay * 1000)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(millisecondDelay)) {
            if !PKHUD.sharedHUD.isVisible
            {
                PKHUD.sharedHUD.contentView = PKHUDSuccessView(title: nil, subtitle: text)
                PKHUD.sharedHUD.show(onView: lastInitialisedController.view)
            }
        }
    }
    else
    {
        DispatchQueue.main.async {
            if !PKHUD.sharedHUD.isVisible
            {
                PKHUD.sharedHUD.contentView = PKHUDSuccessView(title: nil, subtitle: text)
                PKHUD.sharedHUD.show(onView: lastInitialisedController.view)
            }
        }
    }
}

//--------------------------------------------------//

/* MARK: Miscellaneous Functions */

///Retrieves the appropriately random tag integer for a given title.
func aTagFor(_ theViewNamed: String) -> Int
{
    var finalValue: Float = 1.0
    
    for individualCharacter in String(theViewNamed.unicodeScalars.filter(CharacterSet.letters.contains)).stringCharacters
    {
        finalValue += (finalValue / Float(individualCharacter.alphabeticalPosition))
    }
    
    return Int(String(finalValue).replacingOccurrences(of: ".", with: "")) ?? Int().random(min: 5, max: 10)
}

func buildTypeAsString(short: Bool) -> String
{
    switch buildType
    {
    case .preAlpha:
        return short ? "p" : "pre-alpha"
    case .alpha:
        return short ? "a" : "alpha"
    case .beta:
        return short ? "b" : "beta"
    case .releaseCandidate:
        return short ? "c" : "release candidate"
    default:
        return short ? "g" : "general"
    }
}

///Presents a mail composition view.
func composeMessage(withMessage: String, withRecipients: [String], withSubject: String, isHtmlMessage: Bool)
{
    hideHUD(delay: nil)
    
    if MFMailComposeViewController.canSendMail()
    {
        let composeController = MFMailComposeViewController()
        composeController.mailComposeDelegate = lastInitialisedController as! MFMailComposeViewControllerDelegate?
        composeController.setToRecipients(withRecipients)
        composeController.setMessageBody(withMessage, isHTML: isHtmlMessage)
        composeController.setSubject(withSubject)
        
        politelyPresent(viewController: composeController)
    }
    else
    {
        AlertKit().errorAlertController(title: "Cannot Send Mail", message: "It appears that your device is not able to send e-mail.\n\nPlease verify that your e-mail client is set up and try again.", dismissButtonTitle: nil, additionalSelectors: nil, preferredAdditionalSelector: nil, canFileReport: false, extraInfo: nil, metadata: [#file, #function, #line], networkDependent: true)
    }
}

///Returns a boolean describing whether or not the device has an active Internet connection.
func hasConnectivity() -> Bool
{
    let connectionReachability = try! Reachability()
    let networkStatus = connectionReachability.connection.description
    
    return (networkStatus != "No Connection")
}

func notifyAllUsers(title: String, body: String, completion: @escaping(_ errorDescriptor: String?) -> Void)
{
    UserSerialiser().getAllUsers { (returnedUsers, errorDescriptor) in
        if let users = returnedUsers
        {
            var errors: [String] = []
            
            for (index, user) in users.enumerated()
            {
                if let pushTokens = user.pushTokens
                {
                    for token in pushTokens
                    {
                        pushNotification(to: token, title: title, body: body) { (errorDescriptor) in
                            if let error = errorDescriptor
                            {
                                errors.append(error)
                                
                                if index == users.count - 1
                                {
                                    completion(errors.joined(separator: "\n"))
                                }
                            }
                            else
                            {
                                if index == users.count - 1
                                {
                                    completion(errors.count == 0 ? nil : errors.joined(separator: "\n"))
                                }
                            }
                        }
                    }
                }
                else if index == users.count - 1
                {
                    completion(errors.count == 0 ? nil : errors.joined(separator: "\n"))
                }
            }
        }
        else { completion(errorDescriptor!) }
    }
}

///Presents a given view controller, but waits for others to be dismissed before doing so.
func politelyPresent(viewController: UIViewController)
{
    hideHUD(delay: nil)
    
    if viewController as? MFMailComposeViewController != nil
    {
        isPresentingMailComposeViewController = true
    }
    
    let keyWindow = UIApplication.shared.windows.filter{$0.isKeyWindow}.first
    
    if var topController = keyWindow?.rootViewController
    {
        while let presentedViewController = topController.presentedViewController
        {
            topController = presentedViewController
        }
        
        if topController.presentedViewController == nil && !topController.isKind(of: UIAlertController.self)
        {
            #warning("Something changed in iOS 14 that broke the above code.")
            topController = lastInitialisedController
            
            if !Thread.isMainThread
            {
                DispatchQueue.main.sync { topController.present(viewController, animated: true) }
            }
            else { topController.present(viewController, animated: true) }
        }
        else
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: { politelyPresent(viewController: viewController) })
        }
    }
}

func pushNotification(to token: String, title: String, body: String, completion: @escaping(_ errorDescriptor: String?) -> Void)
{
    let messagingKey = "ADD ME BACK POST-COMMIT"
    
    let jsonParameters: [String:Any] = ["to":           token,
                                        "notification": ["title": title, "body": body],
                                        "data":         ["user": "test_id"]]
    
    let urlRequest = NSMutableURLRequest(url: URL(string: "https://fcm.googleapis.com/fcm/send")!)
    
    urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: jsonParameters, options: [.prettyPrinted])
    urlRequest.httpMethod = "POST"
    
    urlRequest.setValue("application/json",    forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("key=\(messagingKey)", forHTTPHeaderField: "Authorization")
    
    let dataTask = URLSession.shared.dataTask(with: urlRequest as URLRequest)  { (returnedData, returnedResponse, returnedError) in
        do {
            if let error = returnedError
            {
                completion(errorInfo(error))
            }
            else { completion(nil) }
        }
    }
    
    dataTask.resume()
}

///Rounds the corners on any desired view.
///Numbers 0 through 4 correspond to all, left, right, top, and bottom, respectively.
func roundCorners(forViews: [UIView], withCornerType: Int!)
{
    for individualView in forViews
    {
        var cornersToRound: UIRectCorner!
        
        if withCornerType == 0
        {
            //All corners.
            cornersToRound = UIRectCorner.allCorners
        }
        else if withCornerType == 1
        {
            //Left corners.
            cornersToRound = UIRectCorner.topLeft.union(UIRectCorner.bottomLeft)
        }
        else if withCornerType == 2
        {
            //Right corners.
            cornersToRound = UIRectCorner.topRight.union(UIRectCorner.bottomRight)
        }
        else if withCornerType == 3
        {
            //Top corners.
            cornersToRound = UIRectCorner.topLeft.union(UIRectCorner.topRight)
        }
        else if withCornerType == 4
        {
            //Bottom corners.
            cornersToRound = UIRectCorner.bottomLeft.union(UIRectCorner.bottomRight)
        }
        
        let maskPathForView: UIBezierPath = UIBezierPath(roundedRect: individualView.bounds,
                                                         byRoundingCorners: cornersToRound,
                                                         cornerRadii: CGSize(width: 10, height: 10))
        
        let maskLayerForView: CAShapeLayer = CAShapeLayer()
        
        maskLayerForView.frame = individualView.bounds
        maskLayerForView.path = maskPathForView.cgPath
        
        individualView.layer.mask = maskLayerForView
        individualView.layer.masksToBounds = false
        individualView.clipsToBounds = true
    }
}
