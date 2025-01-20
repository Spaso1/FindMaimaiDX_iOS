import SwiftUI

struct ActionSheetView: View {
    var body: some View {
        VStack {
            Text("Select an Option")
                .font(.headline)
                .padding()

            Button(action: {
                // 处理选项1
            }) {
                Text("Option 1")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Button(action: {
                // 处理选项2
            }) {
                Text("Option 2")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Button(action: {
                // 处理选项3
            }) {
                Text("Option 3")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding()
    }
}

struct ActionSheetView_Previews: PreviewProvider {
    static var previews: some View {
        ActionSheetView()
    }
}
