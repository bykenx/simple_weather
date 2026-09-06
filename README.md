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
  - 首页展示未来 24 小时预报和最多 10 天每日预报
  - 点击预报卡片打开底部详情面板，按日期查看天气趋势
  - 实际气温／体感温度切换、降水概率图表及逐小时详细指标
  - 最高/最低温度
  - 天气图标和描述

- ⚠️ 天气预警
  - 实时预警信息
  - 预警等级和类型
  - 预警详情和影响范围
  - 预警发布时间

- 🏙️ 城市管理
  - 多城市支持
  - 热门城市、城市搜索和添加
  - 当前城市设置
  - 城市列表管理

- 🌙 天气详情与天文信息
  - 风、降水、湿度、能见度等详情卡片
  - 日出日落、月升月落、月相照明比例和下次满月

- 按城市、按模块保存本地天气缓存，兼容旧版缓存
- 统一卡片与底部详情面板，支持手动切换浅色／深色主题

- 首页动态天空：晴天光晕、夜间星月、流动云层、雨雪、雷暴及雾霾效果；随当前城市天气柔和切换。进入后台或开启系统“减少动态效果”时停止动画。

## 使用说明

- 各天气模块独立加载；某项失败不会阻止其他内容展示。点击模块的“重试”只更新该项，下拉刷新更新全部模块。
- 离线或刷新失败时保留已保存数据，首页统一显示最近成功更新时间；包含超过一小时的数据时提示部分数据已过期。没有可展示数据的模块自动隐藏，已过有效期的预警不展示。
- 在城市管理页拖动右侧手柄调整顺序，顺序自动保存。删除当前城市后切换到剩余第一座城市。
- 点击逐小时或每日预报卡片，在底部详情面板中切换日期、查看实际气温／体感温度和降水概率图表；缺失指标显示暂无数据，不按零处理。空气质量与天气预警详情也通过底部面板展示。
- 每日预报优先请求 v1 的 10 天数据，失败时依次回退至 v7 的 10 天、3 天预报，界面按实际返回天数展示。逐小时预报请求 v1 的 240 小时数据，首页仅预览前 24 小时；接口权限不足或覆盖不完整时显示模块错误，保留已有数据。旧版短时逐小时缓存会触发重新加载。
- 月相数据通过天文接口补充，获取失败不影响每日预报；下次满月在缺少预报数据时使用近似计算。

## 本地天气效果预览

Debug 构建的首页右下角提供“天气效果预览”按钮，即使没有配置 API 或添加城市也能进入。预览复用首页动画，支持所有天气类型、白天／夜间、暂停／播放、从头播放、减少动态效果、示例内容与隐藏面板，不修改实际天气数据。

也可在 VS Code 选择“天气动画预览 (debug)”，或运行 `flutter run --dart-define=WEATHER_PREVIEW=true` 直接进入。Profile／Release 构建没有预览入口，该启动参数也不会生效。

太阳和月亮是独立背景元素，不参与温度文字排版。太阳位于温度左上方，采用柔边六边形核心，带有柔光、星芒以及向右下方延伸的淡色光斑；星芒和光斑以 60 秒为周期缓慢往返旋转，总摆幅为 45°（±22.5°），暂停或减少动态效果时静止。夜间弯月位于温度左侧，内侧透明，仅明亮外缘带有柔和月晕。背景天空、云雾、太阳和光斑由 `shaders/weather_atmosphere.frag` 一次合成，并在最终输出时加入细微的非周期抖动以减轻网格与色阶断层；弯月使用 `shaders/weather_crescent.frag`。新增或修改这些资源后请重新运行应用，避免继续使用已缓存的着色器。

晴天和多云的夜间背景包含错落闪烁的星光，以及从右向左划过的流星。动画从头播放约 6 秒后出现第一颗流星，随后每隔约 17–23 秒出现一次；多云时亮度减弱。暂停时画面冻结，开启“减少动态效果”时显示静态星空并隐藏流星。

天气图标使用 Dart 常量映射，以支持 release 构建的字体裁剪。修改 `assets/qweather_weather_code_map.json` 后，运行 `python3 scripts/generate_weather_icons.py > lib/utils/weather_icons.g.dart`，再运行 `dart format lib/utils/weather_icons.g.dart` 更新映射。

## 技术栈

- Flutter
- Dart
- 和风天气 API
- Dio HTTP 客户端
- SharedPreferences 本地存储
- ChangeNotifier 天气加载控制器
- Flutter Fragment Shader 动态天空与月相渲染

## 安装步骤

1. 克隆项目
```bash
git clone https://github.com/bykenx/simple_weather.git weather_app
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
dart run flutter_launcher_icons
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
- 每日预报：`/weather/v1/daily/{lat}/{lon}`，请求 10 天；失败时回退至 `/v7/weather/10d`、`/v7/weather/3d`
- 逐小时预报：`/weather/v1/hourly/{lat}/{lon}`，请求 240 小时
- 月升月落与月相：`/v7/astronomy/moon`
- 天气预警信息
- 城市搜索服务

API 文档：[和风天气 API 文档](https://dev.qweather.com/docs/api/)

## 项目结构

```
lib/
├── models/          # 天气、预报详情与模块状态模型
├── screens/         # 首页、城市管理、搜索、设置与 Debug 天气预览
├── services/        # API、城市存储、模块缓存与天气加载控制器
├── utils/           # 主题、天气图标、预警颜色与月亮方向计算
├── widgets/         # 天气场景、卡片、趋势图与底部详情面板
└── routes/          # 路由
shaders/             # 天空、弯月与月相着色器
assets/moon/         # 月相资源
scripts/             # 图标转换与天气图标映射生成脚本
```

## 许可证

MIT License
