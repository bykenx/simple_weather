# 简单天气

一个基于和风天气 API 开发的天气应用，提供实时天气、空气质量、天气预报和天气预警等功能。

> 这是一个自用的天气应用项目，目前正在逐步完善中。

## 功能特性

- 🌤️ 实时天气信息
  - 当前温度、体感温度
  - 天气状况和描述
  - 风向和风速
  - 湿度和气压
  - 能见度和云量

- 🌡️ 空气质量
  - AQI 指数显示
  - 空气质量等级
  - 主要污染物
  - 详细污染物浓度
  - 健康建议

- 📅 天气预报
  - 24小时逐小时预报
  - 7天天气预报
  - 最高/最低温度
  - 天气图标和描述

- ⚠️ 天气预警
  - 实时预警信息
  - 预警等级和类型
  - 预警详情和影响范围
  - 预警发布时间

- 🏙️ 城市管理
  - 多城市支持
  - 城市搜索和添加
  - 当前城市设置
  - 城市列表管理

## 技术栈

- Flutter
- Dart
- 和风天气 API
- HTTP 客户端
- 本地存储
- 状态管理

## 安装步骤

1. 克隆项目
```bash
git clone https://github.com/bykenx/simple_weather.git
cd weather_app
```

2. 安装依赖
```bash
flutter pub get
```

3. 配置 API 密钥
- 访问[和风天气开发者平台](https://dev.qweather.com/)注册账号
- 创建应用并获取 API Key
- 在应用内进入"设置"页面
- 配置以下信息：
  - API 密钥：输入你的 API Key
  - API Host：访问[和风天气控制台](https://console.qweather.com/setting)获取你的 API Host（格式应为：xxxx.re.qweatherapi.com，格式可能会变化，以实际为准）
- 点击保存完成配置

_**注意：每个和风天气应用都有独立的 API Host，请确保使用正确的域名，否则 API 请求将无法正常工作。**_

4. 生成应用图标（可选）
```bash
# 安装 svg2png（如果尚未安装）
brew install svg2png

# 运行转换脚本
./scripts/convert_svg_to_png.sh assets/app_icon.svg

# 生成应用图标
flutter pub run flutter_launcher_icons
```

5. 运行应用
```bash
flutter run
```

## 构建发布版本

### Android 构建

1. 配置签名环境变量
```bash
# 在 ~/.zshrc 或 ~/.bash_profile 中添加以下环境变量
export KEYSTORE_PASSWORD=your_keystore_password
export KEY_PASSWORD=your_key_password
```

2. 生成签名密钥（如果尚未生成）
```bash
keytool -genkey -v \
  -keystore android/app/keystore/release.keystore \
  -alias release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass your_store_password \
  -keypass your_key_password
```

3. 构建发布版本
```bash
# 构建所有架构的 APK
flutter build apk --split-per-abi

# 构建特定架构的 APK
flutter build apk --target-platform android-arm64
```

构建完成后，APK 文件将位于以下位置：
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### iOS 构建

1. 打开 Xcode 项目
```bash
open ios/Runner.xcworkspace
```

2. 在 Xcode 中配置签名
- 选择 Runner 项目
- 选择 Runner target
- 在 "Signing & Capabilities" 标签页中：
  - 选择开发者账号
  - 设置 Bundle Identifier
  - 选择 Provisioning Profile

3. 构建发布版本
```bash
flutter build ios --release
```

## API 说明

本项目使用和风天气 API 提供以下服务：
- 实时天气数据
- 空气质量数据
- 天气预报数据
- 天气预警信息
- 城市搜索服务

API 文档：[和风天气 API 文档](https://dev.qweather.com/docs/api/)

## 项目结构

```
lib/
├── models/          # 数据模型
├── screens/         # 页面
├── services/        # 服务
├── utils/           # 工具类
├── widgets/         # 组件
└── routes/          # 路由
```

## 许可证

MIT License