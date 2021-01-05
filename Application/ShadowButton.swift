//
//  ShadowButton.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import UIKit

class ShadowButton: UIButton
{
    //==================================================//

    /* MARK: Class-level Variable Declarations */

    //Booleans
    override var isEnabled:      Bool {
        didSet
        {
            layer.shadowColor     = isEnabled ? enabledShadowColor     : disabledShadowColor.cgColor
            layer.borderColor     = isEnabled ? enabledShadowColor     : disabledShadowColor.cgColor
            backgroundColor       = isEnabled ? enabledBackgroundColor : disabledBackgroundColor
        }
    }
    private var animateTouches:  Bool!

    //UIColors
    private var enabledBackgroundColor: UIColor!

    var disabledBackgroundColor = UIColor.gray
    var disabledShadowColor     = UIColor.darkGray

    //Other Declarations
    private var enabledShadowColor: CGColor!

    var fontSize: CGFloat!

    //==================================================//

    /* MARK: Class Declaration */

    class func buttonWithType(_ buttonType: UIButton.ButtonType?) -> AnyObject
    {
        let currentButton = buttonWithType(buttonType) as! ShadowButton

        return currentButton
    }

    //==================================================//

    /* MARK: Overridden Functions */

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)

        if animateTouches
        {
            layer.shadowOffset = CGSize(width: 0, height: 0)

            frame.origin.y = frame.origin.y + 3
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesEnded(touches, with: event)

        if animateTouches
        {
            layer.shadowOffset = CGSize(width: 0, height: 4)

            frame.origin.y = frame.origin.y - 3
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesMoved(touches, with: event)
    }

    //==================================================//

    /* MARK: Initializer Function */

    func initializeLayer(animateTouches:     Bool,
                         backgroundColor:   UIColor,
                         customBorderFrame _:  CGRect?,
                         customCornerRadius: CGFloat?,
                         shadowColor:       CGColor)
    {
        self.animateTouches = animateTouches

        enabledBackgroundColor = backgroundColor
        enabledShadowColor     = shadowColor

        self.backgroundColor = isEnabled ? enabledBackgroundColor : disabledBackgroundColor

        layer.borderColor   = isEnabled ? enabledShadowColor : disabledShadowColor.cgColor
        layer.borderWidth   = 2
        layer.cornerRadius  = customCornerRadius ?? 10
        layer.masksToBounds = false
        layer.shadowColor   = isEnabled ? enabledShadowColor : disabledShadowColor.cgColor
        layer.shadowOffset  = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 1
    }
}
