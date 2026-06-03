import SwiftUI

struct RoomDetailView: View {
    // Biến môi trường để đóng màn hình này lại
    @Environment(\.dismiss) private var dismiss
    
    // Dữ liệu giả lập cho danh sách thành viên và ảnh Media
    let members = [
        ("Me", true), // (Tên, isOnline)
        ("Dev BE", true),
        ("Thầy Hướng Dẫn", false),
        ("Anh Tester", false)
    ]
    
    let mediaImages = ["photo.stack.fill", "sparkles", "doc.text.fill", "folder.fill", "camera.macro", "livephoto.play"]
    
    // Layout cho lưới ảnh (3 cột)
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - 1. HEADER PROFILE (Ảnh + Tên nhóm)
                VStack(spacing: 12) {
                    Image(systemName: "person.2.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .padding(.top, 20)
                    
                    Text("Hội Dev Python 🐍")
                        .font(.title2)
                        .bold()
                    
                    Text("Mã mời: #PY2026")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
                
                // MARK: - 2. DANH SÁCH THÀNH VIÊN
                VStack(alignment: .leading, spacing: 16) {
                    Text("Thành viên (\(members.count))")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ForEach(members, id: \.0) { member in
                            HStack(spacing: 12) {
                                // Avatar thành viên
                                ZStack(alignment: .bottomTrailing) {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(member.1 ? .blue : .gray)
                                    
                                    // Chấm xanh Online
                                    if member.1 {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 12, height: 12)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                            .offset(x: 2, y: 2)
                                    }
                                }
                                
                                Text(member.0)
                                    .font(.body)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            
                            Divider().padding(.leading, 60)
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // MARK: - 3. KHO MEDIA & LỌC COREML
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Ảnh & Tệp đã gửi")
                            .font(.headline)
                        Spacer()
                        // Nút giả lập bộ lọc CoreML sau này
                        Button(action: {}) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(mediaImages, id: \.self) { imageName in
                            Rectangle()
                                .fill(Color(.secondarySystemGroupedBackground))
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Image(systemName: imageName)
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // MARK: - 4. NÚT RỜI PHÒNG
                Button(action: {
                    // Logic rời phòng
                }) {
                    Text("Rời khỏi phòng")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
                
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Thông tin nhóm")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RoomDetailView()
    }
}
