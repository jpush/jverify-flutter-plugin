import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:jverify/jverify.dart';




void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  /// 统一 key
  final String f_result_key = "result";
  /// 错误码
  final  String  f_code_key = "code";
  /// 回调的提示信息，统一返回 flutter 为 message
  final  String  f_msg_key  = "message";
  /// 运营商信息
  final  String  f_opr_key  = "operator";


  String _platformVersion = 'Unknown';
  String _result = "token=";
  var controllerPHone = new TextEditingController();
  final Jverify jverify = new Jverify();
  bool _loading = false;
  String _token;


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
        body: ModalProgressHUD(child: _buildContent(), inAsyncCall: _loading),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      widthFactor: 2,
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
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new CustomButton(
                    onPressed: (){
                      isInitSuccess();
                    },
                    title: "SDK 是否初始化成功"
                ),
                new Text("   "),
                new CustomButton(
                  onPressed: (){
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
            child: TextField(
              autofocus: false,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                  hintText: "手机号码", hintStyle: TextStyle(color: Colors.black)),
              controller: controllerPHone,
            ),
            margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
          ),
          new Container(
            child: SizedBox(
              child: new CustomButton(
                onPressed: () {
                  verifyNumber();
                },
                title: "验证号码",
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
                title: "登录预号",
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
          )
        ],
        mainAxisAlignment: MainAxisAlignment.start,
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
        }else {
          _result = "sdk 初始换失败";
        }
      });
    });
  }

  /// 判断当前网络环境是否可以发起认证
  void checkVerifyEnable() {
    jverify.checkVerifyEnable().then((map) {
      bool result = map[f_result_key];
      setState(() {
        if (result) {
          _result = "当前网络环境【支持认证】！";
        }else {
          _result = "当前网络环境【不支持认证】！";
        }
      });
    });
  }


  /// 获取号码认证token
  void getToken() {
    setState(() {
      _loading = true;
    });
    jverify.checkVerifyEnable().then((map) {
      bool result = map[f_result_key];
      if (result) {
        jverify.getToken().then((map) {
          int code = map[f_code_key];
          _token = map[f_msg_key];
          String operator = map[f_opr_key];
          setState(() {
            _loading = false;
            _result = "[$code] message = $_token, operator = $operator";
          });
        });
      } else {
        setState(() {
          _loading = false;
          _result = "[2016],msg = 当前网络环境不支持认证";
        });
      }
    });
  }

  /// 发起号码认证，验证手机号码和本机SIM卡号码是否一致
  void verifyNumber() {
    print(controllerPHone.text);
    if (controllerPHone.text == null || controllerPHone.text == "") {
      setState(() {
        _result = "电话号码不能为空";
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    jverify.checkVerifyEnable().then((map) {
      bool result = map[f_result_key];
      if (result) {
        jverify.verifyNumber(controllerPHone.text, token: _token ?? null).then((map) {
          int code = map[f_code_key];
          String content = map[f_msg_key];
          setState(() {
            _loading = false;
            _result = "[$code] message = $content";
          });
        });
      } else {
        setState(() {
          _loading = false;
          _result = "[2016], msg = 当前网络环境不支持认证";
        });
      }
    });
  }

  /// 登录预取号
  void preLogin(){
    setState(() {
      _loading = true;
    });
    jverify.checkVerifyEnable().then((map) {
      bool result = map[f_result_key];
      if (result) {
        jverify.preLogin().then((map) {
          int code = map[f_code_key];
          String message = map[f_msg_key];
          setState(() {
            _loading = false;
            _result = "[$code] message = $message";
          });
        });
      }else {
        setState(() {
          _loading = false;
          _result = "[2016],msg = 当前网络环境不支持认证";
        });
      }
    });
  }

  /// SDK 请求授权一键登录
  void loginAuth() {
    setState(() {
      _loading = true;
    });

    jverify.checkVerifyEnable().then((map) {
      bool result = map[f_result_key];
      if (result) {

        /// 自定义授权的 UI 界面，以下设置的图片必须添加到资源文件里，
        /// android项目将图片存放至drawable文件夹下，可使用图片选择器的文件名,例如：btn_login.xml,入参为"btn_login"。
        /// ios项目存放在 Assets.xcassets。
        JVUIConfig uiConfig = JVUIConfig();
        uiConfig.navColor = Colors.red.value;

        uiConfig.navText = "登录";
        uiConfig.navTextColor = Colors.blue.value;
        //uiConfig.navReturnImgPath = "return_bg";

        uiConfig.logoHidden = false;
        uiConfig.logoOffsetY = 10;
        uiConfig.logoWidth = 90;
        uiConfig.logoHeight = 90;
        uiConfig.logoImgPath = "logo";

        uiConfig.numFieldOffsetY = 120;
        uiConfig.numberColor = Colors.blue.value;

        uiConfig.sloganOffsetY = 150;
        uiConfig.sloganTextColor = Colors.black.value;

        uiConfig.logBtnOffsetY = 300;
        uiConfig.logBtnText = "登录按钮";
        uiConfig.logBtnTextColor = Colors.brown.value;
        //uiConfig.loginBtnNormalImage = "login_btn_normal";
        //uiConfig.loginBtnPressedImage = "login_btn_press";
        //uiConfig.loginBtnUnableImage = "login_btn_unable";

        //设置默认勾选
        uiConfig.privacyState = true;
        //uiConfig.checkedImgPath = "check_image";
        //uiConfig.uncheckedImgPath = "uncheck_image";
        uiConfig.privacyOffsetY = 80;

        uiConfig.clauseName = "协议1";
        uiConfig.clauseUrl = "http://www.baidu.com";
        uiConfig.clauseBaseColor = Colors.black.value;

        uiConfig.clauseNameTwo = "协议二";
        uiConfig.clauseUrlTwo = "http://www.hao123.com";
        uiConfig.clauseColor = Colors.red.value;



        /// 添加自定义的 控件 到授权界面
        List<JVCustomWidget>widgetList = [];

        /*
        final String text_widgetId = "jv_add_custom_text";// 标识控件 id
        JVCustomWidget textWidget = JVCustomWidget(text_widgetId, JVCustomWidgetType.textView);
        textWidget.title = "新加 text view 控件";
        textWidget.left = 20;
        textWidget.top = 360 ;
        textWidget.width = 200;
        textWidget.height  = 40;
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

        final String btn_widgetId = "jv_add_custom_button";// 标识控件 id
        JVCustomWidget buttonWidget = JVCustomWidget(btn_widgetId, JVCustomWidgetType.button);
        buttonWidget.title = "新加 button 控件";
        buttonWidget.left = 100;
        buttonWidget.top = 400;
        buttonWidget.width = 150;
        buttonWidget.height  = 40;
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
        */


        /// 调用接口设置 UI
         jverify.setCustomAuthViewAllWidgets(uiConfig);

        /// 开始一键登录
        jverify.loginAuth(true).then((map) {
          int code = map[f_code_key];
          String content = map[f_msg_key];
          setState(() {
            _loading = false;
            _result = "[$code] message = $content";
          });
        });

      } else {
        setState(() {
          _loading = false;
          _result = "[2016],msg = 当前网络环境不支持认证";
        });
      }
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    jverify.setDebugMode(false); // 打开调试模式
    jverify.setup(
        appKey: "你自己应用的 AppKey",//"你自己应用的 AppKey",
        channel: "devloper-default"); // 初始化sdk,  appKey 和 channel 只对ios设置有效
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }
}

/// 封装 按钮
class CustomButton extends StatelessWidget {

  final VoidCallback onPressed;
  final String title;

  const CustomButton({@required this.onPressed, this.title});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new FlatButton(
      onPressed: onPressed,
      child: new Text("$title"),
      color: Color(0xff585858),
      highlightColor: Color(0xff888888),
      splashColor: Color(0xff888888),
      textColor: Colors.white,
      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
    );
  }
}