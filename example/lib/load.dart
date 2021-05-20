import 'package:flutter/material.dart';

class LoadingDialog {
  static late BuildContext _context;

  static void show(BuildContext context) {
    _context = context;
    Navigator.push(_context, DialogRouter(_LoadingDialog()));
  }

  static void hidden() {
    if (Navigator.canPop(_context)) {
      Navigator.pop(_context);
    }
  }
}

class DialogRouter extends PageRouteBuilder {
  final Widget page;

  DialogRouter(this.page)
      : super(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) => page,
        );
}

class _LoadingDialog extends Dialog {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: new Material(
        ///背景透明
        color: Colors.black54,

        ///保证控件居中效果
        child: new Center(
          ///弹框大小
          child: new SizedBox(
            width: 120.0,
            height: 120.0,
            child: new Container(
              ///弹框背景和圆角
              decoration: ShapeDecoration(
                color: Color(0xffffffff),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                ),
              ),
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new CircularProgressIndicator(),
                  new Padding(
                    padding: const EdgeInsets.only(
                      top: 20.0,
                    ),
                    child: new Text(
                      "加载中",
                      style: new TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
