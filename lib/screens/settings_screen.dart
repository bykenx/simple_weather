import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:simple_weather/services/settings_service.dart';
import 'package:simple_weather/utils/url_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _apiHostController = TextEditingController();
  final _settingsService = SettingsService();
  bool _isLoading = true;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final apiKey = await _settingsService.getApiKey();
    final apiHost = await _settingsService.getApiHost();
    setState(() {
      _apiKeyController.text = apiKey ?? '';
      _apiHostController.text = apiHost ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      await _settingsService.setApiKey(_apiKeyController.text);
      await _settingsService.setApiHost(_apiHostController.text);
      if (mounted) {
        setState(() {
          _isEdited = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('设置已保存')));
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiHostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100.0,
            floating: false,
            backgroundColor: Colors.blue.shade50,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('设置'),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade200, Colors.blue.shade50],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (_isEdited) {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('提示'),
                          content: const Text('是否放弃修改？'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text('放弃'),
                            ),
                          ],
                        ),
                  );
                  return;
                }
                Navigator.pop(context);
              },
            ),
          ),
          SliverToBoxAdapter(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SafeArea(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '和风天气API配置',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'API密钥',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _apiKeyController,
                                  decoration: const InputDecoration(
                                    hintText: '请输入API密钥',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入API密钥';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _isEdited = true;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'API域名',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _apiHostController,
                                  decoration: const InputDecoration(
                                    hintText: '请输入API域名',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入API域名';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _isEdited = true;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '如何获取配置信息：',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: Colors.grey),
                                    children: [
                                      const TextSpan(text: '1. 访问 '),
                                      TextSpan(
                                        text: 'https://dev.qweather.com/',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap =
                                                  () => UrlUtils.launchUrlInBrowser(
                                                    'https://dev.qweather.com/',
                                                  ),
                                      ),
                                      const TextSpan(text: ' 注册账号并登录\n'),
                                      const TextSpan(text: '2. 访问 '),
                                      TextSpan(
                                        text:
                                            'https://console.qweather.com/setting',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer:
                                            TapGestureRecognizer()
                                              ..onTap =
                                                  () => UrlUtils.launchUrlInBrowser(
                                                    'https://console.qweather.com/setting',
                                                  ),
                                      ),
                                      const TextSpan(text: ' 查看API域名\n'),
                                      const TextSpan(text: '3. 创建项目并获取API密钥'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saveSettings,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('保存'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
