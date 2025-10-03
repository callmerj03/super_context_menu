import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_context_menu/super_context_menu.dart';
import 'package:super_context_menu/super_drag_and_drop/src/drag_configuration.dart';
import 'package:super_context_menu/super_drag_and_drop/src/draggable_widget.dart';
import 'package:super_context_menu/super_drag_and_drop/src/model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
                margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Align(
                    alignment: index.isEven ? Alignment.centerLeft : Alignment.bottomRight,
                    child: DragItemWidget(
                      allowedOperations: () => [DropOperation.copy],
                      dragItemProvider: (_) => DragItem(localData: 'LocalDragData'),
                      child: DraggableWidget(
                        child: ContextMenuWidget(
                          menuProvider: (_) {
                            isReturnAllowed = false;

                            return Menu(
                              children: [
                                MenuAction(
                                  title: 'Menu Item 1',
                                  callback: () async {

                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setString('testKey', 'hello');
                                    print("Prefs test value: ${prefs.getString('testKey')}");

                                  },
                                ),
                              ],
                            );
                          },
                          emojiList: const [
                            {'emoji': '👍'},
                            {'emoji': '❤️'},
                            {'emoji': '🔥'},
                            {'emoji': '✨'},
                            // {'emoji': null},
                          ],
                          emojiClick: (String) {},
                          backmanage: (value) {
                            isReturnAllowed = value;
                            print("paissssaaa>>>> ${isReturnAllowed}");
                          },
                          isDarkMode: false,
                          child: const Item(
                            child: Text('Base1 Context Menu' 'Base Context Menu' 'Base'),
                          ),
                        ),
                      ),
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
