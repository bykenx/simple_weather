# 简单天气

一个自用的天气 App，用来查天气、看预报。用 Flutter 写的，数据来自和风天气，支持 Android 和 iOS。

## 运行

准备好 Flutter 环境，在项目目录执行：

```bash
flutter pub get
flutter run
```

打开后，在「设置」里填好和风天气的 API Key 和 API Host，再添加城市就能用了。

## 构建

### Android

准备好签名文件 `android/app/keystore/release.keystore`，密钥别名为 `release`，然后执行：

```bash
export KEYSTORE_PASSWORD="你的密钥库密码"
export KEY_PASSWORD="你的密钥密码"
flutter build apk --release --split-per-abi
```

APK 在 `build/app/outputs/flutter-apk/` 下，按设备架构选择安装。

### iOS

需要 macOS 和 Xcode。打开 `ios/Runner.xcworkspace`，在 Runner 的 Signing & Capabilities 中选择自己的开发团队，再执行：

```bash
flutter build ios --release
```

构建结果在 `build/ios/iphoneos/` 下。需要导出 IPA 时，在 Xcode 中通过 Archive 打包。

## 许可证

MIT License
