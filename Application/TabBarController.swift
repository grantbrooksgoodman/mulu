//
//  TabBarController.swift
//  Mulu Party
//
//  Created by Grant Brooks Goodman on 04/01/2021.
//  Copyright © 2013-2021 NEOTechnica Corporation. All rights reserved.
//

/* First-party Frameworks */
import MessageUI
import UIKit

class TabBarController: UITabBarController
{
    //==================================================//

    /* MARK: Overridden Functions */

    override func viewDidLoad()
    {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        selectedIndex = 1
    }

    override func prepare(for _: UIStoryboardSegue, sender _: Any?)
    {}
}
