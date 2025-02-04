//
//  MainTabBarController.swift
//  TravelApp
//
//  Created by seif on 04/02/2025.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
    }

    private func setupTabBar() {
        let homeVC = UINavigationController(rootViewController: HomeViewController())
        let savedVC = UINavigationController(rootViewController: SavedViewController())
        let bookingsVC = UINavigationController(rootViewController: BookingsViewController())
        let profileVC = UINavigationController(rootViewController: ProfileViewController())

        homeVC.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 0)
        savedVC.tabBarItem = UITabBarItem(title: "Saved", image: UIImage(systemName: "heart"), tag: 1)
        bookingsVC.tabBarItem = UITabBarItem(title: "Bookings", image: UIImage(systemName: "bag"), tag: 2)
        profileVC.tabBarItem = UITabBarItem(title: "Sign In", image: UIImage(systemName: "person.circle"), tag: 3)

        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .systemBackground

        viewControllers = [homeVC, savedVC, bookingsVC, profileVC]
    }
}
