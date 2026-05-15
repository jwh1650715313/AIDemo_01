import UIKit
import SnapKit

// 聊天首页的主视图：背景、顶部标题、消息列表和底部输入栏都在这里组装。
final class ChatView: UIView {
    var onMenuTap: (() -> Void)?
    var onNewChatTap: (() -> Void)?

    let collectionView: UICollectionView
    let inputBar = ChatInputBar()

    private let backgroundView = GridBackgroundView()
    private let headerView = UIView()
    private let menuButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let titleStack = UIStackView()

    override init(frame: CGRect) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: ChatView.makeCollectionViewLayout())
        super.init(frame: frame)
        configureView()
        configureHeader()
        configureCollectionView()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        backgroundColor = UIColor(red: 0.01, green: 0.03, blue: 0.09, alpha: 1.0)
    }

    private func configureHeader() {
        titleLabel.text = "灵境 AI"
        titleLabel.font = .systemFont(ofSize: 27, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        subtitleLabel.text = "你的智能伙伴，随时为你答疑解惑"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.52)
        subtitleLabel.textAlignment = .center

        titleStack.axis = .vertical
        titleStack.alignment = .center
        titleStack.spacing = 6

        configureHeaderButton(menuButton, systemName: "line.3.horizontal")
        configureHeaderButton(addButton, systemName: "plus")
        menuButton.accessibilityLabel = "打开侧边栏"
        addButton.accessibilityLabel = "新建聊天"
        menuButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }

    private func configureHeaderButton(_ button: UIButton, systemName: String) {
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 0.05, green: 0.14, blue: 0.29, alpha: 0.58)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.20, green: 0.62, blue: 1.0, alpha: 0.36).cgColor
        button.layer.cornerRadius = 15
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 4, right: 0)
        collectionView.delaysContentTouches = false
    }

    private func setupLayout() {
        addSubview(backgroundView)
        addSubview(headerView)
        addSubview(collectionView)
        addSubview(inputBar)

        headerView.addSubview(menuButton)
        headerView.addSubview(addButton)
        headerView.addSubview(titleStack)
        [titleLabel, subtitleLabel].forEach(titleStack.addArrangedSubview)

        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(76)
        }

        menuButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalTo(titleStack)
            make.size.equalTo(44)
        }

        addButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(titleStack)
            make.size.equalTo(44)
        }

        titleStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(menuButton.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualTo(addButton.snp.leading).offset(-16)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputBar.snp.top).offset(-12)
        }

        inputBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(68)
            make.bottom.equalTo(keyboardLayoutGuide.snp.top).offset(-12).priority(999)
            make.bottom.lessThanOrEqualTo(safeAreaLayoutGuide.snp.bottom).offset(-12)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-12).priority(.low)
        }
    }

    private static func makeCollectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(96)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(96)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 6
        section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)

        return UICollectionViewCompositionalLayout(section: section)
    }

    @objc private func menuButtonTapped() {
        onMenuTap?()
    }

    @objc private func addButtonTapped() {
        onNewChatTap?()
    }
}
