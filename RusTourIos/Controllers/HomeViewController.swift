//
//  HomeViewController.swift
//  TravelApp
//
//  Created by seif on 03/02/2025.
//

import UIKit

// MARK: - Tour Model
struct Tour {
    let image: UIImage?
    let title: String
    let price: Double
}

// MARK: - Recommended Tour Cell
class RecommendedTourCell: UICollectionViewCell {
    static let identifier = "RecommendedTourCell"
    
    private let tourImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGreen
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(tourImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(priceLabel)
        
        tourImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tourImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tourImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tourImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tourImageView.heightAnchor.constraint(equalTo: tourImageView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: tourImageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with tour: Tour) {
        tourImageView.image = tour.image ?? UIImage(systemName: "photo")
        titleLabel.text = tour.title
        priceLabel.text = "From $\(tour.price)"
    }
}

// MARK: - Home View Controller
class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Search Container (Card-Like View)
    private let searchContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 10
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private let checkInDateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Check-in Date", for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }()
    
    private let checkOutDateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Check-out Date", for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }()
    
    private let adultsLabel: UILabel = {
        let label = UILabel()
        label.text = "Adults: 1"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private let adultsStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 1
        stepper.maximumValue = 10
        stepper.value = 1
        return stepper
    }()
    
    private let childrenLabel: UILabel = {
        let label = UILabel()
        label.text = "Children: 0"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private let childrenStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 0
        stepper.maximumValue = 10
        stepper.value = 0
        return stepper
    }()
    
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Search", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        return button
    }()
    
    // Recommended Tours Section
    private let recommendedToursLabel: UILabel = {
        let label = UILabel()
        label.text = "Recommended Tours"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    
    private var recommendedToursCollectionView: UICollectionView!
    
    // Data source for tours
    private var tours: [Tour] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Add targets
        adultsStepper.addTarget(self, action: #selector(adultsStepperChanged(_:)), for: .valueChanged)
        childrenStepper.addTarget(self, action: #selector(childrenStepperChanged(_:)), for: .valueChanged)
        checkInDateButton.addTarget(self, action: #selector(selectCheckInDate), for: .touchUpInside)
        checkOutDateButton.addTarget(self, action: #selector(selectCheckOutDate), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        
        setupCollectionView()
        setupLayout()
        loadDummyTours()
    }
    
    // MARK: - Setup Methods
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 150, height: 220)
        recommendedToursCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        recommendedToursCollectionView.backgroundColor = .clear
        recommendedToursCollectionView.dataSource = self
        recommendedToursCollectionView.delegate = self
        recommendedToursCollectionView.showsHorizontalScrollIndicator = false
        recommendedToursCollectionView.register(RecommendedTourCell.self, forCellWithReuseIdentifier: RecommendedTourCell.identifier)
    }
    
    private func setupLayout() {
        // Add scroll view and content view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Main stack view to hold search container and recommended tours
        let mainStackView = UIStackView(arrangedSubviews: [searchContainerView, recommendedToursLabel, recommendedToursCollectionView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStackView)
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Set up subviews inside the search container
        setupSearchContainer()
        
        // Set a fixed height for the collection view
        recommendedToursCollectionView.heightAnchor.constraint(equalToConstant: 240).isActive = true
    }
    
    private func setupSearchContainer() {
        // Date buttons arranged horizontally
        let dateStackView = UIStackView(arrangedSubviews: [checkInDateButton, checkOutDateButton])
        dateStackView.axis = .horizontal
        dateStackView.spacing = 10
        dateStackView.distribution = .fillEqually
        
        // Adults row: label and stepper
        let adultsStackView = UIStackView(arrangedSubviews: [adultsLabel, adultsStepper])
        adultsStackView.axis = .horizontal
        adultsStackView.spacing = 10
        adultsStackView.alignment = .center
        
        // Children row: label and stepper
        let childrenStackView = UIStackView(arrangedSubviews: [childrenLabel, childrenStepper])
        childrenStackView.axis = .horizontal
        childrenStackView.spacing = 10
        childrenStackView.alignment = .center
        
        // Group guest rows vertically
        let guestsStackView = UIStackView(arrangedSubviews: [adultsStackView, childrenStackView])
        guestsStackView.axis = .vertical
        guestsStackView.spacing = 10
        
        // Main vertical stack inside search container (date selectors, guest selectors, and search button)
        let searchStackView = UIStackView(arrangedSubviews: [dateStackView, guestsStackView, searchButton])
        searchStackView.axis = .vertical
        searchStackView.spacing = 15
        searchStackView.translatesAutoresizingMaskIntoConstraints = false
        
        searchContainerView.addSubview(searchStackView)
        NSLayoutConstraint.activate([
            searchStackView.topAnchor.constraint(equalTo: searchContainerView.topAnchor, constant: 15),
            searchStackView.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor, constant: 15),
            searchStackView.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor, constant: -15),
            searchStackView.bottomAnchor.constraint(equalTo: searchContainerView.bottomAnchor, constant: -15)
        ])
    }
    
    private func loadDummyTours() {
        // Dummy data for recommended tours (replace with your own data)
        tours = [
            Tour(image: UIImage(systemName: "photo"), title: "City Tour", price: 99),
            Tour(image: UIImage(systemName: "photo"), title: "Historical Walk", price: 129),
            Tour(image: UIImage(systemName: "photo"), title: "Adventure Trip", price: 199),
            Tour(image: UIImage(systemName: "photo"), title: "Beach Getaway", price: 159)
        ]
        recommendedToursCollectionView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func selectCheckInDate() {
        presentDatePicker { [weak self] date in
            guard let self = self else { return }
            self.checkInDateButton.setTitle("Check-in: \(self.formatDate(date))", for: .normal)
        }
    }
    
    @objc private func selectCheckOutDate() {
        presentDatePicker { [weak self] date in
            guard let self = self else { return }
            self.checkOutDateButton.setTitle("Check-out: \(self.formatDate(date))", for: .normal)
        }
    }
    
    private func presentDatePicker(completion: @escaping (Date) -> Void) {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        
        let alert = UIAlertController(title: "Select Date", message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 20),
            datePicker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 20),
            datePicker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -20),
            datePicker.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -60)
        ])
        
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
            completion(datePicker.date)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    @objc private func adultsStepperChanged(_ sender: UIStepper) {
        adultsLabel.text = "Adults: \(Int(sender.value))"
    }
    
    @objc private func childrenStepperChanged(_ sender: UIStepper) {
        childrenLabel.text = "Children: \(Int(sender.value))"
    }
    
    @objc private func searchButtonTapped() {
        // Implement your search logic here.
        let checkInText = checkInDateButton.title(for: .normal) ?? "Not set"
        let checkOutText = checkOutDateButton.title(for: .normal) ?? "Not set"
        let adults = Int(adultsStepper.value)
        let children = Int(childrenStepper.value)
        print("Search initiated with: \(checkInText), \(checkOutText), Adults: \(adults), Children: \(children)")
    }
    
    // MARK: - UICollectionView DataSource & Delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tours.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecommendedTourCell.identifier, for: indexPath) as? RecommendedTourCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: tours[indexPath.item])
        return cell
    }
    
    // Optional: Adjust inter-item spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}
