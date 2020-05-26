library file_dropzone_web;

import 'dart:async';
import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class FileDropZone extends StatefulWidget {
  final Widget child;
  final Color hoverColor;
  final Function onDragEnter;
  final Function onDragExit;
  final Function(List<File> files) onDrop;

  FileDropZone({
    Key key,
    this.child,
    this.hoverColor,
    this.onDragEnter,
    this.onDragExit,
    @required this.onDrop,
  }) : super(key: key);

  @override
  _FileDropZoneState createState() => _FileDropZoneState();

  static void registerWith(Registrar registrar) {}
}

class _FileDropZoneState extends State<FileDropZone> {
  final _childKey = GlobalKey();

  // States
  bool insideDropZone;

  StreamSubscription<MouseEvent> _onDragStream;
  StreamSubscription<MouseEvent> _onDragEndStream;
  StreamSubscription<MouseEvent> _onDropStream;

  @override
  void initState() {
    super.initState();
    insideDropZone = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => didMount());
  }

  void didMount() {
    if (kIsWeb) {
      _onDragStream = document.body.onDragOver.listen(_onDragOver);
      _onDragEndStream = document.body.onDragLeave.listen(_onDragEnd);
      _onDropStream = document.body.onDrop.listen(_onDrop);
    }
  }

  @override
  void dispose() {
    super.dispose();

    if (kIsWeb) {
      _onDragStream.cancel();
      _onDragEndStream.cancel();
      _onDropStream.cancel();
    }
  }

  void _onDragOver(MouseEvent event) {
    event.stopPropagation();
    event.preventDefault();

    final inside = isInsideContainer(event.client);
    if (inside != insideDropZone) {
      setState(() {
        insideDropZone = inside;
      });

      final cb = inside ? widget.onDragEnter : widget.onDragExit;
      if (cb != null) cb();
    }
  }

  void _onDragEnd(MouseEvent event) {
    event.stopPropagation();
    event.preventDefault();

    setState(() {
      insideDropZone = false;
    });

    if (widget.onDragExit != null) widget.onDragExit();
  }

  void _onDrop(MouseEvent event) {
    _onDragEnd(event);

    final inside = isInsideContainer(event.client);
    final files = event.dataTransfer?.files;

    if (inside && files != null) {
      onFilesDrop(files);
    }
  }

  void onFilesDrop(List<File> files) {
    if (widget.onDrop != null) widget.onDrop(files);
  }

  bool isInsideContainer(Point<num> mPos) {
    if (_childKey.currentContext == null ||
        _childKey.currentContext.findRenderObject == null) {
      return false;
    }

    // Get widget position and size
    RenderBox box = _childKey.currentContext.findRenderObject();
    Offset pos = box.localToGlobal(Offset.zero);
    Size size = box.size;

    return (mPos.x >= pos.dx &&
        mPos.y >= pos.dy &&
        mPos.x < (pos.dx + size.width) &&
        mPos.y < (pos.dy + size.height));
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? Container(
            key: _childKey,
            color: insideDropZone ? widget.hoverColor : null,
            child: widget.child,
          )
        : widget.child;
  }
}
