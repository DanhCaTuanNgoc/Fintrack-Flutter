# Hướng dẫn cấu hình Google Sign-In cho Fintrack Flutter

## Bước 1: Tạo OAuth 2.0 Client IDs trong Google Console

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo project mới hoặc chọn project hiện có
3. Tạo OAuth 2.0 Client IDs:
   - Vào "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client ID"
   - Chọn "Android" và nhập thông tin:
     - Package name: `com.example.fintrack`
     - SHA-1 certificate fingerprint: (xem hướng dẫn bên dưới)
   - Chọn "Web application" và tạo thêm một client ID

## Bước 2: Lấy SHA-1 Certificate Fingerprint

### Cho Debug (Development):
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Cho Release (Production):
```bash
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

## Bước 3: Cập nhật cấu hình Android

1. **Tải file google-services.json:**
   - Từ Google Console, tải file `google-services.json`
   - Thay thế file `android/app/google-services.json` hiện tại

2. **Cập nhật strings.xml:**
   - Mở `android/app/src/main/res/values/strings.xml`
   - Thay `YOUR_WEB_CLIENT_ID` bằng Web Client ID từ Google Console

## Bước 4: Cấu hình iOS (nếu cần)

1. **Thêm URL Scheme:**
   - Mở `ios/Runner/Info.plist`
   - Thay `YOUR_REVERSED_CLIENT_ID` bằng Reversed Client ID từ Google Console
   - Reversed Client ID có dạng: `com.googleusercontent.apps.YOUR_CLIENT_ID`

2. **Tải GoogleService-Info.plist:**
   - Từ Google Console, tải file `GoogleService-Info.plist`
   - Đặt vào thư mục `ios/Runner/`

## Bước 5: Test ứng dụng

1. Chạy ứng dụng: `flutter run`
2. Vào Settings > Đăng nhập với Google
3. Kiểm tra xem đăng nhập có hoạt động không

## Troubleshooting

### Lỗi "DEVELOPER_ERROR":
- Kiểm tra SHA-1 fingerprint
- Đảm bảo package name khớp
- Kiểm tra google-services.json

### Lỗi "NETWORK_ERROR":
- Kiểm tra kết nối internet
- Kiểm tra Google Services API

### Lỗi "SIGN_IN_FAILED":
- Kiểm tra OAuth client configuration
- Đảm bảo Google Sign-In API đã kích hoạt
