import 'package:flutter/cupertino.dart';

class EmojiActionModel{

  Widget? view;
  Function(dynamic)? callback;

  EmojiActionModel({required this.view, required this.callback,});

}