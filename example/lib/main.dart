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
        jverify.verifyNumber(controllerPHone.text, token: _token).then((map) {
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

        /// 自定义授权 UI 界面
        jverify.setCustomUI(
          navColor: Colors.red.value,
          navText: "登录",
          navTextColor: Colors.blue.value,
          navReturnImgPath: "return_bg",

          logoHidden: false,
          logoOffsetY: 10,
          logoWidth: 90,
          logoHeight: 90,
          logoImgPath: "logo",

          numFieldOffsetY: 120,
          numberColor: Colors.blue.value,

          sloganOffsetY: 150,
          sloganTextColor: Colors.black.value,

          logBtnOffsetY: 300,
          logBtnText: "登录按钮",
          logBtnTextColor: Colors.brown.value,
          loginBtnNormalImage: "login_btn_normal",
          loginBtnPressedImage: "login_btn_press",
          loginBtnUnableImage: "login_btn_unable",

          checkedImgPath: "check_image",
          uncheckedImgPath: "uncheck_image",
          privacyOffsetY: 80,

          clauseName: "协议1",
          clauseUrl: "http://www.baidu.com",
          clauseBaseColor: Colors.black.value,

          clauseNameTwo: "协议二",
          clauseUrlTwo: "http://www.hao123.com",
          clauseColor: Colors.red.value,
        );

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
        appKey: "你自己应用的 AppKey",
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