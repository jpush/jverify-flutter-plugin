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
      child: Material(
        ///背景透明
        color: Colors.black54,

        ///保证控件居中效果
        child: Center(
          ///弹框大小
          child: SizedBox(
            width: 120.0,
            height: 120.0,
            child: Container(
              ///弹框背景和圆角
              decoration: const ShapeDecoration(
                color: Color(0xffffffff),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 20.0,
                    ),
                    child: Text(
                      "加载中",
                      style: TextStyle(fontSize: 16.0),
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
