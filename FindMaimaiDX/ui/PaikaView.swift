import SwiftUI
import AVFoundation

struct PaikaView: View {
    @State private var nfcMessage: String = "等待 NFC 数据..." // 存储 NFC 数据
    @State private var players: [Player] = [] // 存储玩家数据
    
    @State private var isLoading: Bool = false // 加载状态
    @State private var isFetching: Bool = false // 是否正在循环请求
    @State private var fetchTimer: Timer? // 定时器引用
    @State private var alertIsPresented: Bool = false // 是否显示弹窗
    @State private var manualPartyInput: String = "" // 用户手动输入的 party 值
    @State private var isInputSheetPresented: Bool = false // 是否显示输入弹窗
    @State private var showToast: Bool = false // 是否显示 Toast
    @State private var toastMessage: String = "" // Toast 消息内容
    @State private var username:String = ""
    @State private var avaterUrl:String = "0"
    @State private var isLargePopupPresented: Bool = false // 是否显示大弹窗
    @State private var party:String = ""
    @State private var scannedCode: String = "" // 保存扫描结果
    @State private var isShowingScanner: Bool = false // 控制扫描界面显示
    
    @State private var hasJoinedQueue: Bool = false
    @State private var lastJoinedParty: String = ""
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Toolbar 显示 NFC 数据
                ToolbarView(title: nfcMessage)
                    .padding(.bottom, 8)

                // 水平布局包含两个卡片
                HStack(spacing: 16) {
                    if players.count > 0 {
                        PlayerCard(imageURL: players[0].avatarURL, playerName: players[0].name)
                    } else {
                        PlayerCard(imageName: "person.circle", playerName: "Player 1")
                    }
                    if players.count > 1 {
                        PlayerCard(imageURL: players[1].avatarURL, playerName: players[1].name)
                    } else {
                        PlayerCard(imageName: "person.circle", playerName: "Player 2")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // ScrollView 包含边框
                ScrollView {
                    CardView {
                        VStack(spacing: 8) {
                            ForEach(players.dropFirst(2), id: \.self) { player in
                                HStack {
                                    AsyncImage(url: URL(string: player.avatarURL)) { image in
                                        image.resizable()
                                            .scaledToFit()
                                            .frame(width: 48, height: 48)
                                            .foregroundColor(.blue)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    Text(player.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(8)
                            }
                        }
                    }
                }
            
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .layoutPriority(1)
                
                Spacer() // 确保内容靠上
                
                if showToast {
                                Text(toastMessage)
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .transition(.opacity) // 添加淡入淡出效果
                                    .animation(.easeInOut(duration: 0.3), value: showToast)
                                    .onAppear {
                                        // 自动隐藏 Toast
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            withAnimation {
                                                showToast = false
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                                    .offset(y: -50) // 稍微向上偏移
                            }
                // 大弹窗视图

            }
            if isLargePopupPresented {
                LargePopupView(
                    isPresented: $isLargePopupPresented,
                    shangJiAction: {  // 传入上机操作的闭包
                        self.shangJi()
                    }
                )
            }
            
            // 右下角的悬浮按钮组
            VStack(spacing: 16) {
                // 修改扫码按钮的 action
                FloatingActionButton(iconName: "qrcode.viewfinder", color: .green, label: "扫码") {
                    self.isShowingScanner = true // 直接控制扫描器显示
                }
                FloatingActionButton(iconName: "door.right.hand.open", color: .red, label: "退卡") {
                    if isFetching {
                        stopFetchingPartyData()
                        exitParty()
                    } else {
                        if nfcMessage.contains("NFC 数据:") {
                            let party = nfcMessage.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                            startFetchingPartyData()
                        } else {
                            alertIsPresented = true
                        }
                    }
                }
                FloatingActionButton(iconName: "figure.run", color: .yellow, label: "上机") {
                    if isFetching {
                        isLargePopupPresented = true
                    }
                }
                FloatingActionButton(iconName: "list.bullet.rectangle.portrait", color: .blue, label: "排卡") {
                    if nfcMessage.contains("NFC 数据:") {
                        // 使用 NFC 数据中的参数
                        let party = nfcMessage.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                        startFetchingPartyData()
                        join()
                    } else {
                        // 显示输入弹窗
                        isInputSheetPresented = true
                        
                    }
                }

            }


            // 修改 QRScannerView 的使用方式
            .sheet(isPresented: $isShowingScanner) {
                QRScannerView { result in
                    // 处理扫描结果
                    self.handleScannedCode(result)
                    self.isShowingScanner = false
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 128)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .onAppear() {
            loadUsername()
            checkQueueStatus() // 检查排卡状态
        }
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.all)
        .onOpenURL { url in
            handleNFCURL(url: url) // 处理 NFC URL
        }
        .onTapGesture {
            // 点击背景关闭弹窗
            isLargePopupPresented = false
        }
        .sheet(isPresented: $isInputSheetPresented) {
                VStack(spacing: 16) {
                    Text("请输入 Party 和用户名")
                                    .font(.headline)
                                    .padding()

                    // Party 输入框
                    TextField("Party 参数", text: $party)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    // 用户名输入框
                    TextField("用户名", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    HStack {
                        // 取消按钮
                        Button("取消") {
                            isInputSheetPresented = false // 关闭弹窗
                        }
                        .frame(maxWidth: .infinity)

                        // 确认按钮
                        Button("确认") {
                            if !party.isEmpty && !username.isEmpty {
                                print("确认输入：Party = \(party), 用户名 = \(username)")
                            } else {
                                print("请填写所有字段")
                            }
                            isInputSheetPresented = false // 关闭弹窗
                            startFetchingPartyData()
                            saveUsername()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                join()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 8)
            }
    }
    // 检查排卡状态
    private func checkQueueStatus() {
        if let savedParty = UserDefaults.standard.string(forKey: "lastJoinedParty_\(username)") {
            lastJoinedParty = savedParty
            hasJoinedQueue = UserDefaults.standard.bool(forKey: "hasJoinedQueue_\(username)")
            
            if hasJoinedQueue {
                // 如果之前已经加入队列，自动加载该队列
                party = lastJoinedParty
                nfcMessage = "已加入队列: \(party)"
                startFetchingPartyData()
                showToastMessage(message: "已自动恢复排卡状态")
            }
        }
    }
        
    private func checkIsShangJi() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("延迟 2 秒后执行的代码")
            for index in players.indices {
                let player = players[index]
                // 检查是否已经加入房间
                if index == 2 {
                    if player.name == username {
                        // 处理第 3 位玩家
                        play()
                    }
                } else if index == 3 {
                    if player.name == username {
                        // 处理第 4 位玩家
                        changeToAndPlay()
                    }
                }
            }
        }
    }
    private func startFetchingPartyData() {
        guard !isFetching, fetchTimer == nil else { return } // 防止重复启动
        isFetching = true
        
        // 启动定时器
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            print("定时器触发，当前 isFetching 状态：\(self.isFetching)")
            self.fetchPartyData(party: party)
            
            if !self.isFetching {
                print("定时器已停止")
                timer.invalidate()
            }
        }
    }

    private func stopFetchingPartyData() {
        isFetching = false
        DispatchQueue.main.async {
                   self.isFetching = false
                   self.fetchTimer?.invalidate()
                   self.fetchTimer = nil
               }
        exitParty()
        showToastMessage(message: "已退卡!")
        nfcMessage = "退出机厅"
    }

    private func play() {
        let urlString = "https://mais.godserver.cn/api/mai/v1/partyPlay?party=\(party)"
        guard let url = URL(string: urlString) else {
            print("无效的 URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // 发起网络请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("网络请求失败: \(error.localizedDescription)")
                return
            }
            // 检查响应状态码
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.showToastMessage(message: "上机成功!")
                    }
                } else {
                    print("服务器返回错误")
                }
            }
        
        task.resume()
    }
    private func changeToAndPlay() {
        let playerIdentifier = "\(username)()\(avaterUrl)" // 拼接用户标识符
        let changeTo2 = "\(players[2].name)()\(players[2].avatarURL)"
        let urlString = "https://mais.godserver.cn/api/mai/v1/party?party=\(party)&people=\(playerIdentifier)&changeToPeople=\(changeTo2)"
        guard let url = URL(string: urlString) else {
            print("无效的 URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // 发起网络请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("网络请求失败: \(error.localizedDescription)")
                return
            }
            // 检查响应状态码
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        play()
                    }
                } else {
                    print("服务器返回错误")
                }
            }
        
        task.resume()
    }
    private func exitParty() {
        let playerIdentifier = "\(username)()\(avaterUrl)" // 拼接用户标识符
        let urlString = "https://mais.godserver.cn/api/mai/v1/party?party=\(party)&people=\(playerIdentifier)"
        guard let url = URL(string: urlString) else {
            print("无效的 URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // 发起网络请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("网络请求失败: \(error.localizedDescription)")
                return
            }
            // 检查响应状态码
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.showToastMessage(message: "退出成功!")
                        self.saveQueueStatus(joined: false)

                    }
                } else {
                    print("服务器返回错误")
                }
            }
        
        task.resume()
    }
    private func join() {
           let playerIdentifier = "\(username)()\(avaterUrl)" // 拼接用户标识符
        if hasJoinedQueue && party == lastJoinedParty {
            showToastMessage(message: "您已经加入该队列")
            return
        }
           var a = false // 标志变量
    
           print("尝试添加")
           for index in players.indices {
               let player = players[index]
               // 检查是否已经加入房间
               print(player.name)
               print(username)
               if player.name == username {
                   showToastMessage(message: "您已经加入该房间")
                   a = true
                   break // 跳出循环
               }
           }
           if(a) {
               return
           }
           // 构造 URL 和请求
           let urlString = "https://mais.godserver.cn/api/mai/v1/party?party=\(party)&people=\(playerIdentifier)"
           guard let url = URL(string: urlString) else {
               print("无效的 URL")
               return
           }
           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           // 发起网络请求
           let task = URLSession.shared.dataTask(with: request) { data, response, error in
               if let error = error {
                   print("网络请求失败: \(error.localizedDescription)")
                   return
               }
               // 检查响应状态码
               if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                       DispatchQueue.main.async {
                           self.showToastMessage(message: "加入成功")
                           self.saveQueueStatus(joined: true)

                       }
                   } else {
                       print("服务器返回错误")
                   }
               }
           task.resume()
       }

        
    private func saveQueueStatus(joined: Bool) {
        UserDefaults.standard.set(joined, forKey: "hasJoinedQueue_\(username)")
        UserDefaults.standard.set(party , forKey: "lastJoinedParty_\(username)")
        hasJoinedQueue = joined
        lastJoinedParty = party
    }

    // 获取排卡数据
    private func fetchPartyData(party: String) {
        guard let url = URL(string: "https://mais.godserver.cn/api/mai/v1/party?party=\(party)") else {
            nfcMessage = "无效的 URL"
            return
        }

        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    nfcMessage = "网络错误: \(error.localizedDescription)"
                    return
                }

                guard let data = data,
                      let responseString = String(data: data, encoding: .utf8),
                      let playerList = parsePlayerData(responseString) else {
                    nfcMessage = "无法解析数据"
                    return
                }

                players = playerList
                nfcMessage = "排卡队列:" + party
            }
        }.resume()
    }

    // 添加处理扫描结果的方法
    private func handleScannedCode(_ code: String) {
        let parameter = code.replacingOccurrences(of: "paika", with: "")
        self.party = parameter
        self.nfcMessage = "NFC 数据: \(parameter)"
        self.startFetchingPartyData()
        self.showToastMessage(message: "扫码成功")
    }
    // 解析玩家数据
    private func parsePlayerData(_ data: String) -> [Player]? {
        let playerStrings = data.split(separator: ",")
        var players: [Player] = []

        for playerString in playerStrings {
            let components = playerString.split(separator: "(")
            guard components.count == 2,
                  let avatarURL = components[1].split(separator: ")").first else {
                continue
            }
            let name = String(components[0]).replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "\"", with: "")
            let avatar = "https://assets2.lxns.net/maimai/icon/" + String(avatarURL).replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "]", with: "") + ".png"
            //print(name + "," + avatar)
            players.append(Player(name: name, avatarURL: avatar))
        }

        return players
    }

    // 处理 NFC URL 并更新状态
    private func handleNFCURL(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let path = components.path.split(separator: "/").last else {
            nfcMessage = "无效的 NFC 数据"
            return
        }

        if path.contains("paika") {
            let parameter = path.split(separator: "paika").last ?? ""
            nfcMessage = "NFC 数据: \(parameter)"
            party = "\(parameter)"
            print(parameter)
            startFetchingPartyData()
            
        } else {
            nfcMessage = "未找到有效参数"
        }
    }
    private func showToastMessage(message: String) {
            toastMessage = message
            showToast = true
    }
    // 保存用户名到 UserDefaults
    private func saveUsername() {
        UserDefaults.standard.set(username, forKey: "username")
        print("用户名已保存：\(username)")
    }
    // 从 UserDefaults 加载用户名
    private func loadUsername() {
        if let savedUsername = UserDefaults.standard.string(forKey: "username") {
            username = savedUsername
            print("用户名已加载：\(username)")
        } else {
            if let bindingInfo = UserDefaults.standard.dictionary(forKey: "userBindingInfo"),
               let isBound = bindingInfo["isBound"] as? Bool, isBound {
                
                avaterUrl = bindingInfo["iconId"] as? String ?? ""
                username = bindingInfo["userName"] as? String ?? ""
            }
        }
    }
    private func shangJi() {
        // 处理上机逻辑
        print("执行上机操作")
        
        for index in players.indices {
            let player = players[index]
            // 检查是否已经加入房间
            if index == 2 {
                if player.name == username {
                    // 处理第 3 位玩家
                    play()
                }
            } else if index == 3 {
                if player.name == username {
                    // 处理第 4 位玩家
                    changeToAndPlay()
                }
            }
        }
    }
}

// 玩家数据模型
struct Player: Hashable , Identifiable{
    let id = UUID() // 自动生成唯一 ID
    let name: String
    let avatarURL: String
}

// 更新 PlayerCard 支持 URL 加载头像
struct PlayerCard: View {
    let imageURL: String?
    let imageName: String
    let playerName: String

    init(imageURL: String? = nil, imageName: String = "person.circle", playerName: String) {
        self.imageURL = imageURL
        self.imageName = imageName
        self.playerName = playerName
    }

    var body: some View {
        VStack {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.blue)
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.blue)
                    .padding(8)
            }

            Text(playerName)
                .font(.body)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(Color(UIColor.systemBackground))
                .shadow(radius: 4)
        )
    }
}

// 修改 LargePopupView 使其接收一个 action 闭包
struct LargePopupView: View {
    @Binding var isPresented: Bool
    let shangJiAction: () -> Void  // 新增：接收上机操作的闭包
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 半透明背景
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isPresented = false
                    }

                // 弹窗内容
                VStack(spacing: 20) {
                    // 上机按钮
                    Button(action: {
                        shangJiAction()  // 调用传入的上机操作
                        isPresented = false
                    }) {
                        Text("上机")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                    .frame(
                        width: geometry.size.width * 0.75,
                        height: geometry.size.height * 0.6
                    )
                    .padding(20)
                    .background(Color.blue)
                    .cornerRadius(16)
                    .shadow(radius: 8)

                    // 关闭按钮
                    Button("关闭弹窗") {
                        isPresented = false
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(
                    width: geometry.size.width * 0.75,
                    height: geometry.size.height * 0.75
                )
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 8)
            }
        }
    }
}

// Toolbar 视图
struct ToolbarView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.pink)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
    }
}
// 浮动按钮组
struct FloatingButtonGroup: View {
    var body: some View {
        VStack(spacing: 16) {
            // 四个按钮，从上到下排列
            FloatingActionButton(iconName: "qrcode.viewfinder", color: .green, label: "扫码") {
                print("扫码")
            }
            FloatingActionButton(iconName: "figure.run", color: .red, label: "上机") {
            }
            FloatingActionButton(iconName: "clock.arrow.circlepath", color: .orange, label: "退勤") {
                print("退勤")
            }
            FloatingActionButton(iconName: "list.bullet.rectangle.portrait", color: .blue, label: "排卡") {
                print("排卡")
            }
        }
    }
}
// 定义悬浮按钮
struct FloatingActionButton: View {
    let iconName: String
    let color: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.title2) // 图标稍小一些
                    .foregroundColor(.white)
                Text(label)
                    .font(.caption) // 文本稍小一些
                    .foregroundColor(.white)
            }
            .padding(12) // 内边距使得文字和图标之间以及背景有适当的间距
            
            .background(Circle().fill(color))
            .shadow(radius: 4)
        }
    }
}

// 边框卡片视图
struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(Color(UIColor.secondarySystemBackground))
                    .shadow(radius: 4)
            )
    }
}


struct QRScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void // 回调函数，用于返回扫描结果

    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.onScan = onScan
        return viewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var onScan: ((String) -> Void)? // 回调函数

        override func viewDidLoad() {
            super.viewDidLoad()

            // 初始化捕获会话
            captureSession = AVCaptureSession()
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                print("无法访问摄像头: \(error)")
                return
            }

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                failed()
                return
            }

            // 设置元数据输出
            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr] // 仅识别 QR 码
            } else {
                failed()
                return
            }

            // 设置预览层
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            // 开始捕获会话
            captureSession.startRunning()
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let stringValue = metadataObject.stringValue {
                onScan?(stringValue) // 调用回调函数，返回扫描结果
                print(stringValue)
                captureSession.stopRunning() // 停止捕获会话
            }
        }

        private func failed() {
            let alert = UIAlertController(title: "扫描失败", message: "无法访问摄像头", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            captureSession = nil
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }
}



