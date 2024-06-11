import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:super_native_extensions/raw_menu.dart' as raw;
import 'package:flutter/foundation.dart' as foundation;
import 'package:super_native_extensions/widget_snapshot.dart';

import '../super_context_menu.dart';
import 'menu.dart';
import 'menu_internal.dart';
import 'menu_model.dart';
import 'scaffold/mobile/menu_widget_builder.dart';
import 'scaffold/mobile/menu_preview_widget.dart';
import 'scaffold/mobile/menu_stack.dart';
import 'util.dart';

final _keyLift = _SnapshotKey('Lift');
final _keyPreview = _SnapshotKey('Preview');

class MobileContextMenuWidget extends StatefulWidget {
  const MobileContextMenuWidget({
    super.key,
    this.liftBuilder,
    this.previewBuilder,
    this.deferredPreviewBuilder,
    required this.child,
    required this.hitTestBehavior,
    required this.menuProvider,
    this.iconTheme,
    this.destructiveIconTheme,
    required this.contextMenuIsAllowed,
    required this.menuWidgetBuilder,
    required this.emojiList,
    required this.emojiClick,
  }) : assert(previewBuilder == null || deferredPreviewBuilder == null, 'Cannot use both previewBuilder and deferredPreviewBuilder');

  final Widget Function(BuildContext context, Widget child)? liftBuilder;
  final Widget Function(BuildContext context, Widget child)? previewBuilder;
  final DeferredMenuPreview Function(BuildContext context, Widget child, CancellationToken cancellationToken)? deferredPreviewBuilder;

  final HitTestBehavior hitTestBehavior;
  final MenuProvider menuProvider;
  final ContextMenuIsAllowed contextMenuIsAllowed;
  final Widget child;
  final MobileMenuWidgetBuilder menuWidgetBuilder;

  final List<Map> emojiList;
  final Function(String?) emojiClick;

  /// Base icon theme for menu icons. The size will be overridden depending
  /// on platform.
  final IconThemeData? iconTheme;

  /// Icon theme for destructive actions. The size will be overridden depending
  /// on platform.
  final IconThemeData? destructiveIconTheme;

  @override
  State<MobileContextMenuWidget> createState() => _ContextMenuWidgetState();
}

class _ContextMenuWidgetState extends State<MobileContextMenuWidget> {
  OverlayEntry? overlayWidget;

  final _scrollController = ScrollController();

  void closeOverlay() {
    if (overlayWidget == null || overlayWidget?.mounted == false) return;
    overlayWidget?.remove();
    overlayWidget = null;
  }

  void _insertOverlay(BuildContext context, raw.MobileMenuDelegate delegate) {
    overlayWidget = OverlayEntry(builder: (context) {
      final size = MediaQuery.of(context).size;
      return Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: () {
                closeOverlay();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            width: size.width,
            child: Material(
              color: Colors.black,
              child: Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: EmojiPicker(
                  scrollController: _scrollController,
                  onEmojiSelected: (emoji.Category? category, Emoji emoji) {
                    widget.emojiClick(emoji.emoji);
                    delegate.hideMenu(itemSelected: false);
                    closeOverlay();
                  },
                  config: Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.2 : 1.0),
                        backgroundColor: Colors.black,
                        columns: 8,
                        noRecents: Text(
                          'No Recents',
                          style: TextStyle(fontSize: 20, color: Colors.white60),
                          textAlign: TextAlign.center,
                        )),
                    swapCategoryAndBottomBar: true,
                    skinToneConfig: SkinToneConfig(indicatorColor: Colors.transparent, dialogBackgroundColor: Colors.black, enabled: true),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: Colors.black,
                    ),
                    bottomActionBarConfig: const BottomActionBarConfig(
                        backgroundColor: Colors.black,
                        showBackspaceButton: false,
                        buttonColor: Colors.transparent,
                        buttonIconColor: Colors.white),
                    searchViewConfig: SearchViewConfig(
                        backgroundColor: Colors.black,
                        buttonColor: Colors.white,
                        buttonIconColor: Colors.white,
                        hintText: "Search emoji",
                        hintStyle: TextStyle(color: Colors.white),
                        emojiListBgColor: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
    return Overlay.of(context).insert(overlayWidget!);
  }

  raw.MenuSerializationOptions _serializationOptions(BuildContext context) {
    final mq = MediaQuery.of(context);
    final iconTheme = widget.iconTheme ??
        const IconThemeData.fallback().copyWith(
          color: mq.platformBrightness == Brightness.light ? const Color(0xFF090909) : const Color(0xFFF0F0F0),
        );
    final destructiveIconTheme = widget.destructiveIconTheme ??
        iconTheme.copyWith(
          color: mq.platformBrightness == Brightness.light ? const Color(0xFFFF3B2F) : const Color(0xFFFF453A),
        );
    return raw.MenuSerializationOptions(
      iconTheme: iconTheme,
      destructiveIconTheme: destructiveIconTheme,
      devicePixelRatio: mq.devicePixelRatio,
    );
  }

  Future<MobileMenuConfiguration?> getMenuConfiguration(MobileMenuConfigurationRequest request) async {
    if (!widget.contextMenuIsAllowed(request.location)) {
      return null;
    }

    final onShowMenu = SimpleNotifier();
    final onHideMenu = ValueNotifier<MenuResult?>(null);
    final onPreviewAction = SimpleNotifier();

    void disposeNotifiers() {
      onShowMenu.dispose();
      onHideMenu.dispose();
      onPreviewAction.dispose();
    }

    final menu = await widget.menuProvider(MenuRequest(
      onShowMenu: onShowMenu,
      onHideMenu: onHideMenu,
      onPreviewAction: onPreviewAction,
      location: request.location,
    ));
    final snapshotter = _snapshotterKey.currentState!;
    if (menu == null || !mounted) {
      disposeNotifiers();
      return null;
    }

    final liftImage = await snapshotter.getSnapshot(request.location, _keyLift, () {
      FocusScope.of(context).unfocus();
      widget.liftBuilder?.call(context, widget.child);
    });

    if (liftImage == null) {
      // might happen if the widget was removed from hierarchy.
      onHideMenu.value = MenuResult(itemSelected: false);
      disposeNotifiers();
      return null;
    }

    final previewImage = widget.previewBuilder != null
        ? await snapshotter.getSnapshot(request.location, _keyPreview, () => widget.previewBuilder!.call(context, widget.child))
        : null;

    final menuContext = await raw.MenuContext.instance();

    if (!mounted) {
      disposeNotifiers();
      return null;
    }

    final serializationOptions = _serializationOptions(context);
    final handle = await menuContext.registerMenu(
      menu,
      serializationOptions,
    );

    MenuContextDelegate.instance.registerOnHideCallback(
      request.configurationId,
      (response) {
        onHideMenu.value = response;
        handle.dispose();
        disposeNotifiers();
      },
    );

    MenuContextDelegate.instance.registerOnShowCallback(
      request.configurationId,
      onShowMenu.notify,
    );

    MenuContextDelegate.instance.registerPreviewActionCallback(
      request.configurationId,
      onPreviewAction.notify,
    );

    Widget emojiView(
      String emoji,
    ) {
      return Container(
        height: 48,
        width: 48,
        margin: EdgeInsets.only(left: 8),
        child: Center(
            child: DefaultTextStyle(
          style: TextStyle(fontSize: 30),
          child: Text(
            emoji,
          ),
        )),
      );
    }

    Widget emojiViewAddIcon() {
      return Container(
        height: 48,
        width: 48,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // color: Colors.black,
          color: Colors.white.withOpacity(0.5),
        ),
        child: Center(child: Icon(Icons.add)),
      );
    }

    Size? deferredSize = widget.deferredPreviewBuilder != null ? _getDeferredPreview(onHideMenu, request.previewImageSetter) : null;

    return MobileMenuConfiguration(
      configurationId: request.configurationId,
      liftImage: liftImage,
      previewImage: previewImage?.snapshot,
      previewSize: deferredSize,
      handle: handle,
      backgroundBuilder: (opacity) {
        return Builder(builder: (context) => widget.menuWidgetBuilder.buildOverlayBackground(context, opacity));
      },
      previewBuilder: (size, snapshot) {
        return MenuPreviewWidget(size: size, menuWidgetBuilder: widget.menuWidgetBuilder, image: snapshot);
      },
      menuWidgetBuilder: (
        BuildContext context,
        Menu rootMenu,
        raw.MobileMenuDelegate delegate,
        AlignmentGeometry alignment,
        ValueListenable<bool> canScrollListenable,
        IconThemeData iconTheme,
      ) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.emojiList != null)
              if (widget.emojiList.length > 0)
                Container(
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.emojiList
                          .map((map) => map['emoji'] != null
                              ? GestureDetector(
                                  onTap: () {
                                    widget.emojiClick(map['emoji']);
                                    delegate.hideMenu(itemSelected: false);
                                  },
                                  child: emojiView(map['emoji']))
                              : GestureDetector(
                                  onTap: () {
                                    _insertOverlay(context, delegate);

                                    // delegate.hideMenu(itemSelected: false);
                                  },
                                  child: emojiViewAddIcon()))
                          .toList()),
                  decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(100)), color: Theme.of(context).primaryColor),
                  height: 48,
                  margin: EdgeInsets.only(bottom: 16),
                ),
            MenuStack(
              rootMenu: rootMenu,
              builder: widget.menuWidgetBuilder,
              canScrollListenable: canScrollListenable,
              delegate: delegate,
              iconTheme: iconTheme,
              menuAlignment: alignment,
            ),
          ],
        );
      },
      iconTheme: serializationOptions.iconTheme,
    );
  }

  Size _getDeferredPreview(Listenable onHide, ValueSetter<WidgetSnapshot> imageSetter) {
    final cancellationToken = raw.SimpleCancellationToken();
    onHide.addListener(cancellationToken.cancel);
    final deferredPreview = widget.deferredPreviewBuilder!(context, widget.child, cancellationToken);
    deferredPreview.widget.then((widget) {
      if (!cancellationToken.cancelled) {
        cancellationToken.dispose();
        _updateMenuPreview(widget, deferredPreview.size, imageSetter);
      }
    }, onError: (error) {
      cancellationToken.dispose();
    });

    return deferredPreview.size;
  }

  void _updateMenuPreview(Widget preview, Size size, ValueSetter<WidgetSnapshot> imageSetter) async {
    final snapshotter = _snapshotterKey.currentState!;
    final child = SnapshotSettings(
      constraintsTransform: (_) => BoxConstraints.tight(size),
      child: preview,
    );
    final previewImage = await snapshotter.getSnapshot(
      Offset.zero,
      _SnapshotKey('DeferredPreview'), // Deferred preview must have separate key.
      () => child,
    );
    if (previewImage != null) {
      imageSetter(previewImage.snapshot);
    }
  }

  final _snapshotterKey = GlobalKey<WidgetSnapshotterState>();

  @override
  Widget build(BuildContext context) {
    return WidgetSnapshotter(
      key: _snapshotterKey,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) {
            {
              _snapshotterKey.currentState?.registerWidget(
                  _keyLift,
                  widget.liftBuilder?.call(
                    context,
                    widget.child,
                  ));
              if (widget.previewBuilder != null) {
                _snapshotterKey.currentState?.registerWidget(
                    _keyPreview,
                    widget.previewBuilder!.call(
                      context,
                      widget.child,
                    ));
              }
            }
          }
        },
        onPointerCancel: (_) {
          _snapshotterKey.currentState?.unregisterWidget(_keyLift);
          _snapshotterKey.currentState?.unregisterWidget(_keyPreview);
        },
        onPointerUp: (_) {
          _snapshotterKey.currentState?.unregisterWidget(_keyLift);
          _snapshotterKey.currentState?.unregisterWidget(_keyPreview);
        },
        child: BaseContextMenuRenderWidget(
          hitTestBehavior: widget.hitTestBehavior,
          getConfiguration: getMenuConfiguration,
          contextMenuIsAllowed: widget.contextMenuIsAllowed,
          child: _LongPressDetector(
            hitTestBehavior: widget.hitTestBehavior,
            contextMenuIsAllowed: widget.contextMenuIsAllowed,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _LongPressDetector extends StatelessWidget {
  final Widget child;
  final HitTestBehavior hitTestBehavior;
  final ContextMenuIsAllowed contextMenuIsAllowed;

  const _LongPressDetector({
    required this.hitTestBehavior,
    required this.contextMenuIsAllowed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // Context menu is handled by iOS, but we need this gesture detector to
      // prevent listview pan detector immediately recognizing pan and setting
      // ignore pointer.
      return RawGestureDetector(
        behavior: hitTestBehavior,
        gestures: {
          PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(),
            (recognizer) {
              recognizer.gestureSettings = const DeviceGestureSettings(touchSlop: double.maxFinite);
              recognizer.onDown = (_) {};
            },
          ),
        },
        child: child,
      );
    } else {
      return raw.MultiTouchDetector(
        child: RawGestureDetector(
          behavior: hitTestBehavior,
          gestures: {
            raw.SingleDragDelayedGestureRecognizer: GestureRecognizerFactoryWithHandlers<raw.SingleDragDelayedGestureRecognizer>(
                () => raw.SingleDragDelayedGestureRecognizer(
                      beginDuration: const Duration(milliseconds: 150),
                      duration: const Duration(milliseconds: 300),
                    ), (recognizer) {
              recognizer.shouldAcceptTouchAtPosition = contextMenuIsAllowed;
              recognizer.onDragStart = (globalPosition) {
                return longPressHandler?.dragGestureForPosition(
                  context: context,
                  position: globalPosition,
                  pointer: recognizer.lastPointer!,
                );
              };
            }),
          },
          child: child,
        ),
      );
    }
  }
}

class _SnapshotKey {
  _SnapshotKey(this.debugName);

  @override
  String toString() {
    return "SnapshotKey('$debugName') ${identityHashCode(this)}";
  }

  final String debugName;
}
