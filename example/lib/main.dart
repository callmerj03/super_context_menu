import 'package:flutter/material.dart';
import 'package:super_context_menu/super_context_menu.dart';

void main() async {
  runApp(const MainApp());
}

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

class _BaseContextMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ContextMenuWidget(
      child: Item(
        child: Text('Base Context Menu' 'Base Context Menu' 'Base'),
      ),
      menuProvider: (_) {
        return Menu(
          children: [
            // MenuAction(
            //   title: 'Menu Item 1',
            //   callback: () {},
            // ),
            // MenuAction(title: 'Menu Item 2', callback: () {}),
            // MenuAction(title: 'Menu Item 3', callback: () {}),
            // MenuSeparator(),
            // Menu(title: 'Submenu', children: [
            //   MenuAction(title: 'Submenu Item 1', callback: () {}),
            //   MenuAction(title: 'Submenu Item 2', callback: () {}),
            //   Menu(title: 'Nested Submenu', children: [
            //     MenuAction(title: 'Submenu Item 1', callback: () {}),
            //     MenuAction(title: 'Submenu Item 2', callback: () {}),
            //   ]),
            // ]),
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
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return Container(
              margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Align(alignment: index.isEven ? Alignment.centerLeft : Alignment.bottomRight, child: _BaseContextMenu()),
            );
          },
          // child: Column(
          //   crossAxisAlignment: CrossAxisAlignment.stretch,
          //   children: <Widget>[
          //     Section(
          //       description:
          //       const Text('Base context menu, without drag & drop.'),
          //       child: _BaseContextMenu(),
          //     ),
          //     Section(
          //       description:
          //       const Text('Base context menu,z with drag & drop.'),
          //       child: _BaseContextMenuWithDrag(),
          //     ),
          //     Section(
          //       description: const Text(
          //           'Complex context menu, with custom lift, preview and drag builders (mobile only).'),
          //       child: _ComplexContextMenu(),
          //     ),
          //     Section(
          //       description:
          //       const Text('Deferred menu preview (mobile only).'),
          //       child: _DeferredMenuPreview(),
          //     ),
          //   ].intersperse(const _Separator()).toList(growable: false),
          // ),
        )

            // _PageLayout(
            //   itemZone:
            //   SingleChildScrollView(
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.stretch,
            //       children: <Widget>[
            //         Section(
            //           description:
            //           const Text('Base context menu, without drag & drop.'),
            //           child: _BaseContextMenu(),
            //         ),
            //         Section(
            //           description:
            //           const Text('Base context menu, with drag & drop.'),
            //           child: _BaseContextMenuWithDrag(),
            //         ),
            //         Section(
            //           description: const Text(
            //               'Complex context menu, with custom lift, preview and drag builders (mobile only).'),
            //           child: _ComplexContextMenu(),
            //         ),
            //         Section(
            //           description:
            //           const Text('Deferred menu preview (mobile only).'),
            //           child: _DeferredMenuPreview(),
            //         ),
            //       ].intersperse(const _Separator()).toList(growable: false),
            //     ),
            //   ),
            //   dropZone:  _DropZone(),
            // ),
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
