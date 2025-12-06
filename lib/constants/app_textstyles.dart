import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyles{
  static TextStyle monB18({Color? color}) => TextStyle(
    fontFamily: "monB",
    fontSize: 18.sp,
    color: color ?? Colors.black,
  );

  static TextStyle monB24({Color? color}) => TextStyle(
    fontFamily: "monB",
    fontSize: 24.sp,
    color: color ?? Colors.black,
  );

  static TextStyle monB32({Color? color}) => TextStyle(
    fontFamily: "monB",
    fontSize: 32.sp,
    color: color ?? Colors.black,
  );

  static TextStyle monB14({Color? color}) => TextStyle(
    fontFamily: "monB",
    fontSize: 14.sp,
    color: color ?? Colors.black,
  );

  static TextStyle monSB20({Color? color}) => TextStyle(
    fontFamily: "monSB",
    fontSize: 20.sp,
    color: color ?? Colors.black,
  );

  static TextStyle monSB16({Color? color}) => TextStyle(
    fontFamily: "monSB",
    fontSize: 16.sp,
    color: color ?? Colors.black,
  );

  static TextStyle monMd14({Color? color}) => TextStyle(
    fontFamily: "monMd",
    fontSize: 14.sp,
    color: color ?? Colors.black,
  );

  static TextStyle monMd14Underlined({Color? color}) => TextStyle(
    fontFamily: "monMd",
    decoration: TextDecoration.underline,
    decorationColor: color,
    fontSize: 14.sp,
    color: color ?? Colors.black,
  );


  static TextStyle monMd12({Color? color}) => TextStyle(
    fontFamily: "monMd",
    fontSize: 12.sp,
    color: color ?? Colors.black,
  );

  static TextStyle monReg16({Color? color}) => TextStyle(
    fontFamily: "monReg",
    fontSize: 16.sp,
    color: color ?? Colors.black,
  );

  static TextStyle monReg14({Color? color}) => TextStyle(
    fontFamily: "monReg",
    fontSize: 14.sp,
    color: color ?? Colors.black,
  );

  static TextStyle monMd16({Color? color}) => TextStyle(
    fontFamily: "monMd",
    fontSize: 16.sp,
    color: color ?? Colors.black,
  );

  static TextStyle robMd14({Color? color}) => TextStyle(
    fontFamily: "robMd",
    fontSize: 14.sp,
    decoration: TextDecoration.underline,
    decorationColor: color,
    color: color ?? Colors.black,
  );

  static TextStyle robReg12({Color? color}) => TextStyle(
    fontFamily: "robReg",
    fontSize: 12.sp,
    color: color ?? Colors.black,
  );

  static TextStyle popMd14({Color? color}) => TextStyle(
    fontFamily: "popMd",
    fontSize: 14.sp,
    color: color ?? Colors.black,
  );
  static TextStyle popReg14({Color? color}) => TextStyle(
    fontFamily: "popReg",
    fontSize: 14.sp,
    color: color ?? Colors.black,
  );
  static TextStyle popReg16({Color? color}) => TextStyle(
    fontFamily: "popReg",
    fontSize: 16.sp,
    color: color ?? Colors.black,
  );
  static TextStyle popMd18({Color? color}) => TextStyle(
    fontFamily: "popMd",
    fontSize: 18.sp,
    color: color ?? Colors.black,
  );

  static TextStyle popMd16({Color? color}) => TextStyle(
    fontFamily: "popMd",
    fontSize: 16.sp,
    color: color ?? Colors.black,
  );

  static TextStyle popMd20({Color? color}) => TextStyle(
    fontFamily: "popMd",
    fontSize: 20.sp,
    color: color ?? Colors.black,
  );

  static TextStyle popReg16Underlined({Color? color}) => TextStyle(
    fontFamily: "popReg",
    fontSize: 16.sp,
    decoration: TextDecoration.underline,
    decorationColor: color,
    color: color ?? Colors.black,
  );
}