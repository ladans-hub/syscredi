import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Action buttons share the largest natural size and wrap on narrow screens.
/// Intrinsic sizing keeps this usable in AlertDialog as well as page toolbars.
class EqualButtonGroup extends MultiChildRenderObjectWidget {
  const EqualButtonGroup({
    super.key,
    required super.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.alignment = WrapAlignment.start,
  });

  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _EqualButtons(spacing, runSpacing, alignment, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderBox renderObject,
  ) {
    (renderObject as _EqualButtons)
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..alignment = alignment
      ..textDirection = Directionality.of(context)
      ..markNeedsLayout();
  }
}

class _ButtonData extends ContainerBoxParentData<RenderBox> {}

class _EqualButtons extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ButtonData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ButtonData> {
  _EqualButtons(
    this.spacing,
    this.runSpacing,
    this.alignment,
    this.textDirection,
  );

  double spacing;
  double runSpacing;
  WrapAlignment alignment;
  TextDirection textDirection;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ButtonData) child.parentData = _ButtonData();
  }

  Size _buttonSize(double maxWidth) {
    double width = 0;
    double height = 48;
    RenderBox? child = firstChild;
    while (child != null) {
      width = math.max(width, child.getMaxIntrinsicWidth(double.infinity));
      child = childAfter(child);
    }
    width = math.min(width, maxWidth);
    child = firstChild;
    while (child != null) {
      height = math.max(height, child.getMaxIntrinsicHeight(width));
      child = childAfter(child);
    }
    return Size(width, height);
  }

  int _columns(double maxWidth, double width) => maxWidth.isFinite
      ? math.max(
          1,
          math.min(
            childCount,
            ((maxWidth + spacing) / (width + spacing)).floor(),
          ),
        )
      : math.max(1, childCount);

  @override
  double computeMinIntrinsicWidth(double height) =>
      _buttonSize(double.infinity).width;

  @override
  double computeMaxIntrinsicWidth(double height) => childCount == 0
      ? 0
      : _buttonSize(double.infinity).width * childCount +
            spacing * (childCount - 1);

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (childCount == 0) return constraints.constrain(Size.zero);
    final button = _buttonSize(constraints.maxWidth);
    final columns = _columns(constraints.maxWidth, button.width);
    final rows = (childCount / columns).ceil();
    return constraints.constrain(
      Size(
        button.width * columns + spacing * (columns - 1),
        button.height * rows + runSpacing * (rows - 1),
      ),
    );
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
    if (childCount == 0) return;
    final button = _buttonSize(constraints.maxWidth);
    final columns = _columns(constraints.maxWidth, button.width);
    RenderBox? child = firstChild;
    int index = 0;
    while (child != null) {
      child.layout(BoxConstraints.tight(button), parentUsesSize: true);
      final column = index % columns;
      final row = index ~/ columns;
      final count = math.min(columns, childCount - row * columns);
      final free = math.max(
        0.0,
        size.width - count * button.width - (count - 1) * spacing,
      );
      final (leading, extra) = switch (alignment) {
        WrapAlignment.start => (0.0, 0.0),
        WrapAlignment.end => (free, 0.0),
        WrapAlignment.center => (free / 2, 0.0),
        WrapAlignment.spaceBetween => (
          0.0,
          count > 1 ? free / (count - 1) : 0.0,
        ),
        WrapAlignment.spaceAround => (free / count / 2, free / count),
        WrapAlignment.spaceEvenly => (free / (count + 1), free / (count + 1)),
      };
      final x = leading + column * (button.width + spacing + extra);
      (child.parentData! as _ButtonData).offset = Offset(
        textDirection == TextDirection.ltr ? x : size.width - x - button.width,
        row * (button.height + runSpacing),
      );
      child = childAfter(child);
      index++;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
