part of premo_table;

/// [FrozenHeadersLayout] will sync the vertical and horizontal scrolling of
/// 4 sections passed.
///
/// The four main sections as follows:
/// - Q1 - Top Left Quarter:
///   Frozen in position, horizontal scrolling synced with Q2.
/// - Q2 - Top Right Quarter:
///   Frozen in position, horizontal scrolling synced with Q1.
/// - Q3 - Bottom Left Quarter:
///   Frozen in position, horizontal and vertical scrolling synced with Q4.
/// - Q4 - Bottom Right Quarter:
///   Horizontal and vertical scrolling synced with Q3.
///
/// Each section is wrapped in a [SingleChildScrollView] as required to stick /
/// freeze the appropriate section.
class FrozenHeadersLayout extends StatefulWidget {
  final Widget? q1;
  final Widget? q2;
  final Widget q3;
  final Widget q4;

  FrozenHeadersLayout({
    Key? key,
    this.q1,
    this.q2,
    required this.q3,
    required this.q4,
  }) : super(key: key);

  @override
  _FrozenHeadersLayoutState createState() => _FrozenHeadersLayoutState();
}

class _FrozenHeadersLayoutState extends State<FrozenHeadersLayout> {
  final ScrollController _verticalRowHeadersController = ScrollController();
  final ScrollController _verticalContentController = ScrollController();

  final ScrollController _horizontalColHeadersController = ScrollController();
  final ScrollController _horizontalContentController = ScrollController();

  _SyncScrollController? _verticalSyncController;
  _SyncScrollController? _horizontalSyncController;

  @override
  void initState() {
    super.initState();
    _verticalSyncController = _SyncScrollController(
      [
        _verticalRowHeadersController,
        _verticalContentController,
      ],
    );
    _horizontalSyncController = _SyncScrollController(
      [
        _horizontalColHeadersController,
        _horizontalContentController,
      ],
    );
  }

  @override
  void dispose() {
    _verticalRowHeadersController.dispose();
    _verticalContentController.dispose();
    _horizontalColHeadersController.dispose();
    _horizontalContentController.dispose();
    _verticalSyncController = null;
    _horizontalSyncController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // TOP HALF
        Row(
          children: <Widget>[
            // TOP LEFT
            // Q1 - Sticky column headers and legend cell
            widget.q1 ?? Container(),
            // TOP RIGHT
            // SCROLLABLE column headers
            Expanded(
              child: NotificationListener<ScrollNotification>(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: widget.q2 ?? Container(),
                  controller: _horizontalColHeadersController,
                ),
                onNotification: (ScrollNotification notification) {
                  _horizontalSyncController!.processNotification(
                    notification,
                    _horizontalColHeadersController,
                  );
                  return true;
                },
              ),
            )
          ],
        ),
        // BOTTOM HALF
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // BOTTOM LEFT
              // q3 - Sticky row headers
              NotificationListener<ScrollNotification>(
                child: SingleChildScrollView(
                  child: widget.q3,
                  controller: _verticalRowHeadersController,
                ),
                onNotification: (ScrollNotification notification) {
                  _verticalSyncController!.processNotification(
                    notification,
                    _verticalRowHeadersController,
                  );
                  return true;
                },
              ),
              // BOTTOM RIGHT
              // q4 - Scrollable cell content
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _horizontalContentController,
                    child: NotificationListener<ScrollNotification>(
                      child: SingleChildScrollView(
                        controller: _verticalContentController,
                        child: widget.q4,
                      ),
                      onNotification: (ScrollNotification notification) {
                        _verticalSyncController!.processNotification(
                          notification,
                          _verticalContentController,
                        );
                        return true;
                      },
                    ),
                  ),
                  onNotification: (ScrollNotification notification) {
                    _horizontalSyncController!.processNotification(
                      notification,
                      _horizontalContentController,
                    );
                    return true;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// [SyncScrollController] keeps scroll controllers in sync.
class _SyncScrollController {
  final List<ScrollController> _registeredScrollControllers = [];
  ScrollController? _scrollingController;
  bool _scrollingActive = false;

  _SyncScrollController(List<ScrollController> controllers) {
    controllers.forEach((controller) {
      return _registeredScrollControllers.add(controller);
    });
  }

  processNotification(
    ScrollNotification notification,
    ScrollController sender,
  ) {
    if (notification is ScrollStartNotification && !_scrollingActive) {
      _scrollingController = sender;
      _scrollingActive = true;
      return;
    }

    if (identical(sender, _scrollingController) && _scrollingActive) {
      if (notification is ScrollEndNotification) {
        _scrollingController = null;
        _scrollingActive = false;
        return;
      }

      if (notification is ScrollUpdateNotification) {
        for (ScrollController controller in _registeredScrollControllers) {
          if (identical(_scrollingController, controller)) continue;
          controller.jumpTo(_scrollingController!.offset);
        }
      }
    }
  }
}
