import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jverify/jverify.dart';

import 'load.dart';

void main() => runApp( MaterialApp(
  title: "demo",
  theme:  ThemeData(primaryColor: Colors.white),
  home: const MyApp(),
));

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  /// 统一 key
  final String fResultKey = "result";

  /// 错误码
  final String fCodeKey = "code";

  /// 回调的提示信息，统一返回 flutter 为 message
  final String fMsgKey = "message";

  /// 运营商信息
  final String fOprKey = "operator";

  String _result = "token=";
  var controllerPHone =  TextEditingController();
  final Jverify jverify =  Jverify();
  String? _token;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('JVerify example'),
        ),
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      widthFactor: 2,
      child:  Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.all(20),
            color: Colors.brown,
            width: 300,
            height: 100,
            child: Text(_result),
          ),
           Container(
            margin: const EdgeInsets.fromLTRB(40, 5, 40, 5),
            child:  Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                 CustomButton(
                    onPressed: () {
                      isInitSuccess();
                    },
                    title: "初始化状态"),
                 const Text("   "),
                 CustomButton(
                  onPressed: () {
                    checkVerifyEnable();
                  },
                  title: "网络环境是否支持",
                ),
              ],
            ),
          ),
           Container(
            margin: const EdgeInsets.fromLTRB(40, 5, 40, 5),
            child: SizedBox(
              width: double.infinity,
              child:  CustomButton(
                onPressed: () {
                  getToken();
                },
                title: "获取号码认证 Token",
              ),
            ),
          ),
           Container(
            margin: const EdgeInsets.fromLTRB(40, 5, 40, 5),
            child: TextField(
              autofocus: false,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                  hintText: "手机号码", hintStyle: TextStyle(color: Colors.black)),
              controller: controllerPHone,
            ),
          ),
           Container(
            margin: const EdgeInsets.fromLTRB(40, 5, 40, 5),
            child: SizedBox(
              width: double.infinity,
              child:  CustomButton(
                onPressed: () {
                  preLogin();
                },
                title: "预取号",
              ),
            ),
          ),
           Container(
            margin: const EdgeInsets.fromLTRB(40, 5, 40, 5),
            child: SizedBox(
              width: double.infinity,
              child:  CustomButton(
                onPressed: () {
                  loginAuth(false);
                },
                title: "一键登录",
              ),
            ),
          ),
           Container(
            margin: const EdgeInsets.fromLTRB(40, 5, 40, 5),
            child: SizedBox(
              width: double.infinity,
              child:  CustomButton(
                onPressed: () {
                  loginAuth(true);
                },
                title: "短信登录",
              ),
            ),
          ),
           Container(
            margin: const EdgeInsets.fromLTRB(40, 5, 40, 5),
            child: SizedBox(
              width: double.infinity,
              child:  CustomButton(
                onPressed: () {
                  getSMSCode();
                },
                title: "获取验证码",
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// sdk 初始化是否完成
  void isInitSuccess() {
    jverify.isInitSuccess().then((map) {
      bool result = map[ fResultKey];
      setState(() {
        if (result) {
          _result = "sdk 初始化成功";
        } else {
          _result = "sdk 初始化失败";
        }
      });
    });
  }

  /// 判断当前网络环境是否可以发起认证
  void checkVerifyEnable() {
    jverify.checkVerifyEnable().then((map) {
      bool result = map[ fResultKey];
      setState(() {
        if (result) {
          _result = "当前网络环境【支持认证】！";
        } else {
          _result = "当前网络环境【不支持认证】！";
        }
      });
    });
  }

  /// 获取号码认证token
  void getToken() {
    setState(() {
      _showLoading(context);
    });
    jverify.checkVerifyEnable().then((map) {
      bool result = map[ fResultKey];
      if (result) {
        jverify.getToken().then((map) {
          int code = map[fCodeKey];
          _token = map[fMsgKey];
          String operator = map[fOprKey];
          setState(() {
            _hideLoading();
            _result = "[$code] message = $_token, operator = $operator";
          });
        });
      } else {
        setState(() {
          _hideLoading();
          _result = "[2016],msg = 当前网络环境不支持认证";
        });
      }
    });
  }

  /// 获取短信验证码
  void getSMSCode() {
    setState(() {
      _showLoading(context);
    });
    String phoneNum = controllerPHone.text;
    if (phoneNum.isEmpty) {
      setState(() {
        _hideLoading();
        _result = "[3002],msg = 没有输入手机号码";
      });
      return;
    }
    jverify.checkVerifyEnable().then((map) {
      bool result = map[ fResultKey];
      if (result) {
        jverify.getSMSCode(phoneNum: phoneNum).then((map) {
          debugPrint("获取短信验证码：${map.toString()}");
          int code = map[fCodeKey];
          String message = map[fMsgKey];
          setState(() {
            _hideLoading();
            _result = "[$code] message = $message";
          });
        });
      } else {
        setState(() {
          _hideLoading();
          _result = "[3004],msg = 获取短信验证码异常";
        });
      }
    });
  }

  /// 登录预取号
  void preLogin() {
    setState(() {
      _showLoading(context);
    });
    jverify.checkVerifyEnable().then((map) {
      bool result = map[ fResultKey];
      if (result) {
        jverify.preLogin().then((map) {
          debugPrint("预取号接口回调：${map.toString()}");
          int code = map[fCodeKey];
          String message = map[fMsgKey];
          setState(() {
            _hideLoading();
            _result = "[$code] message = $message";
          });
        });
      } else {
        setState(() {
          _hideLoading();
          _result = "[2016],msg = 当前网络环境不支持认证";
        });
      }
    });
  }

  void _showLoading(BuildContext context) {
    LoadingDialog.show(context);
  }

  void _hideLoading() {
    LoadingDialog.hidden();
  }

  /// SDK 请求授权一键登录
  void loginAuth(bool isSms) {
    setState(() {
      _showLoading(context);
    });
    jverify.checkVerifyEnable().then((map) {
      bool result = map[ fResultKey];
      debugPrint("checkVerifyEnable $map");
      //需要使用sms的时候不检查result
      // if (result) {
      if (true) {

        final screenSize = PlatformDispatcher.instance.views.single.physicalSize;
        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;
        bool isiOS = Platform.isIOS;

        /// 自定义授权的 UI 界面，以下设置的图片必须添加到资源文件里，
        /// android项目将图片存放至drawable文件夹下，可使用图片选择器的文件名,例如：btn_login.xml,入参为"btn_login"。
        /// ios项目存放在 Assets.xcassets。
        ///
        JVUIConfig uiConfig = JVUIConfig();
        // uiConfig.authBGGifPath = "main_gif";
        // uiConfig.authBGVideoPath="main_vi";
        uiConfig.authBGVideoPath =
        "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";
        uiConfig.authBGVideoImgPath = "main_v_bg";

        uiConfig.navHidden = !isiOS;
        // uiConfig.navColor = Colors.red.value;
        // uiConfig.navText = "登录";
        // uiConfig.navTextColor = Colors.blue.value;
        // uiConfig.navReturnImgPath = "return_bg"; //图片必须存在

        uiConfig.logoWidth = 100;
        uiConfig.logoHeight = 80;
        //uiConfig.logoOffsetX = isiOS ? 0 : null;//(screenWidth/2 - uiConfig.logoWidth/2).toInt();
        uiConfig.logoOffsetY = 10;
        uiConfig.logoVerticalLayoutItem =  JVIOSLayoutItem.itemSuper;
        uiConfig.logoHidden = false;
        uiConfig.logoImgPath = "logo";

        uiConfig.numberFieldWidth = 200;
        uiConfig.numberFieldHeight = 40;
        //uiConfig.numFieldOffsetX = isiOS ? 0 : null;//(screenWidth/2 - uiConfig.numberFieldWidth/2).toInt();
        uiConfig.numFieldOffsetY = isiOS ? 20 : 120;
        uiConfig.numberVerticalLayoutItem =  JVIOSLayoutItem.itemLogo;
        uiConfig.numberColor = Colors.blue.value;
        uiConfig.numberSize = 18;

        uiConfig.sloganOffsetY = isiOS ? 20 : 160;
        uiConfig.sloganVerticalLayoutItem =  JVIOSLayoutItem.itemNumber;
        uiConfig.sloganTextColor = Colors.black.value;
        uiConfig.sloganTextSize = 15;
//        uiConfig.slogan
        //uiConfig.sloganHidden = 0;

        uiConfig.logBtnWidth = 220;
        uiConfig.logBtnHeight = 50;
        //uiConfig.logBtnOffsetX = isiOS ? 0 : null;//(screenWidth/2 - uiConfig.logBtnWidth/2).toInt();
        uiConfig.logBtnOffsetY = isiOS ? 20 : 230;
        uiConfig.logBtnVerticalLayoutItem =  JVIOSLayoutItem.itemSlogan;
        uiConfig.logBtnText = "登录按钮";
        uiConfig.logBtnTextColor = Colors.brown.value;
        uiConfig.logBtnTextSize = 16;
        uiConfig.logBtnTextBold = true;
        uiConfig.loginBtnNormalImage = "login_btn_normal"; //图片必须存在
        uiConfig.loginBtnPressedImage = "login_btn_press"; //图片必须存在
        uiConfig.loginBtnUnableImage = "login_btn_unable"; //图片必须存在

        uiConfig.privacyHintToast =
        true; //only android 设置隐私条款不选中时点击登录按钮默认显示toast。

        uiConfig.privacyState = false; //设置默认勾选
        uiConfig.privacyCheckboxSize = 20;
        uiConfig.checkedImgPath = "check_image"; //图片必须存在
        uiConfig.uncheckedImgPath = "uncheck_image"; //图片必须存在
        uiConfig.privacyCheckboxInCenter = true;
        uiConfig.privacyCheckboxHidden = false;
        uiConfig.isAlertPrivacyVc = true;

        //uiConfig.privacyOffsetX = isiOS ? (20 + uiConfig.privacyCheckboxSize) : null;
        uiConfig.privacyOffsetY = 15; // 距离底部距离
        uiConfig.privacyVerticalLayoutItem =  JVIOSLayoutItem.itemSuper;
        uiConfig.clauseName = "协议1";
        uiConfig.clauseUrl = "http://www.baidu.com";
        uiConfig.clauseBaseColor =
            const Color.fromARGB(255, 236, 216, 216).value;
        uiConfig.clauseNameTwo = "协议二";
        uiConfig.clauseUrlTwo = "http://www.hao123.com";
        uiConfig.clauseColor = const Color.fromARGB(255, 128, 120, 89).value;
        uiConfig.privacyText = ["我已阅读并同意", "尾部文字"];
        uiConfig.privacyTextSize = 13;
        uiConfig.privacyItem = [
          JVPrivacy("自定义协议1", "http://www.baidu.com",
              beforeName: "==", afterName: "++", separator: "、"),
          JVPrivacy("自定义协议2", "http://www.baidu.com", separator: "、"),
          JVPrivacy("自定义协议3", "http://www.baidu.com", separator: "、"),
          JVPrivacy("自定义协议4", "http://www.baidu.com", separator: "、"),
          JVPrivacy("自定义协议5", "http://www.baidu.com", separator: "、")
        ];
        uiConfig.textVerAlignment = 1;
        //uiConfig.privacyWithBookTitleMark = true;
        //uiConfig.privacyTextCenterGravity = false;
        uiConfig.authStatusBarStyle = JVIOSBarStyle.statusBarStyleDarkContent;
        uiConfig.privacyStatusBarStyle = JVIOSBarStyle.statusBarStyleDefault;
        uiConfig.modelTransitionStyle =
            JVIOSUIModalTransitionStyle.crossDissolve;

        uiConfig.statusBarColorWithNav = true;
        // uiConfig.virtualButtonTransparent = true;

        uiConfig.privacyStatusBarColorWithNav = true;
        uiConfig.privacyVirtualButtonTransparent = true;

        uiConfig.needStartAnim = true;
        uiConfig.needCloseAnim = true;
        uiConfig.enterAnim = "activity_slide_enter_bottom";
        uiConfig.exitAnim = "activity_slide_exit_bottom";

        uiConfig.privacyNavColor = Colors.red.value;
        uiConfig.privacyNavTitleTextColor = Colors.blue.value;
        uiConfig.privacyNavTitleTextSize = 16;

        uiConfig.privacyNavTitleTitle = "ios lai le"; //only ios
        uiConfig.privacyNavReturnBtnImage = "back"; //图片必须存在;

        //协议二次弹窗内容设置 -iOS
        uiConfig.isAlertPrivacyVc = true;
        uiConfig.agreementAlertViewCornerRadius = 15;
        uiConfig.agreementAlertViewBackgroundColor =
            const Color.fromARGB(255, 28, 27, 32).value;
        uiConfig.agreementAlertViewTitleTextColor = Colors.white.value;
        uiConfig.agreementAlertViewTitleText =
        "Please Read And Agree to The Following Terms";
        uiConfig.agreementAlertViewTitleTexSize = 16;
        uiConfig.agreementAlertViewContentTextAlignment =
            JVTextAlignmentType.center;
        uiConfig.agreementAlertViewContentTextFontSize = 13;
        // uiConfig.agreementAlertViewLoginBtnNormalImagePath = "login_btn_normal";
        // uiConfig.agreementAlertViewLoginBtnPressedImagePath = "login_btn_press";
        // uiConfig.agreementAlertViewLoginBtnUnableImagePath = "login_btn_unable";
        uiConfig.agreementAlertViewLoginBtnNormalImagePath =
        "login_btn_normal_dark";
        uiConfig.agreementAlertViewLoginBtnPressedImagePath =
        "login_btn_normal_dark";
        uiConfig.agreementAlertViewLoginBtnUnableImagePath =
        "login_btn_normal_dark";
        uiConfig.agreementAlertViewLogBtnText = "同意";
        uiConfig.agreementAlertViewLogBtnTextFontSize = 13;
        uiConfig.agreementAlertViewLogBtnTextColor =
            const Color.fromARGB(255, 128, 120, 89).value;

        //协议二次弹窗内容设置 -Android
        JVPrivacyCheckDialogConfig privacyCheckDialogConfig =
        JVPrivacyCheckDialogConfig();
        // privacyCheckDialogConfig.width = 250;
        // privacyCheckDialogConfig.height = 100;
        privacyCheckDialogConfig.title = "测试协议标题";
        privacyCheckDialogConfig.offsetX = 0;
        privacyCheckDialogConfig.offsetY = 0;
        privacyCheckDialogConfig.logBtnText = "同11意";
        privacyCheckDialogConfig.titleTextSize = 22;
        privacyCheckDialogConfig.gravity = "center";
        privacyCheckDialogConfig.titleTextColor = Colors.black.value;
        privacyCheckDialogConfig.contentTextGravity = "left";
        privacyCheckDialogConfig.contentTextSize = 14;
        privacyCheckDialogConfig.logBtnImgPath = "login_btn_normal";
        privacyCheckDialogConfig.logBtnTextColor = Colors.black.value;
        privacyCheckDialogConfig.logBtnMarginT = 20;
        privacyCheckDialogConfig.logBtnMarginB = 20;
        privacyCheckDialogConfig.logBtnMarginL = 10;
        privacyCheckDialogConfig.logBtnWidth = 140;
        privacyCheckDialogConfig.logBtnHeight = 40;

        /// 添加自定义的 控件 到dialog
        List<JVCustomWidget> dialogWidgetList = [];
        const String btnDialogWidgetId =
            "jv_add_custom_dialog_button"; // 标识控件 id
        JVCustomWidget buttonDialogWidget =
        JVCustomWidget(btnDialogWidgetId, JVCustomWidgetType.button);
        buttonDialogWidget.title = "取消";
        buttonDialogWidget.titleColor = Colors.white.value;
        buttonDialogWidget.left = 0;
        buttonDialogWidget.top = 160;
        buttonDialogWidget.width = 140;
        buttonDialogWidget.height = 40;
        buttonDialogWidget.textAlignment = JVTextAlignmentType.center;
        buttonDialogWidget.btnNormalImageName = "main_btn_other";
        buttonDialogWidget.btnPressedImageName = "main_btn_other";
        // buttonDialogWidget.backgroundColor = Colors.yellow.value;
        //buttonWidget.textAlignment = JVTextAlignmentType.left;

        // 添加点击事件监听
        jverify.addClikWidgetEventListener(btnDialogWidgetId, (eventId) {
          debugPrint("receive listener - click dialog widget event :$eventId");
          if (btnDialogWidgetId == eventId) {
            debugPrint("receive listener - 点击【新加 dialog button】");
          }
        });
        dialogWidgetList.add(buttonDialogWidget);
        privacyCheckDialogConfig.widgets = dialogWidgetList;
        uiConfig.privacyCheckDialogConfig = privacyCheckDialogConfig;

        //sms
        JVSMSUIConfig smsConfig = JVSMSUIConfig();
        smsConfig.smsPrivacyBeanList = [
          JVPrivacy("自定义协议1", "http://www.baidu.com",
              beforeName: "==", afterName: "++", separator: "*")
        ];
        smsConfig.enableSMSService = true;
        uiConfig.smsUIConfig = smsConfig;

        uiConfig.setIsPrivacyViewDarkMode = false; //协议页面是否支持暗黑模式

        //弹框模式
        // JVPopViewConfig popViewConfig = JVPopViewConfig();
        // popViewConfig.width = (screenWidth - 100.0).toInt();
        // popViewConfig.height = (screenHeight - 150.0).toInt();

        // uiConfig.popViewConfig = popViewConfig;

        /// 添加自定义的 控件 到授权界面
        List<JVCustomWidget> widgetList = [];

        const String textWidgetId = "jv_add_custom_text"; // 标识控件 id
        JVCustomWidget textWidget =
        JVCustomWidget(textWidgetId, JVCustomWidgetType.textView);
        textWidget.title = "新加 text view 控件";
        textWidget.left = 20;
        textWidget.top = 360;
        textWidget.width = 200;
        textWidget.height = 40;
        textWidget.backgroundColor = Colors.yellow.value;
        textWidget.isShowUnderline = true;
        textWidget.textAlignment = JVTextAlignmentType.center;
        textWidget.isClickEnable = true;

        // 添加点击事件监听
        jverify.addClikWidgetEventListener(textWidgetId, (eventId) {
          debugPrint("receive listener - click widget event :$eventId");
          if (textWidgetId == eventId) {
            debugPrint("receive listener - 点击【新加 text】");
          }
        });
        widgetList.add(textWidget);

        const String btnWidgetId = "jv_add_custom_button"; // 标识控件 id
        JVCustomWidget buttonWidget =
        JVCustomWidget(btnWidgetId, JVCustomWidgetType.button);
        buttonWidget.title = "新加 button 控件";
        buttonWidget.left = 100;
        buttonWidget.top = 400;
        buttonWidget.width = 150;
        buttonWidget.height = 40;
        buttonWidget.isShowUnderline = true;
        buttonWidget.backgroundColor = Colors.brown.value;
        //buttonWidget.btnNormalImageName = "";
        //buttonWidget.btnPressedImageName = "";
        //buttonWidget.textAlignment = JVTextAlignmentType.left;

        // 添加点击事件监听
        jverify.addClikWidgetEventListener(btnWidgetId, (eventId) {
          debugPrint("receive listener - click widget event :$eventId");
          if (btnWidgetId == eventId) {
            debugPrint("receive listener - 点击【新加 button】");
          }
        });
        widgetList.add(buttonWidget);

        // 设置iOS的二次弹窗按钮
        uiConfig.agreementAlertViewWidgets = dialogWidgetList;
        uiConfig.agreementAlertViewUIFrames = {
          "superViewFrame": [
            (screenWidth ~/ 2).toInt() - 140,
            (screenHeight ~/ 2).toInt() - 150,
            280,
            200
          ],
          "alertViewFrame": [0, 0, 280, 200],
          "titleFrame": [10, 10, 260, 60],
          "contentFrame": [15, 70, 250, 110],
          "buttonFrame": [140, 160, 140, 40]
        };

        /// 步骤 1：调用接口设置 UI
        jverify.setCustomAuthorizationView(true, uiConfig,
            landscapeConfig: uiConfig, widgets: widgetList);
        if (!isSms) {
          /// 步骤 2：调用一键登录接口
          jverify.loginAuthSyncApi2(
              autoDismiss: true,
              enableSms: true,
              loginAuthCallback: (event) {
                setState(() {
                  _hideLoading();
                  _result = "获取返回数据：[${event.code}] message = ${event.message}";
                });
                debugPrint(
                    "获取到 loginAuthSyncApi 接口返回数据，code=${event.code},message = ${event.message},operator = ${event.operator}");
              });
        } else {
          /// 步骤 2：调用短信登录接口
          jverify.smsAuth(
              autoDismiss: true,
              smsCallback: (event) {
                setState(() {
                  _hideLoading();
                  _result = "获取返回数据：[${event.code}] message = ${event.message}";
                });
                debugPrint(
                    "获取到 smsAuth 接口返回数据，code=${event.code},message = ${event.message},phone = ${event.phone}");
              });
        }
      }
      // else {
      //   setState(() {
      //     _hideLoading();
      //     _result = "[2016],msg = 当前网络环境不支持认证";
      //   });
      //
      //   /* 弹框模式
      //   JVPopViewConfig popViewConfig = JVPopViewConfig();
      //   popViewConfig.width = (screenWidth - 100.0).toInt();
      //   popViewConfig.height = (screenHeight - 150.0).toInt();
      //
      //   uiConfig.popViewConfig = popViewConfig;
      //   */
      //
      //   /*
      //
      //   /// 方式二：使用异步接口 （如果想使用异步接口，则忽略此步骤，看方式二）
      //
      //   /// 先，执行异步的一键登录接口
      //   jverify.loginAuth(true).then((map) {
      //
      //     /// 再，在回调里获取 loginAuth 接口异步返回数据（如果是通过添加 JVLoginAuthCallBackListener 监听来获取返回数据，则忽略此步骤）
      //     int code = map[fCodeKey];
      //     String content = map[fMsgKey];
      //     String operator = map[fOprKey];
      //     setState(() {
      //      _hideLoading();
      //       _result = "接口异步返回数据：[$code] message = $content";
      //     });
      //     debugPrint("通过接口异步返回，获取到 loginAuth 接口返回数据，code=$code,message = $content,operator = $operator");
      //   });
      //
      //   */
      // }
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // 初始化 SDK 之前添加监听
    jverify.addSDKSetupCallBackListener((JVSDKSetupEvent event) {
      debugPrint("接收 SDK 设置回调事件 :${event.toMap()}");
    });

    jverify.setDebugMode(true); // 打开调试模式
    jverify.setCollectionAuth(true);
    jverify.setup(
        appKey: "4fcc3e237eec4c4fb804ad49", //"你自己应用的 AppKey",
        channel: "default_developer"); // 初始化sdk,  appKey 和 channel 只对ios设置有效
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    /// 授权页面点击时间监听
    jverify.addAuthPageEventListener((JVAuthPageEvent event) {
      debugPrint("接收身份验证页面事件 :${event.toMap()}");
    });
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty(' fResultKey',  fResultKey));
  }
}

/// 封装 按钮
class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? title;

  const CustomButton({super.key, required this.onPressed, this.title});

  @override
  Widget build(BuildContext context) {
    return  TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.white),
        overlayColor: WidgetStateProperty.all(const Color(0xff888888)),
        backgroundColor: WidgetStateProperty.all(const Color(0xff585858)),
        padding: WidgetStateProperty.all(const EdgeInsets.fromLTRB(10, 5, 10, 5)),
      ),
      child:  Text("$title"),
    );
  }
}
