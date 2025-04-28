import SwiftUI

struct SettingsView: View {
    @State private var securityCode: String = ""
    @State private var bindingKey: String = ""
    @State private var isAccountBound: Bool = false
    @State private var iconId: String = ""
    @State private var userName: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var raw : String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("账号绑定")) {
                    if isAccountBound {
                        boundAccountView
                    } else {
                        bindingInputView
                    }
                }
                
                if isAccountBound {
                    Section(header: Text("用户信息")) {
                        userInfoView
                    }
                    
                    Section(header: Text("功能内容")) {
                        functionalContentView
                    }
                }
                
                Section {
                    Button(action: {
                        if isAccountBound {
                            unbindAccount()
                        } else {
                            bindAccount()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text(isAccountBound ? "解绑账号" : "绑定账号")
                                    .foregroundColor(isAccountBound ? .red : .blue)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
            }
            .onAppear {
                checkAccountBindingStatus()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var boundAccountView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if !iconId.isEmpty {
                    AsyncImage(url: URL(string: "https://assets2.lxns.net/maimai/icon/\(iconId).png")) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                }
                
                Text(userName.isEmpty ? "已绑定用户" : userName)
                    .font(.headline)
                    .padding(.leading, 8)
            }
        }
    }
    
    private var bindingInputView: some View {
        Group {
            TextField("安全码", text: $securityCode)
            TextField("绑定Key", text: $bindingKey)
        }
    }
    
    private var userInfoView: some View {
        Group {
            if !iconId.isEmpty {
                HStack {
                    Text("头像URL:")
                    Spacer()
                    Text(iconId)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            if !userName.isEmpty {
                HStack {
                    Text("用户名:")
                    Spacer()
                    Text(userName)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var functionalContentView: some View {
        Group {
            NavigationLink(destination: Text("功能页面1")) {
                Text("功能1")
            }
            
            NavigationLink(destination: Text("功能页面2")) {
                Text("功能2")
            }
        }
    }
    
    // MARK: - Binding Logic
    
    private func bindAccount() {
        guard !securityCode.isEmpty, !bindingKey.isEmpty else {
            showAlert(message: "请输入安全码和绑定Key")
            return
        }
        
        isLoading = true
        
        let urlString = "https://mais.godserver.cn/api/qq/safeCoding?result=\(bindingKey)&safecode=\(securityCode)"
        print(urlString)
        guard let url = URL(string: urlString) else {
            showAlert(message: "无效的URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.showAlert(message: "网络请求失败: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    self.showAlert(message: "服务器返回错误")
                    return
                }
                
                guard let data = data else {
                    self.showAlert(message: "没有接收到数据")
                    return
                }
                
                // Save the raw data first
                let rawDataString = String(data: data, encoding: .utf8) ?? ""
                self.raw = rawDataString
                
                UserDefaults.standard.set(raw, forKey: "user")

                
                self.fetchUserData(from: rawDataString)
            }
        }
        task.resume()
    }
    
    private func fetchUserData(from qqData: String) {
        isLoading = true
        
        let userDataUrlString = "https://mais.godserver.cn/api/qq/userData?qq=\(qqData)"
        guard let url = URL(string: userDataUrlString) else {
            showAlert(message: "无效的用户数据URL")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.showAlert(message: "获取用户数据失败: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    self.showAlert(message: "用户数据服务器返回错误")
                    return
                }
                
                guard let data = data else {
                    self.showAlert(message: "没有接收到用户数据")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let userData = try decoder.decode(UserData.self, from: data)
                    
                    // 更新状态变量
                    self.userName = userData.userName
                    self.iconId = String(userData.iconId) // 转换为String
                    
                    // 保存到UserDefaults
                    let bindingInfo: [String: Any] = [
                        "securityCode": self.securityCode,
                        "bindingKey": self.bindingKey,
                        "iconId": String(userData.iconId),
                        "userName": userData.userName,
                        "rating": userData.playerRating,
                        "isBound": true,
                        "bindingDate": Date()
                    ]
                    
                    UserDefaults.standard.set(bindingInfo, forKey: "userBindingInfo")
                    self.isAccountBound = true
                    
                    self.showAlert(message: "账号绑定成功")
                } catch {
                    print("解码错误: \(error)")
                    self.showAlert(message: "解析用户数据失败: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }
    private func unbindAccount() {
        clearBindingData()
        isAccountBound = false
        securityCode = ""
        bindingKey = ""
        iconId = ""
        userName = ""
        showAlert(message: "账号已解绑")
    }
    
    // MARK: - Data Management
    
    private struct UserBindingData {
        let iconId: String
        let userName: String
    }
    
    private func saveBindingData(securityCode: String, bindingKey: String, userData: UserBindingData) {
        do {
            let encoder = JSONEncoder()
            
            let bindingInfo: [String: Any] = [
                "securityCode": securityCode,
                "bindingKey": bindingKey,
                "avatarURL": self.iconId,
                "username": self.userName,
                "isBound": true,
                "bindingDate": Date()
            ]
            
            UserDefaults.standard.set(bindingInfo, forKey: "userBindingInfo")
            UserDefaults.standard.set(self.userName, forKey: "username")
            UserDefaults.standard.set(self.iconId, forKey: "iconId")

        } catch {
            print("Failed to encode user data: \(error)")
        }
    }
    
    private func clearBindingData() {
        UserDefaults.standard.removeObject(forKey: "userBindingInfo")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "iconId")

    }
    
    private func checkAccountBindingStatus() {
        if let bindingInfo = UserDefaults.standard.dictionary(forKey: "userBindingInfo"),
           let isBound = bindingInfo["isBound"] as? Bool, isBound {
            
            isAccountBound = true
            iconId = bindingInfo["iconId"] as? String ?? ""
            userName = bindingInfo["userName"] as? String ?? ""
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}
struct UserData: Codable {
    let userId: Int
    let userName: String
    let lastGameId: String
    let lastRomVersion: String
    let lastDataVersion: String
    let lastLoginDate: String
    let lastPlayDate: String
    let playerRating: Int
    let nameplateId: Int
    let iconId: Int
    let banState: Int
    
    // 不需要显式声明 CodingKeys 除非字段名不同
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
