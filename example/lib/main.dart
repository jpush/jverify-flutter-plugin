import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jverify/jverify.dart';

import 'load.dart';

void main() => runApp(new MaterialApp(
      title: "demo",
      theme: new ThemeData(primaryColor: Colors.white),
      home: MyApp(),
    ));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _iosAppKey = '4fcc3e237eec4c4fb804ad49';
  static const String _ohosAppKey = '667c13ce8023161dbfd75a6e';
  static const String _ohosHelpWidgetId = 'ohos_auth_help';
  static const String _ohosImageWidgetId = 'ohos_auth_image';
  static const String _ohosDialogCancelWidgetId = 'ohos_dialog_cancel';
  static const String _ohosCmImageButtonWidgetId = 'ohos_cm_image_button';
  static const String _ohosCmCloseWidgetId = 'ohos_cm_close_image';

  static String? get _platformAppKey {
    if (Platform.isIOS) {
      return _iosAppKey;
    }
    if (Platform.operatingSystem == 'ohos') {
      return _ohosAppKey;
    }
    // Android 从 app/build.gradle 的 JPUSH_APPKEY 初始化，不读取 Dart appKey。
    return null;
  }

  /// 统一 key
  final String f_result_key = "result";

  /// 额外信息
  final String f_extra_key = "extra";

  /// 错误码
  final String f_code_key = "code";

  /// 回调的提示信息，统一返回 flutter 为 message
  final String f_msg_key = "message";

  /// 运营商信息
  final String f_opr_key = "operator";

  String _result = "token=";
  final Jverify jverify = new Jverify();
  String? _token;
  final JVAuthPageEventListener _authPageEventListener =
      (JVAuthPageEvent event) {
    print("receive auth page event :${event.toMap()}");
  };

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
      child: SingleChildScrollView(
        child: new Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.all(20),
              color: Colors.brown,
              child: Text(_result),
              width: 300,
              height: 100,
            ),
            new Container(
              margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
              child: new Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: <Widget>[
                  new CustomButton(
                      onPressed: () {
                        isInitSuccess();
                      },
                      title: "初始化状态"),
                  new CustomButton(
                    onPressed: () {
                      checkVerifyEnable();
                    },
                    title: "网络环境是否支持",
                  ),
                ],
              ),
            ),
            new Container(
              child: SizedBox(
                child: new CustomButton(
                  onPressed: () {
                    getToken();
                  },
                  title: "获取号码认证 Token",
                ),
                width: double.infinity,
              ),
              margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
            ),
            new Container(
              child: SizedBox(
                child: new CustomButton(
                  onPressed: () {
                    preLogin();
                  },
                  title: "预取号",
                ),
                width: double.infinity,
              ),
              margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
            ),
            new Container(
              child: SizedBox(
                child: new CustomButton(
                  onPressed: () {
                    checkPreLoginCache();
                  },
                  title: "是否存在预取号缓存",
                ),
                width: double.infinity,
              ),
              margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
            ),
            new Container(
              child: SizedBox(
                child: new CustomButton(
                  onPressed: () {
                    loginAuth();
                  },
                  title: "一键登录",
                ),
                width: double.infinity,
              ),
              margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
            ),
            new Container(
              margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
              child: new Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: <Widget>[
                  new CustomButton(
                    onPressed: clearPreLoginCache,
                    title: "清除预取号缓存",
                  ),
                  new CustomButton(
                    onPressed: dismissLoginAuthView,
                    title: "关闭授权页",
                  ),
                ],
              ),
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.start,
        ),
      ),
    );
  }

  /// sdk 初始化是否完成
  void isInitSuccess() {
    jverify.isInitSuccess().then((map) {
      bool result = map[f_result_key];
      setState(() {
        if (result) {
          _result = "sdk 初始换成功";
        } else {
          _result = "sdk 初始换失败";
        }
      });
    });
  }

  /// 判断当前网络环境是否可以发起认证
  void checkVerifyEnable() {
    jverify.checkVerifyEnable().then((map) {
      bool result = map[f_result_key];
      Map extra = map[f_extra_key] is Map ? map[f_extra_key] : const {};
      setState(() {
        if (result) {
          _result = "当前网络环境【支持认证】！" + extra.toString();
        } else {
          _result = "当前网络环境【不支持认证】！" + extra.toString();
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
      bool result = map[f_result_key];
      if (result) {
        jverify.getToken().then((map) {
          int code = map[f_code_key];
          _token = map[f_msg_key];
          String operator = map[f_opr_key];
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

  /// 预取号缓存
  void checkPreLoginCache() {
    jverify.validPreloginCache().then((map) {
      bool result = map[f_result_key];
      setState(() {
        if (result) {
          _result = "预取号缓存有效";
        } else {
          _result = "预取号缓存无效";
        }
      });
    });
  }

  void clearPreLoginCache() {
    jverify.clearPreLoginCache();
    setState(() {
      _result = "已请求清除预取号缓存";
    });
  }

  void dismissLoginAuthView() {
    jverify.dismissLoginAuthView();
    setState(() {
      _result = "已请求关闭授权页";
    });
  }

  void preLogin() {
    setState(() {
      _showLoading(context);
    });
    jverify.checkVerifyEnable().then((map) {
      bool result = map[f_result_key];
      if (result) {
        jverify.preLogin(enableSms: false).then((map) {
          print("预取号接口回调：${map.toString()}");
          int code = map[f_code_key];
          String message = map[f_msg_key];
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
  void loginAuth() {
    setState(() {
      _showLoading(context);
    });
    jverify.checkVerifyEnable().then((map) {
      bool result = map[f_result_key];
      print("checkVerifyEnable $map");
      if (result) {
        final screenSize = MediaQuery.of(context).size;
        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;
        bool isiOS = Platform.isIOS;
        if (Platform.operatingSystem == 'ohos') {
          _loginAuthOnHarmonyOS();
          return;
        }

        /// 自定义授权的 UI 界面，以下设置的图片必须添加到资源文件里，
        /// android项目将图片存放至drawable文件夹下，可使用图片选择器的文件名,例如：btn_login.xml,入参为"btn_login"。
        /// ios项目存放在 Assets.xcassets。
        ///
        JVUIConfig uiConfig = JVUIConfig();
        // uiConfig.authBGGifPath = "main_gif";
        uiConfig.authBGVideoPath = "videoBg";
        // uiConfig.authBGVideoPath =
        //     "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";
        uiConfig.authBGVideoImgPath = "cmBackground";

        uiConfig.navHidden = !isiOS;
        // uiConfig.navColor = Colors.red.value;
        // uiConfig.navText = "登录";
        // uiConfig.navTextColor = Colors.blue.value;
        // uiConfig.navReturnImgPath = "return_bg"; //图片必须存在

        uiConfig.logoWidth = 100;
        uiConfig.logoHeight = 80;
        //uiConfig.logoOffsetX = isiOS ? 0 : null;//(screenWidth/2 - uiConfig.logoWidth/2).toInt();
        uiConfig.logoOffsetY = 10;
        uiConfig.logoVerticalLayoutItem = JVIOSLayoutItem.ItemSuper;
        uiConfig.logoHidden = false;
        uiConfig.logoImgPath = "logo";

        uiConfig.numberFieldWidth = 200;
        uiConfig.numberFieldHeight = 40;
        //uiConfig.numFieldOffsetX = isiOS ? 0 : null;//(screenWidth/2 - uiConfig.numberFieldWidth/2).toInt();
        uiConfig.numFieldOffsetY = isiOS ? 20 : 120;
        uiConfig.numberVerticalLayoutItem = JVIOSLayoutItem.ItemLogo;
        uiConfig.numberColor = Colors.blue.value;
        uiConfig.numberSize = 18;

        uiConfig.sloganOffsetY = isiOS ? 20 : 160;
        uiConfig.sloganVerticalLayoutItem = JVIOSLayoutItem.ItemNumber;
        uiConfig.sloganTextColor = Colors.black.value;
        uiConfig.sloganTextSize = 15;
        uiConfig.sloganWidth = 100;
//        uiConfig.slogan
        //uiConfig.sloganHidden = 0;

        uiConfig.logBtnWidth = 220;
        uiConfig.logBtnHeight = 50;
        //uiConfig.logBtnOffsetX = isiOS ? 0 : null;//(screenWidth/2 - uiConfig.logBtnWidth/2).toInt();
        uiConfig.logBtnOffsetY = isiOS ? 20 : 230;
        uiConfig.logBtnVerticalLayoutItem = JVIOSLayoutItem.ItemSlogan;
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
        uiConfig.privacyCheckboxOffsetY = 5;
        uiConfig.checkedImgPath = "check_image"; //图片必须存在
        uiConfig.uncheckedImgPath = "uncheck_image"; //图片必须存在
        uiConfig.privacyCheckboxInCenter = true;
        uiConfig.privacyCheckboxHidden = false;
        uiConfig.isAlertPrivacyVc = true;

        //uiConfig.privacyOffsetX = isiOS ? (20 + uiConfig.privacyCheckboxSize) : null;
        uiConfig.privacyOffsetY = 50; // 距离底部距离
        uiConfig.privacyOffsetX = 50; // 距离底部距离
        uiConfig.privacyMarginR = 50;
        uiConfig.privacyVerticalLayoutItem = JVIOSLayoutItem.ItemSuper;
        uiConfig.clauseName = "协议1";
        uiConfig.clauseUrl = "http://www.baidu.com";
        uiConfig.clauseBaseColor =
            const Color.fromARGB(255, 236, 216, 216).value;
        uiConfig.clauseNameTwo = "协议二";
        uiConfig.clauseUrlTwo = "http://www.hao123.com";
        uiConfig.clauseColor = const Color.fromARGB(255, 128, 120, 89).value;
        uiConfig.privacyText = ["我已阅读并同意", ""];
        uiConfig.privacyTextSize = 10;
        uiConfig.privacyItem = [
          JVPrivacy("自定义协议1", "http://www.baidu.com",
              beforeName: "==", afterName: "++", separator: "、"),
          // JVPrivacy("自定义", "http://www.baidu.com", separator: "、"),
          // JVPrivacy("自定义协议3", "http://www.baidu.com", separator: "、"),
          // JVPrivacy("自定义协议4", "http://www.baidu.com", separator: "、"),
          // JVPrivacy("自定义协议5", "http://www.baidu.com", separator: "、")
        ];
        uiConfig.textVerAlignment = 1;
        //uiConfig.privacyWithBookTitleMark = true;
        //uiConfig.privacyTextCenterGravity = false;
        uiConfig.authStatusBarStyle = JVIOSBarStyle.StatusBarStyleDarkContent;
        uiConfig.privacyStatusBarStyle = JVIOSBarStyle.StatusBarStyleDefault;
        uiConfig.modelTransitionStyle =
            JVIOSUIModalTransitionStyle.CrossDissolve;

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
        uiConfig.privacyNavReturnBtnImage = "umcsdk_return_bg"; //图片必须存在;

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

        uiConfig.appLanguageType = "1";
        uiConfig.navReturnBtnOffsetX = 10;
        uiConfig.navReturnBtnOffsetY = 10;
        uiConfig.navReturnBtnHidden = false;
        uiConfig.navReturnImgPath = "umcsdk_return_bg"; //图片必须存在
        uiConfig.navHidden = false;
        uiConfig.navTransparent = false;
        uiConfig.statusBarTransparent = true;
        uiConfig.navText = "";
        // uiConfig.openPrivacyInBrowser = true;

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
        privacyCheckDialogConfig.contentTextPaddingL = 10;
        privacyCheckDialogConfig.privacyBackgroundColor = Colors.red.value;

        /// 添加自定义的 控件 到dialog
        List<JVCustomWidget> dialogWidgetList = [];
        final String btn_dialog_widgetId =
            "jv_add_custom_dialog_button"; // 标识控件 id
        JVCustomWidget buttonDialogWidget =
            JVCustomWidget(btn_dialog_widgetId, JVCustomWidgetType.button);
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
        jverify.addClikWidgetEventListener(btn_dialog_widgetId, (eventId) {
          print("receive listener - click dialog widget event :$eventId");
          if (btn_dialog_widgetId == eventId) {
            print("receive listener - 点击【新加 dialog button】");
          }
        });
        dialogWidgetList.add(buttonDialogWidget);
        privacyCheckDialogConfig.widgets = dialogWidgetList;
        uiConfig.privacyCheckDialogConfig = privacyCheckDialogConfig;

        uiConfig.setIsPrivacyViewDarkMode = false; //协议页面是否支持暗黑模式

        //弹框模式
        // JVPopViewConfig popViewConfig = JVPopViewConfig();
        // popViewConfig.width = (screenWidth - 100.0).toInt();
        // popViewConfig.height = (screenHeight - 150.0).toInt();

        // uiConfig.popViewConfig = popViewConfig;

        /// 添加自定义的 控件 到授权界面
        List<JVCustomWidget> widgetList = [];

        final String text_widgetId = "jv_add_custom_text"; // 标识控件 id
        JVCustomWidget textWidget =
            JVCustomWidget(text_widgetId, JVCustomWidgetType.textView);
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
        jverify.addClikWidgetEventListener(text_widgetId, (eventId) {
          print("receive listener - click widget event :$eventId");
          if (text_widgetId == eventId) {
            print("receive listener - 点击【新加 text】");
          }
        });
        widgetList.add(textWidget);

        final String btn_widgetId = "jv_add_custom_button"; // 标识控件 id
        JVCustomWidget buttonWidget =
            JVCustomWidget(btn_widgetId, JVCustomWidgetType.button);
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
        jverify.addClikWidgetEventListener(btn_widgetId, (eventId) {
          print("receive listener - click widget event :$eventId");
          if (btn_widgetId == eventId) {
            print("receive listener - 点击【新加 button】");
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

        /// 步骤 2：调用一键登录接口
        jverify.loginAuthSyncApi2(
            autoDismiss: true,
            enableSms: false,
            loginAuthcallback: (event) {
              setState(() {
                _hideLoading();
                _result = "获取返回数据：[${event.code}] message = ${event.message}";
              });
              print(
                  "获取到 loginAuthSyncApi 接口返回数据，code=${event.code},message = ${event.message},operator = ${event.operator}");
            });
      } else {
        setState(() {
          _hideLoading();
          _result = "[2016],msg = 当前网络环境不支持认证";
        });

        /* 弹框模式
        JVPopViewConfig popViewConfig = JVPopViewConfig();
        popViewConfig.width = (screenWidth - 100.0).toInt();
        popViewConfig.height = (screenHeight - 150.0).toInt();

        uiConfig.popViewConfig = popViewConfig;
        */

        /*

        /// 方式二：使用异步接口 （如果想使用异步接口，则忽略此步骤，看方式二）

        /// 先，执行异步的一键登录接口
        jverify.loginAuth(true).then((map) {

          /// 再，在回调里获取 loginAuth 接口异步返回数据（如果是通过添加 JVLoginAuthCallBackListener 监听来获取返回数据，则忽略此步骤）
          int code = map[f_code_key];
          String content = map[f_msg_key];
          String operator = map[f_opr_key];
          setState(() {
           _hideLoading();
            _result = "接口异步返回数据：[$code] message = $content";
          });
          print("通过接口异步返回，获取到 loginAuth 接口返回数据，code=$code,message = $content,operator = $operator");
        });

        */
      }
    });
  }

  /// HarmonyOS 最小可运行配置。图片名称来自 example/ohos 的资源目录。
  void _loginAuthOnHarmonyOS() {
    final JVCustomWidget helpWidget =
        JVCustomWidget(_ohosHelpWidgetId, JVCustomWidgetType.button)
          ..title = '登录遇到问题？'
          ..titleColor = Colors.blue.value
          ..backgroundColor = const Color(0xFFEAF4FF).value
          ..left = 30
          ..top = 80
          ..width = 190
          ..height = 36
          ..harmonyBorderRadius = 18
          ..isClickEnable = true
          ..textAlignment = JVTextAlignmentType.center
          ..harmonyAction = JVHarmonyCustomWidgetAction.callback
          ..harmonyToastText = '已点击“登录遇到问题”';
    final JVCustomWidget dialogCancelWidget =
        JVCustomWidget(_ohosDialogCancelWidgetId, JVCustomWidgetType.button)
          ..title = '取消'
          ..titleColor = Colors.blue.value
          ..backgroundColor = const Color(0xFFEAF2FF).value
          // The dialog custom view is centered by ArkUI Stack including its
          // margins. top=130 places this 36 vp button about 12 vp below the
          // SDK's 40 vp login button whose top margin is 30.
          ..left = 0
          ..top = 130
          ..width = 100
          ..height = 36
          ..harmonyBorderRadius = 18
          ..harmonyAction = JVHarmonyCustomWidgetAction.closeCheckDialog;
    final JVCustomWidget imageWidget =
        JVCustomWidget(_ohosImageWidgetId, JVCustomWidgetType.image)
          ..backgroundColor = Colors.white.value
          ..width = 36
          ..height = 36
          ..left = 235
          ..top = 80
          ..harmonyImage = JVHarmonyImageConfig(
            name: 'app_icon',
            fit: JVHarmonyImageFit.contain,
          )
          ..harmonyAction = JVHarmonyCustomWidgetAction.callback
          ..harmonyToastText = '已点击自定义图片';
    final JVPrivacyCheckDialogConfig privacyDialog =
        JVPrivacyCheckDialogConfig()
          ..width = 300
          ..height = 240
          ..title = '同意并继续'
          ..titleTextSize = 14
          ..titleTextColor = Colors.black.value
          ..contentTextGravity = 'left'
          ..contentTextSize = 11
          ..contentTextPaddingT = 30
          ..contentTextPaddingL = 10
          ..contentTextPaddingR = 15
          ..logBtnText = '同意并继续'
          ..logBtnTextColor = Colors.white.value
          ..logBtnWidth = 200
          ..logBtnHeight = 40
          ..logBtnMarginL = 25
          ..logBtnMarginR = 25
          ..logBtnMarginT = 30
          ..privacyBackgroundColor = Colors.white.value
          ..widgets = <JVCustomWidget>[dialogCancelWidget];
    final JVHarmonyCMUIConfig cmConfig = JVHarmonyCMUIConfig()
      ..fitsSystemWindows = true
      // 移动 SDK 默认状态栏为品牌蓝色；示例改为透明背景并使用深色内容，
      // 与白色授权页融为一体，同时保留时间、信号和电量的可读性。
      ..systemBar = (JVHarmonySystemBarConfig()
        ..statusBarColor = '#00000000'
        ..statusBarContentColor = '#FF000000'
        ..isStatusBarLightIcon = false)
      ..numberMargin = JVHarmonyMargin(top: 100)
      // 移动号码 Text 默认在固定宽度内左对齐；缩到内容宽度并把
      // 整个节点锚定到容器中线，保证视觉中心而不只是控件框居中。
      ..numberWidth = 140
      ..numberHeight = 36
      ..numberAlignRule = (JVHarmonyAlignRule()
        ..middle = JVHarmonyHorizontalRule(
            '__container__', JVHarmonyHorizontalAlign.center))
      // 登录按钮相对号码向下定位，避免单独设置 top margin 时被解释为
      // 相对容器顶部。120 vp 比 SDK 默认位置略低，同时避开底部协议区。
      ..loginBtnMargin = JVHarmonyMargin(top: 120)
      ..loginBtnAlignRule = (JVHarmonyAlignRule()
        ..middle = JVHarmonyHorizontalRule(
            '__container__', JVHarmonyHorizontalAlign.center)
        ..top =
            JVHarmonyVerticalRule('phoneNum', JVHarmonyVerticalAlign.bottom))
      // 未勾选协议时移动 SDK 会使用独立的 disabled 样式。示例使用
      // 纯色样式，避免把 SDK 源码 Demo 中带说明文字的测试图当成按钮背景。
      ..loginBtnDisabledTextColor = Colors.white.value
      ..loginBtnDisabledColor = const Color(0xFF9BA8B5).value
      ..loginBtnDisabledBorderColor = Colors.transparent.value
      ..loginBtnDisabledBorderWidth = 0
      ..checkBoxSize = const JVHarmonySize(18, 20)
      ..checkBoxLocation = 0
      // 与移动 SDK 源码 Demo 一致：checkbox 固定在容器底部，
      // 协议文本再以 clause_checkBox 为锚点做垂直居中。
      ..checkBoxAlignRule = (JVHarmonyAlignRule()
        ..left = JVHarmonyHorizontalRule(
            '__container__', JVHarmonyHorizontalAlign.start)
        ..bottom = JVHarmonyVerticalRule(
            '__container__', JVHarmonyVerticalAlign.bottom))
      ..clauseAlignRule = (JVHarmonyAlignRule()
        ..middle = JVHarmonyHorizontalRule(
            '__container__', JVHarmonyHorizontalAlign.center)
        ..center = JVHarmonyVerticalRule(
            'clause_checkBox', JVHarmonyVerticalAlign.center))
      ..clauseMargin = JVHarmonyMargin(top: 9)
      ..privacyMarginRight = 20
      ..webCloseImgWidth = 30
      ..webCloseImgHeight = 30
      ..webCloseImgMargin = JVHarmonyMargin(left: 16, top: 52)
      ..webCloseImgAlignRule = (JVHarmonyAlignRule()
        ..left = JVHarmonyHorizontalRule(
            '__container__', JVHarmonyHorizontalAlign.start)
        ..top =
            JVHarmonyVerticalRule('__container__', JVHarmonyVerticalAlign.top))
      ..clauses = <JVHarmonyCMClause>[
        JVHarmonyCMClause(
          text: '登录即同意',
          fontSize: 13,
          fontColor: Colors.grey.value,
        ),
        JVHarmonyCMClause(
          text: '《&&Clause&&》',
          fontSize: 13,
          fontColor: Colors.blue.value,
          isProtocol: true,
        ),
        JVHarmonyCMClause(
          text: '《用户协议》',
          url: 'https://www.jiguang.cn/license/privacy',
          fontSize: 13,
          fontColor: Colors.blue.value,
          isProtocol: true,
        ),
      ]
      // 透明自定义层保留移动 SDK 默认号码和登录按钮，只保留一个
      // 有明确帮助用途的图片 Button；点击同时回调 widget ID 并显示 Toast。
      ..loginPage = JVHarmonyCMLoginPageConfig(
        backgroundColor: 0x00000000,
        widgets: <JVHarmonyCMLoginPageWidget>[
          JVHarmonyCMLoginPageWidget(
            id: _ohosCmImageButtonWidgetId,
            anchor: 'loginBtn',
            type: JVCustomWidgetType.button,
            image: JVHarmonyImageConfig(
              name: 'app_icon',
              fit: JVHarmonyImageFit.contain,
            ),
            width: 44,
            height: 44,
            backgroundColor: Colors.transparent.value,
            borderRadius: 22,
            margin: JVHarmonyMargin(top: 16),
            action: JVHarmonyCustomWidgetAction.callback,
            toastText: '已点击自定义帮助按钮',
          ),
          JVHarmonyCMLoginPageWidget(
            id: _ohosCmCloseWidgetId,
            anchor: _ohosCmImageButtonWidgetId,
            type: JVCustomWidgetType.button,
            text: '关闭授权页',
            width: 140,
            height: 36,
            borderRadius: 18,
            // SDK loadingProgress 位于登录按钮下方；采用源码 Demo 的
            // 80 vp 间距，把可点击关闭按钮放到 loading 区域之后。
            margin: JVHarmonyMargin(top: 80),
            action: JVHarmonyCustomWidgetAction.dismissLoginAuth,
          ),
        ],
      )
      ..loginConfirmDialog = JVHarmonyCMLoginConfirmDialogConfig(
        message: '确认使用本机号码登录？',
      );

    final JVUIConfig uiConfig = JVUIConfig()
      ..authBackgroundImage = 'jverify_login_test_back'
      ..navReturnImgPath = 'jverify_nav_close'
      ..privacyNavReturnBtnImage = 'umcsdk_return_bg'
      ..navReturnBtnHidden = false
      ..navReturnBtnOffsetX = 10
      ..navReturnBtnOffsetY = 10
      ..harmonyReturnBtnWidth = 30
      ..harmonyReturnBtnHeight = 30
      ..harmonyAuthPageFontFollowSystem = false
      // 不显式设置安全区时，插件会读取 HarmonyOS 系统避让区。
      // SDK 源码使用顺序 Column：Logo 负责首段下移，
      // 号码/slogan/登录按钮的 OffsetY 是相对上一控件的间距。
      ..logoHidden = false
      ..logoImgPath = 'app_icon'
      ..logoWidth = 80
      ..logoHeight = 80
      ..logoOffsetX = -1
      ..logoOffsetY = 150
      ..numberColor = Colors.black.value
      ..numberSize = 24
      ..numFieldOffsetX = -1
      ..numFieldOffsetY = 7
      ..numberFieldWidth = 220
      ..numberFieldHeight = 36
      ..sloganTextColor = Colors.grey.value
      ..sloganTextSize = 12
      ..sloganOffsetX = -1
      ..sloganOffsetY = 7
      ..logBtnText = '本机号码一键登录'
      ..logBtnTextColor = Colors.white.value
      ..logBtnTextSize = 15
      ..logBtnOffsetX = -1
      ..logBtnOffsetY = 22
      ..logBtnWidth = 270
      ..logBtnHeight = 48
      ..harmonyLogBtnBackgroundColor = Colors.blue.value
      ..harmonyLogBtnBorderRadius = 24
      ..privacyState = false
      ..privacyText = <String>['登录即同意', '，并使用本机号码登录']
      ..privacyTextSize = 12
      ..privacyCheckboxSize = 18
      ..privacyCheckboxInCenter = true
      ..privacyOffsetX = 10
      ..privacyMarginR = 20
      ..privacyOffsetY = 100
      ..harmonyPrivacyHintToastText = '请勾选隐私协议'
      ..clauseName = '用户协议'
      ..clauseUrl = 'https://www.jiguang.cn/license/privacy'
      ..privacyCheckDialogConfig = privacyDialog
      ..harmonyCmUIConfig = cmConfig;

    debugPrint('[JVerify][OHOS] apply native authorization UI');
    jverify.setCustomAuthorizationView(false, uiConfig,
        widgets: <JVCustomWidget>[helpWidget, imageWidget]);
    debugPrint('[JVerify][OHOS] request loginAuth with mounted NavPathStack');
    jverify.loginAuthSyncApi2(
      autoDismiss: true,
      enableSms: false,
      loginAuthcallback: (event) {
        debugPrint(
            '[JVerify][OHOS] login callback code=${event.code}, operator=${event.operator}');
        if (!mounted) {
          return;
        }
        setState(() {
          _hideLoading();
          _result = event.code == 6000
              ? '鸿蒙一键登录成功：[${event.code}] token=${event.message}'
              : '鸿蒙一键登录失败：[${event.code}] ${event.message}';
        });
      },
      pageEventCallback: (event) {
        debugPrint(
            '[JVerify][OHOS] auth page event code=${event.code}, message=${event.message}');
      },
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // 初始化 SDK 之前添加监听
    jverify.addSDKSetupCallBackListener((JVSDKSetupEvent event) {
      print("receive sdk setup call back event :${event.toMap()}");
    });

    jverify.setDebugMode(true); // 打开调试模式
    jverify.setCollectionAuth(true);
    jverify.setup(
        appKey: _platformAppKey,
        channel:
            "developer-default"); // Android 使用原生配置；iOS/HarmonyOS 使用 Dart AppKey
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    /// 授权页面点击时间监听
    jverify.addAuthPageEventListener(_authPageEventListener);
    jverify.addClikWidgetEventListener(_ohosHelpWidgetId, (String eventId) {
      debugPrint('[JVerify][OHOS] custom auth widget clicked: $eventId');
    });
    jverify.addClikWidgetEventListener(_ohosDialogCancelWidgetId,
        (String eventId) {
      debugPrint('[JVerify][OHOS] privacy dialog widget clicked: $eventId');
    });
    jverify.addClikWidgetEventListener(_ohosImageWidgetId, (String eventId) {
      debugPrint('[JVerify][OHOS] custom image clicked: $eventId');
    });
    jverify.addClikWidgetEventListener(_ohosCmImageButtonWidgetId,
        (String eventId) {
      debugPrint('[JVerify][OHOS] CM image button clicked: $eventId');
    });
    jverify.addClikWidgetEventListener(_ohosCmCloseWidgetId, (String eventId) {
      debugPrint('[JVerify][OHOS] CM close button clicked: $eventId');
    });
  }

  @override
  void dispose() {
    jverify.removeAuthPageEventListener(_authPageEventListener);
    jverify.removeClikWidgetEventListener(_ohosHelpWidgetId);
    jverify.removeClikWidgetEventListener(_ohosImageWidgetId);
    jverify.removeClikWidgetEventListener(_ohosDialogCancelWidgetId);
    jverify.removeClikWidgetEventListener(_ohosCmImageButtonWidgetId);
    jverify.removeClikWidgetEventListener(_ohosCmCloseWidgetId);
    jverify.addSDKSetupCallBackListener(null);
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('f_result_key', f_result_key));
  }
}

/// 封装 按钮
class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? title;

  const CustomButton({@required this.onPressed, this.title});

  @override
  Widget build(BuildContext context) {
    return new TextButton(
      onPressed: onPressed,
      child: new Text("$title"),
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.white),
        overlayColor: MaterialStateProperty.all(Color(0xff888888)),
        backgroundColor: MaterialStateProperty.all(Color(0xff585858)),
        padding: MaterialStateProperty.all(EdgeInsets.fromLTRB(10, 5, 10, 5)),
      ),
    );
  }
}
