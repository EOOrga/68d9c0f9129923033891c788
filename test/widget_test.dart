import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quilan_ops/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard opens the main operations areas', (tester) async {
    final controller = OpsController(initialState: OpsState.seed());

    await tester.pumpWidget(QuilanApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Operations command'), findsOneWidget);
    expect(find.text('Open incidents'), findsOneWidget);

    await tester.tap(find.text('Incidents'));
    await tester.pumpAndSettle();

    expect(find.text('Incident reports'), findsOneWidget);
    expect(find.byKey(const Key('newIncidentButton')), findsOneWidget);
  });

  testWidgets('creates an incident and saves it locally', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = OpsController(initialState: OpsState.empty());

    await tester.pumpWidget(QuilanApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Incidents'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newIncidentButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('incidentTitleField')),
      'Dock safety review',
    );
    await tester.enterText(
      find.byKey(const Key('incidentSiteField')),
      'Main dock',
    );
    await tester.enterText(
      find.byKey(const Key('incidentOwnerField')),
      'Ops lead',
    );
    await tester.tap(find.byKey(const Key('saveIncidentButton')));
    await tester.pumpAndSettle();

    expect(find.text('Dock safety review'), findsOneWidget);
    expect(controller.state.incidents, hasLength(1));
  });
}
