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
  String _platformVersion = 'Unknown';
  String _result  = "token=";
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
        body: ModalProgressHUD(
            child: _buildContent(),
            inAsyncCall: _loading
        ),
      ),
    );
  }

  Widget _buildContent(){
    return Center(widthFactor: 2,
      child: new Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(30),
            child: Text(_result),
            width: 300,
            height: 100,
          ),
          new Container(
            child: SizedBox(
              child: new FlatButton(
                onPressed: (){
                  getToken();
                },
                child: new Text("获取Token"),
                color: Color(0xff585858),
                highlightColor: Color(0xff888888),
                splashColor: Color(0xff888888),
                textColor: Colors.white,
                padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
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
                  hintText: "手机号码",
                  hintStyle: TextStyle(color: Colors.black)
              ),
              controller: controllerPHone,
            ),
            margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
          ),
          new Container(
            child: SizedBox(
              child: new FlatButton(
                onPressed: (){
                  verifyNumber();
                },
                child: new Text("验证号码"),
                color: Color(0xff585858),
                highlightColor: Color(0xff888888),
                splashColor: Color(0xff888888),
                textColor: Colors.white,
                padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
              ),
              width: double.infinity,
            ),
            margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
          ),
          new Container(
            child: SizedBox(
              child: new FlatButton(
                onPressed: (){
                  loginAuth();
                },
                child: new Text("一键登录"),
                color: Color(0xff585858),
                highlightColor: Color(0xff888888),
                splashColor: Color(0xff888888),
                textColor: Colors.white,
                padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
              ),
              width: double.infinity,
            ),
            margin: EdgeInsets.fromLTRB(40, 5, 40, 5),
          )

        ],
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void getToken(){
    setState(() {
      _loading = true;
    });
    jverify.checkVerifyEnable().then((map){
      bool result = map["result"];
      if(result){
        jverify.getToken().then((map){
          int code = map["code"];
          _token = map["content"];
          String operator = map["operator"];
          setState(() {
            _loading = false;
            _result = "[$code]message=$_token, operator=$operator";
          });
        });
      }else{
        setState(() {
          _loading = false;
          _result = "[2016],msg = 当前网络环境不支持认证";
        });
      }
    });
  }

  void verifyNumber(){
    print(controllerPHone.text);
    if(controllerPHone.text == null || controllerPHone.text == ""){
      setState(() {
        _result = "电话号码不能为空";
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    jverify.checkVerifyEnable().then((map){
      bool result = map["result"];
      if(result){
        jverify.verifyNumber(controllerPHone.text,token: _token).then((map){
          int code = map["code"];
          String content = map["content"];
          String operator = map["operator"];
          setState(() {
            _loading = false;
            _result = "[$code]message=$content, operator=$operator";
          });
        });
      }else{
        setState(() {
          _loading = false;
          _result = "[2016],msg = 当前网络环境不支持认证";
        });
      }
    });
  }

  void loginAuth(){
    setState(() {
      _loading = true;
    });
    jverify.checkVerifyEnable().then((map){
      bool result = map["result"];
      if(result){
        jverify.setCustomUI(logoImgPath: "logo",logoWidth: 90,logoHeight: 90,navColor: Colors.red.value,navText: "登录",navTextColor: Colors.blue.value,navReturnImgPath: "return_bg"
          ,checkedImgPath: "check_image",uncheckedImgPath: "uncheck_image",loginBtnNormalImage: "login_btn_normal",loginBtnPressedImage: "login_btn_press",
            loginBtnUnableImage: "login_btn_unable",clauseBaseColor: Colors.red.value,clauseName: "协议一",clauseUrl: "http://www.baidu.com",clauseNameTwo: "协议二",clauseUrlTwo: "http://www.hao123.com",
          logBtnOffsetY: 300,logBtnText: "登录按钮",logBtnTextColor: Colors.green.value,numberColor: Colors.blue.value,logoHidden: false,logoOffsetY: 10,numFieldOffsetY: 100,clauseColor: Colors.black.value,
          privacyOffsetY: 100,sloganOffsetY: 150,sloganTextColor: Colors.black.value);
        jverify.loginAuth().then((map){
          int code = map["code"];
          String content = map["content"];
          String operator = map["operator"];
          setState(() {
            _loading = false;
            _result = "[$code]message=$content, operator=$operator";
          });
        });
      }else{
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
    jverify.setDebugMode(true); // 打开调试模式
    jverify.setup(appKey: "你的 AppKey", channel: "devloper-default"); // 初始化sdk,  appKey 和 channel 只对ios设置有效
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }
}
