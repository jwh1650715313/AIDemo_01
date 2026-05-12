import UIKit
import SnapKit

// 聊天机器人首页控制器：负责 UI 状态，真实回复由 ChatResponding 实现提供。
final class ChatViewController: UIViewController {
    private let onLogout: (() -> Void)?
    private let chatService: ChatResponding
    private let chatView = ChatView()
    private let dimmingView = UIView()
    private let sidebarView = ChatSidebarView()
    private var messages = ChatMessage.welcomeMessages
    private var conversationMessages: [ChatMessage] = []
    private var sendTask: Task<Void, Never>?
    private var previousNavigationBarHidden = true
    private var previousTabBarHidden = false
    private var isSidebarVisible = false

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    init(
        chatService: ChatResponding,
        onLogout: (() -> Void)? = nil
    ) {
        self.chatService = chatService
        self.onLogout = onLogout
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        sendTask?.cancel()
    }

    override func loadView() {
        view = chatView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        bindInputBar()
        bindSidebarActions()
        configureSidebar()
        configureKeyboardDismissGesture()

        DispatchQueue.main.async { [weak self] in
            self?.scrollToBottom(animated: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 页面旋转或首次布局后，隐藏态侧栏始终停在屏幕左侧外。
        if !isSidebarVisible {
            sidebarView.transform = hiddenSidebarTransform()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previousNavigationBarHidden = navigationController?.isNavigationBarHidden ?? true
        previousTabBarHidden = tabBarController?.tabBar.isHidden ?? false
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(previousNavigationBarHidden, animated: animated)
        tabBarController?.tabBar.isHidden = previousTabBarHidden
    }

    private func configureCollectionView() {
        chatView.collectionView.dataSource = self
        chatView.collectionView.register(
            AIMessageCell.self,
            forCellWithReuseIdentifier: AIMessageCell.reuseIdentifier
        )
        chatView.collectionView.register(
            UserMessageCell.self,
            forCellWithReuseIdentifier: UserMessageCell.reuseIdentifier
        )
        chatView.collectionView.register(
            TypingMessageCell.self,
            forCellWithReuseIdentifier: TypingMessageCell.reuseIdentifier
        )
    }

    private func bindInputBar() {
        chatView.inputBar.onSend = { [weak self] text in
            self?.sendUserMessage(text)
        }
    }

    private func bindSidebarActions() {
        chatView.onMenuTap = { [weak self] in
            self?.showSidebar()
        }

        chatView.onNewChatTap = { [weak self] in
            self?.startNewChat()
        }

        sidebarView.onNewChatTap = { [weak self] in
            self?.startNewChat()
        }
        sidebarView.onAllChatsTap = { [weak self] in
            self?.hideSidebar()
        }
        sidebarView.onSettingsTap = { [weak self] in
            self?.hideSidebar()
        }
        sidebarView.onLogoutTap = { [weak self] in
            self?.logoutFromSidebar()
        }
    }

    private func configureSidebar() {
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.56)
        dimmingView.alpha = 0
        dimmingView.isHidden = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped))
        dimmingView.addGestureRecognizer(tapGesture)

        view.addSubview(dimmingView)
        view.addSubview(sidebarView)

        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        sidebarView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.78)
        }

        sidebarView.transform = hiddenSidebarTransform()
    }

    private func configureKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        chatView.collectionView.addGestureRecognizer(tapGesture)
    }

    private func sendUserMessage(_ text: String) {
        guard sendTask == nil else { return }

        if messages.last?.isTyping == true {
            messages.removeLast()
        }

        let userMessage = ChatMessage(
            sender: .user,
            text: text,
            time: currentTimeString(),
            isRead: true
        )
        messages.append(userMessage)
        conversationMessages.append(userMessage)
        messages.append(
            ChatMessage(
                sender: .ai,
                content: .typing,
                time: currentTimeString()
            )
        )

        chatView.collectionView.reloadData()
        scrollToBottom(animated: true)
        chatView.inputBar.setSending(true)

        let requestMessages = conversationMessages
        let chatService = chatService
        sendTask = Task { [weak self, chatService] in
            do {
                let answer = try await chatService.reply(for: requestMessages)
                await MainActor.run {
                    self?.appendAIReply(answer)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.finishCurrentSend()
                }
            } catch {
                await MainActor.run {
                    self?.appendAIError(error)
                }
            }
        }
    }

    private func appendAIReply(_ text: String) {
        finishCurrentSend()

        let aiMessage = ChatMessage(
            sender: .ai,
            text: text,
            time: currentTimeString()
        )
        messages.append(aiMessage)
        conversationMessages.append(aiMessage)

        chatView.collectionView.reloadData()
        scrollToBottom(animated: true)
    }

    private func appendAIError(_ error: Error) {
        finishCurrentSend()

        messages.append(
            ChatMessage(
                sender: .ai,
                text: error.localizedDescription,
                time: currentTimeString()
            )
        )

        chatView.collectionView.reloadData()
        scrollToBottom(animated: true)
    }

    private func finishCurrentSend() {
        if messages.last?.isTyping == true {
            messages.removeLast()
        }

        sendTask = nil
        chatView.inputBar.setSending(false)
    }

    private func startNewChat() {
        sendTask?.cancel()
        sendTask = nil
        messages = ChatMessage.welcomeMessages
        conversationMessages = []
        chatView.inputBar.setSending(false)
        chatView.collectionView.reloadData()
        hideSidebar { [weak self] in
            self?.scrollToBottom(animated: false)
        }
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        chatView.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }

    private func showSidebar() {
        guard !isSidebarVisible else { return }

        dismissKeyboard()
        isSidebarVisible = true
        dimmingView.isHidden = false
        view.bringSubviewToFront(dimmingView)
        view.bringSubviewToFront(sidebarView)

        sidebarView.transform = hiddenSidebarTransform()

        // 遮罩和侧栏一起动画，形成从左侧滑入的轻量抽屉效果。
        UIView.animate(
            withDuration: 0.34,
            delay: 0,
            usingSpringWithDamping: 0.92,
            initialSpringVelocity: 0.20,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.dimmingView.alpha = 1
            self.sidebarView.transform = .identity
        }
    }

    private func hideSidebar(completion: (() -> Void)? = nil) {
        guard isSidebarVisible else {
            completion?()
            return
        }

        isSidebarVisible = false

        UIView.animate(
            withDuration: 0.26,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState]
        ) {
            self.dimmingView.alpha = 0
            self.sidebarView.transform = self.hiddenSidebarTransform()
        } completion: { _ in
            if !self.isSidebarVisible {
                self.dimmingView.isHidden = true
            }
            completion?()
        }
    }

    private func hiddenSidebarTransform() -> CGAffineTransform {
        CGAffineTransform(translationX: -view.bounds.width * 0.78, y: 0)
    }

    private func logoutFromSidebar() {
        hideSidebar { [weak self] in
            guard let self else { return }

            // 当前 App 有统一的退出登录回调时，交给 Coordinator 清登录态并回到登录页。
            if let onLogout {
                onLogout()
            } else {
                dismiss(animated: true)
            }
        }
    }

    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func dimmingViewTapped() {
        hideSidebar()
    }
}

extension ChatViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messages.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let message = messages[indexPath.item]

        if message.isTyping {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TypingMessageCell.reuseIdentifier,
                for: indexPath
            ) as? TypingMessageCell
            cell?.configure(with: message)
            return cell ?? UICollectionViewCell()
        }

        switch message.sender {
        case .ai:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: AIMessageCell.reuseIdentifier,
                for: indexPath
            ) as? AIMessageCell
            cell?.configure(with: message)
            return cell ?? UICollectionViewCell()
        case .user:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: UserMessageCell.reuseIdentifier,
                for: indexPath
            ) as? UserMessageCell
            cell?.configure(with: message)
            return cell ?? UICollectionViewCell()
        }
    }
}
