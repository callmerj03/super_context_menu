import 'package:flutter/material.dart';
import 'package:super_context_menu/super_context_menu.dart';

void main() async {
  runApp(MainApp());
}

bool isReturnAllowed = false;

class Item extends StatelessWidget {
  const Item({
    super.key,
    this.color = Colors.blue,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final EdgeInsets padding;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.description,
    required this.child,
  });

  final Widget description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0),
            child: description,
          ),
        ],
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  void backmanage(bool value) {
    isReturnAllowed = value;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WillPopScope(
        onWillPop: () async {
          print(">>>>|||| ${isReturnAllowed}");
          return false;
        },
        child: Scaffold(
          body: SafeArea(child: ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Align(
                    alignment: index.isEven ? Alignment.centerLeft : Alignment.bottomRight,
                    child: ContextMenuWidget(
                      child: Item(
                        child: Text('Base Context Menu' 'Base Context Menu' 'Base'),
                      ),
                      menuProvider: (_) {
                        isReturnAllowed = false;
                        print("poisaaaa${isReturnAllowed}");

                        return Menu(
                          children: [
                            MenuAction(
                              title: 'Menu Item 1',
                              callback: () {},
                            ),
                          ],
                        );
                      },
                      emojiList: [
                        {'emoji': '👍'},
                        {'emoji': '👍'},
                        {'emoji': '👍'},
                        {'emoji': '👍'},
                        {'emoji': null},
                      ],
                      emojiClick: (String) {},
                      backmanage: (value) {
                        isReturnAllowed = value;
                        print("paissssaaa>>>> ${isReturnAllowed}");
                      },
                    )),
              );
            },
          )),
        ),
      ),
    );
  }
}

extension IntersperseExtensions<T> on Iterable<T> {
  Iterable<T> intersperse(T element) sync* {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      yield iterator.current;
      while (iterator.moveNext()) {
        yield element;
        yield iterator.current;
      }
    }
  }
}
