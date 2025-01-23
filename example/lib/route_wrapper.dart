import 'package:flutter/material.dart';

abstract class RouteWrapper {
  /// clients will implement this method to return their wrapped routes
  Widget wrappedRoute(BuildContext context);
}
