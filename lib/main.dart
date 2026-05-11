import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String appName = 'QUILAN MARIUS RENE GABRIEL';
const String developerName = 'QUILAN MARIUS RENE GABRIEL';
const String supportEmail = 'support@quilanmariusrenegabriel.com';
const bool screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

const Color brandNavy = Color(0xFF071826);
const Color brandTeal = Color(0xFF00BFC0);
const Color brandGold = Color(0xFFE3A823);
const Color brandBlue = Color(0xFF1677D2);
const Color brandInk = Color(0xFF102235);

void main() {
  runApp(const QuilanApp());
}

class QuilanApp extends StatefulWidget {
  const QuilanApp({super.key, this.controller});

  final OpsController? controller;

  @override
  State<QuilanApp> createState() => _QuilanAppState();
}

class _QuilanAppState extends State<QuilanApp> {
  late final OpsController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? OpsController(screenshotMode: screenshotMode);
    _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: brandTeal,
          brightness: Brightness.light,
        ).copyWith(
          primary: brandTeal,
          secondary: brandGold,
          tertiary: brandBlue,
          surface: const Color(0xFFF8FBFC),
          onPrimary: brandNavy,
          onSecondary: brandNavy,
          onSurface: brandInk,
        );

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF3F7F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: brandNavy,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE0EAEE)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.ready) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return OperationsHome(controller: _controller);
        },
      ),
    );
  }
}

class OperationsHome extends StatefulWidget {
  const OperationsHome({super.key, required this.controller});

  final OpsController controller;

  @override
  State<OperationsHome> createState() => _OperationsHomeState();
}

class _OperationsHomeState extends State<OperationsHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(controller: widget.controller, onSelectTab: _selectTab),
      IncidentsScreen(controller: widget.controller),
      ResourcesScreen(controller: widget.controller),
      ScheduleScreen(controller: widget.controller),
      ReportsScreen(controller: widget.controller),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Command',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Incidents',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Resources',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _index = index);
  }
}

class OpsController extends ChangeNotifier {
  OpsController({OpsState? initialState, this.screenshotMode = false})
    : state =
          initialState ?? (screenshotMode ? OpsState.seed() : OpsState.empty()),
      _ready = initialState != null || screenshotMode;

  final bool screenshotMode;
  OpsState state;
  bool _ready;
  SharedPreferences? _preferences;

  bool get ready => _ready;

  Future<void> load() async {
    if (_ready) {
      return;
    }
    _preferences = await SharedPreferences.getInstance();
    final saved = _preferences?.getString('ops_state');
    if (saved != null && saved.isNotEmpty) {
      try {
        state = OpsState.fromJson(jsonDecode(saved) as Map<String, dynamic>);
      } on FormatException {
        state = OpsState.empty();
      } on TypeError {
        state = OpsState.empty();
      }
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    if (screenshotMode) {
      notifyListeners();
      return;
    }
    await _preferences?.setString('ops_state', jsonEncode(state.toJson()));
    notifyListeners();
  }

  Future<void> addIncident(Incident incident) async {
    state = state.copyWith(incidents: [incident, ...state.incidents]);
    await _save();
  }

  Future<void> updateIncidentStatus(String id, String status) async {
    state = state.copyWith(
      incidents: [
        for (final incident in state.incidents)
          if (incident.id == id)
            incident.copyWith(status: status)
          else
            incident,
      ],
    );
    await _save();
  }

  Future<void> addAllocation(ResourceAllocation allocation) async {
    state = state.copyWith(allocations: [allocation, ...state.allocations]);
    await _save();
  }

  Future<void> addInterview(InterviewSlot interview) async {
    state = state.copyWith(interviews: [interview, ...state.interviews]);
    await _save();
  }

  Future<void> addPayroll(PayrollReport report) async {
    state = state.copyWith(payrollReports: [report, ...state.payrollReports]);
    await _save();
  }

  Future<void> resetWorkspace() async {
    state = OpsState.empty();
    await _preferences?.remove('ops_state');
    notifyListeners();
  }
}

class OpsState {
  const OpsState({
    required this.incidents,
    required this.allocations,
    required this.interviews,
    required this.payrollReports,
  });

  final List<Incident> incidents;
  final List<ResourceAllocation> allocations;
  final List<InterviewSlot> interviews;
  final List<PayrollReport> payrollReports;

  factory OpsState.empty() {
    return const OpsState(
      incidents: [],
      allocations: [],
      interviews: [],
      payrollReports: [],
    );
  }

  factory OpsState.seed() {
    return OpsState(
      incidents: [
        Incident(
          id: 'inc-001',
          title: 'Loading bay access delay',
          site: 'North depot',
          severity: 'High',
          status: 'Assigned',
          owner: 'A. Bernard',
          note: 'Forklift lane blocked during morning intake.',
          reportedAt: DateTime(2026, 5, 11, 8, 35),
        ),
        Incident(
          id: 'inc-002',
          title: 'Supplier invoice mismatch',
          site: 'Finance desk',
          severity: 'Medium',
          status: 'Open',
          owner: 'M. Laurent',
          note: 'Payroll hours and supplier receipt need review.',
          reportedAt: DateTime(2026, 5, 11, 9, 10),
        ),
        Incident(
          id: 'inc-003',
          title: 'Interview room double booked',
          site: 'HQ floor 2',
          severity: 'Low',
          status: 'Scheduled',
          owner: 'S. Vidal',
          note: 'Move candidate panel to room B before 14:00.',
          reportedAt: DateTime(2026, 5, 10, 16, 45),
        ),
      ],
      allocations: [
        ResourceAllocation(
          id: 'res-001',
          resource: 'Warehouse lift team',
          team: 'Logistics',
          window: 'Today 10:30-14:00',
          priority: 'Urgent',
          status: 'Confirmed',
        ),
        ResourceAllocation(
          id: 'res-002',
          resource: 'Payroll review block',
          team: 'Finance',
          window: 'Today 15:00-17:00',
          priority: 'Normal',
          status: 'Queued',
        ),
        ResourceAllocation(
          id: 'res-003',
          resource: 'Interview panel room B',
          team: 'People ops',
          window: 'Tomorrow 09:00-12:00',
          priority: 'Normal',
          status: 'Reserved',
        ),
      ],
      interviews: [
        InterviewSlot(
          id: 'int-001',
          candidate: 'Nadia Mercier',
          role: 'Operations coordinator',
          dateLabel: 'May 12, 09:30',
          stage: 'Panel',
          interviewer: 'People ops',
        ),
        InterviewSlot(
          id: 'int-002',
          candidate: 'Hugo Caron',
          role: 'Payroll analyst',
          dateLabel: 'May 12, 11:00',
          stage: 'Skills review',
          interviewer: 'Finance desk',
        ),
      ],
      payrollReports: [
        PayrollReport(
          id: 'pay-001',
          period: 'May week 2',
          department: 'Logistics',
          hours: '412.5',
          variance: '+8.0 overtime',
          status: 'Needs approval',
        ),
        PayrollReport(
          id: 'pay-002',
          period: 'May week 2',
          department: 'Administration',
          hours: '188.0',
          variance: 'Balanced',
          status: 'Ready',
        ),
      ],
    );
  }

  factory OpsState.fromJson(Map<String, dynamic> json) {
    return OpsState(
      incidents: _decodeList(json['incidents'], Incident.fromJson),
      allocations: _decodeList(
        json['allocations'],
        ResourceAllocation.fromJson,
      ),
      interviews: _decodeList(json['interviews'], InterviewSlot.fromJson),
      payrollReports: _decodeList(
        json['payrollReports'],
        PayrollReport.fromJson,
      ),
    );
  }

  OpsState copyWith({
    List<Incident>? incidents,
    List<ResourceAllocation>? allocations,
    List<InterviewSlot>? interviews,
    List<PayrollReport>? payrollReports,
  }) {
    return OpsState(
      incidents: incidents ?? this.incidents,
      allocations: allocations ?? this.allocations,
      interviews: interviews ?? this.interviews,
      payrollReports: payrollReports ?? this.payrollReports,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incidents': incidents.map((incident) => incident.toJson()).toList(),
      'allocations': allocations
          .map((allocation) => allocation.toJson())
          .toList(),
      'interviews': interviews.map((interview) => interview.toJson()).toList(),
      'payrollReports': payrollReports
          .map((report) => report.toJson())
          .toList(),
    };
  }
}

List<T> _decodeList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) {
    return [];
  }
  return [
    for (final item in value)
      if (item is Map<String, dynamic>) fromJson(item),
  ];
}

class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.site,
    required this.severity,
    required this.status,
    required this.owner,
    required this.note,
    required this.reportedAt,
  });

  final String id;
  final String title;
  final String site;
  final String severity;
  final String status;
  final String owner;
  final String note;
  final DateTime reportedAt;

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String? ?? _id('inc'),
      title: json['title'] as String? ?? 'Untitled incident',
      site: json['site'] as String? ?? 'Unassigned site',
      severity: json['severity'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'Open',
      owner: json['owner'] as String? ?? 'Unassigned',
      note: json['note'] as String? ?? '',
      reportedAt:
          DateTime.tryParse(json['reportedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Incident copyWith({String? status}) {
    return Incident(
      id: id,
      title: title,
      site: site,
      severity: severity,
      status: status ?? this.status,
      owner: owner,
      note: note,
      reportedAt: reportedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'site': site,
      'severity': severity,
      'status': status,
      'owner': owner,
      'note': note,
      'reportedAt': reportedAt.toIso8601String(),
    };
  }
}

class ResourceAllocation {
  const ResourceAllocation({
    required this.id,
    required this.resource,
    required this.team,
    required this.window,
    required this.priority,
    required this.status,
  });

  final String id;
  final String resource;
  final String team;
  final String window;
  final String priority;
  final String status;

  factory ResourceAllocation.fromJson(Map<String, dynamic> json) {
    return ResourceAllocation(
      id: json['id'] as String? ?? _id('res'),
      resource: json['resource'] as String? ?? 'Resource',
      team: json['team'] as String? ?? 'Team',
      window: json['window'] as String? ?? 'Today',
      priority: json['priority'] as String? ?? 'Normal',
      status: json['status'] as String? ?? 'Queued',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resource': resource,
      'team': team,
      'window': window,
      'priority': priority,
      'status': status,
    };
  }
}

class InterviewSlot {
  const InterviewSlot({
    required this.id,
    required this.candidate,
    required this.role,
    required this.dateLabel,
    required this.stage,
    required this.interviewer,
  });

  final String id;
  final String candidate;
  final String role;
  final String dateLabel;
  final String stage;
  final String interviewer;

  factory InterviewSlot.fromJson(Map<String, dynamic> json) {
    return InterviewSlot(
      id: json['id'] as String? ?? _id('int'),
      candidate: json['candidate'] as String? ?? 'Candidate',
      role: json['role'] as String? ?? 'Role',
      dateLabel: json['dateLabel'] as String? ?? 'To schedule',
      stage: json['stage'] as String? ?? 'Screen',
      interviewer: json['interviewer'] as String? ?? 'Panel',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'candidate': candidate,
      'role': role,
      'dateLabel': dateLabel,
      'stage': stage,
      'interviewer': interviewer,
    };
  }
}

class PayrollReport {
  const PayrollReport({
    required this.id,
    required this.period,
    required this.department,
    required this.hours,
    required this.variance,
    required this.status,
  });

  final String id;
  final String period;
  final String department;
  final String hours;
  final String variance;
  final String status;

  factory PayrollReport.fromJson(Map<String, dynamic> json) {
    return PayrollReport(
      id: json['id'] as String? ?? _id('pay'),
      period: json['period'] as String? ?? 'Current period',
      department: json['department'] as String? ?? 'Operations',
      hours: json['hours'] as String? ?? '0',
      variance: json['variance'] as String? ?? 'Not reviewed',
      status: json['status'] as String? ?? 'Draft',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period': period,
      'department': department,
      'hours': hours,
      'variance': variance,
      'status': status,
    };
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onSelectTab,
  });

  final OpsController controller;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final openIncidents = state.incidents
        .where((incident) => incident.status != 'Closed')
        .length;
    final readyPayroll = state.payrollReports
        .where((report) => report.status == 'Ready')
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: brandNavy,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Operations command',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Track incident response, staffing resources, interviews, and payroll reports from one offline workspace.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => onSelectTab(1),
                    icon: const Icon(Icons.add_alert),
                    label: const Text('Report issue'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onSelectTab(2),
                    icon: const Icon(Icons.assignment_ind),
                    label: const Text('Allocate team'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth > 720
                ? (constraints.maxWidth - 36) / 4
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                MetricCard(
                  width: itemWidth,
                  label: 'Open incidents',
                  value: '$openIncidents',
                  icon: Icons.report_problem,
                  color: brandGold,
                ),
                MetricCard(
                  width: itemWidth,
                  label: 'Allocated resources',
                  value: '${state.allocations.length}',
                  icon: Icons.account_tree,
                  color: brandTeal,
                ),
                MetricCard(
                  width: itemWidth,
                  label: 'Interviews',
                  value: '${state.interviews.length}',
                  icon: Icons.event_available,
                  color: brandBlue,
                ),
                MetricCard(
                  width: itemWidth,
                  label: 'Payroll ready',
                  value: '$readyPayroll',
                  icon: Icons.payments,
                  color: const Color(0xFF2EAD6B),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Today',
          action: TextButton(
            onPressed: () => onSelectTab(3),
            child: const Text('View schedule'),
          ),
        ),
        if (state.interviews.isEmpty)
          const EmptyState(
            icon: Icons.event_busy,
            title: 'No interviews scheduled',
            body: 'Add interview slots as candidates move through the process.',
          )
        else
          RecordCard(
            leading: const Icon(Icons.event_available, color: brandBlue),
            title: state.interviews.first.candidate,
            subtitle:
                '${state.interviews.first.role} • ${state.interviews.first.dateLabel}',
            trailing: StatusPill(
              label: state.interviews.first.stage,
              color: brandBlue,
            ),
          ),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Priority queue',
          action: TextButton(
            onPressed: () => onSelectTab(1),
            child: const Text('Review'),
          ),
        ),
        if (state.incidents.isEmpty)
          const EmptyState(
            icon: Icons.inbox,
            title: 'No incident reports',
            body: 'Create a report when something needs follow-up.',
          )
        else
          Column(
            children: state.incidents.take(2).map((incident) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IncidentTile(
                  incident: incident,
                  onTap: () => onSelectTab(1),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key, required this.controller});

  final OpsController controller;

  @override
  Widget build(BuildContext context) {
    final incidents = controller.state.incidents;
    return Scaffold(
      body: ListView(
        key: const Key('incidentsList'),
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(
            title: 'Incident reports',
            action: FilledButton.icon(
              key: const Key('newIncidentButton'),
              onPressed: () => showIncidentForm(context, controller),
              icon: const Icon(Icons.add),
              label: const Text('New incident'),
            ),
          ),
          const SizedBox(height: 10),
          if (incidents.isEmpty)
            const EmptyState(
              icon: Icons.report_off,
              title: 'No active reports',
              body:
                  'Log a workplace issue, assign an owner, and keep the status visible.',
            )
          else
            ...incidents.map(
              (incident) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IncidentTile(
                  incident: incident,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => IncidentDetailScreen(
                        incident: incident,
                        controller: controller,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({
    super.key,
    required this.incident,
    required this.controller,
  });

  final Incident incident;
  final OpsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incident status')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final current = controller.state.incidents.firstWhere(
            (item) => item.id == incident.id,
            orElse: () => incident,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                current.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    label: current.severity,
                    color: severityColor(current.severity),
                  ),
                  StatusPill(
                    label: current.status,
                    color: statusColor(current.status),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DetailRow(
                label: 'Site',
                value: current.site,
                icon: Icons.location_city,
              ),
              DetailRow(
                label: 'Owner',
                value: current.owner,
                icon: Icons.person_pin,
              ),
              DetailRow(
                label: 'Reported',
                value: formatDate(current.reportedAt),
                icon: Icons.schedule,
              ),
              DetailRow(label: 'Notes', value: current.note, icon: Icons.notes),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response status',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Open', 'Assigned', 'Scheduled', 'Closed']
                            .map((status) {
                              return ChoiceChip(
                                label: Text(status),
                                selected: current.status == status,
                                onSelected: (_) => controller
                                    .updateIncidentStatus(current.id, status),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key, required this.controller});

  final OpsController controller;

  @override
  Widget build(BuildContext context) {
    final allocations = controller.state.allocations;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: 'Resource allocation',
          action: FilledButton.icon(
            key: const Key('newResourceButton'),
            onPressed: () => showResourceForm(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Assign'),
          ),
        ),
        const SizedBox(height: 10),
        if (allocations.isEmpty)
          const EmptyState(
            icon: Icons.account_tree_outlined,
            title: 'No resources allocated',
            body: 'Reserve teams, rooms, or review blocks for the work queue.',
          )
        else
          ...allocations.map(
            (allocation) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordCard(
                leading: const Icon(Icons.account_tree, color: brandTeal),
                title: allocation.resource,
                subtitle: '${allocation.team} • ${allocation.window}',
                trailing: StatusPill(
                  label: allocation.status,
                  color: allocation.priority == 'Urgent'
                      ? brandGold
                      : brandTeal,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key, required this.controller});

  final OpsController controller;

  @override
  Widget build(BuildContext context) {
    final interviews = controller.state.interviews;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: 'Interview scheduling',
          action: FilledButton.icon(
            key: const Key('newInterviewButton'),
            onPressed: () => showInterviewForm(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Schedule'),
          ),
        ),
        const SizedBox(height: 10),
        if (interviews.isEmpty)
          const EmptyState(
            icon: Icons.event_busy,
            title: 'No interview slots',
            body: 'Add candidates, roles, stages, and interviewer owners.',
          )
        else
          ...interviews.map(
            (interview) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordCard(
                leading: const Icon(Icons.event_available, color: brandBlue),
                title: interview.candidate,
                subtitle: '${interview.role} • ${interview.dateLabel}',
                trailing: StatusPill(label: interview.stage, color: brandBlue),
                footer: 'Interviewer: ${interview.interviewer}',
              ),
            ),
          ),
      ],
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.controller});

  final OpsController controller;

  @override
  Widget build(BuildContext context) {
    final reports = controller.state.payrollReports;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: 'Payroll reports',
          action: FilledButton.icon(
            key: const Key('newPayrollButton'),
            onPressed: () => showPayrollForm(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Add report'),
          ),
        ),
        const SizedBox(height: 10),
        if (reports.isEmpty)
          const EmptyState(
            icon: Icons.payments_outlined,
            title: 'No payroll reports',
            body: 'Save period totals and variances before approval review.',
          )
        else
          ...reports.map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordCard(
                leading: const Icon(Icons.payments, color: Color(0xFF2EAD6B)),
                title: '${report.department} • ${report.period}',
                subtitle: '${report.hours} hours • ${report.variance}',
                trailing: StatusPill(
                  label: report.status,
                  color: statusColor(report.status),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: brandNavy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.privacy_tip, color: brandTeal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Settings and privacy',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Records stay on this device. There is no account sign-in, cloud sync, analytics, advertising, or network service.',
                ),
                const SizedBox(height: 12),
                Text('Support: $supportEmail'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => confirmReset(context, controller),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear local records'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: brandInk,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: brandInk,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class IncidentTile extends StatelessWidget {
  const IncidentTile({super.key, required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RecordCard(
      onTap: onTap,
      leading: Icon(
        Icons.report_problem,
        color: severityColor(incident.severity),
      ),
      title: incident.title,
      subtitle: '${incident.site} • ${incident.owner}',
      trailing: StatusPill(
        label: incident.status,
        color: statusColor(incident.status),
      ),
      footer:
          '${incident.severity} severity • ${formatDate(incident.reportedAt)}',
    );
  }
}

class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.footer,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final String? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 34, child: leading),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing,
                ],
              ),
              if (footer != null) ...[
                const SizedBox(height: 10),
                Text(
                  footer!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color.alphaBlend(color.withValues(alpha: 0.45), Colors.black),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 42, color: brandBlue),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: brandTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 3),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showIncidentForm(
  BuildContext context,
  OpsController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => IncidentForm(controller: controller),
  );
}

class IncidentForm extends StatefulWidget {
  const IncidentForm({super.key, required this.controller});

  final OpsController controller;

  @override
  State<IncidentForm> createState() => _IncidentFormState();
}

class _IncidentFormState extends State<IncidentForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _site = TextEditingController();
  final _owner = TextEditingController();
  final _note = TextEditingController();
  String _severity = 'Medium';

  @override
  void dispose() {
    _title.dispose();
    _site.dispose();
    _owner.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'New incident',
      formKey: _formKey,
      onSave: () async {
        if (!_formKey.currentState!.validate()) {
          return;
        }
        await widget.controller.addIncident(
          Incident(
            id: _id('inc'),
            title: _title.text.trim(),
            site: _site.text.trim(),
            severity: _severity,
            status: 'Open',
            owner: _owner.text.trim(),
            note: _note.text.trim().isEmpty
                ? 'No extra notes.'
                : _note.text.trim(),
            reportedAt: DateTime.now(),
          ),
        );
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      saveKey: const Key('saveIncidentButton'),
      children: [
        TextFormField(
          key: const Key('incidentTitleField'),
          controller: _title,
          decoration: const InputDecoration(labelText: 'Issue title'),
          textInputAction: TextInputAction.next,
          validator: requiredField,
        ),
        TextFormField(
          key: const Key('incidentSiteField'),
          controller: _site,
          decoration: const InputDecoration(labelText: 'Site or desk'),
          textInputAction: TextInputAction.next,
          validator: requiredField,
        ),
        TextFormField(
          key: const Key('incidentOwnerField'),
          controller: _owner,
          decoration: const InputDecoration(labelText: 'Owner'),
          textInputAction: TextInputAction.next,
          validator: requiredField,
        ),
        DropdownButtonFormField<String>(
          initialValue: _severity,
          decoration: const InputDecoration(labelText: 'Severity'),
          items: const ['Low', 'Medium', 'High']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() => _severity = value ?? _severity),
        ),
        TextFormField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Notes'),
          maxLines: 3,
        ),
      ],
    );
  }
}

Future<void> showResourceForm(
  BuildContext context,
  OpsController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ResourceForm(controller: controller),
  );
}

class ResourceForm extends StatefulWidget {
  const ResourceForm({super.key, required this.controller});

  final OpsController controller;

  @override
  State<ResourceForm> createState() => _ResourceFormState();
}

class _ResourceFormState extends State<ResourceForm> {
  final _formKey = GlobalKey<FormState>();
  final _resource = TextEditingController();
  final _team = TextEditingController();
  final _window = TextEditingController();
  String _priority = 'Normal';

  @override
  void dispose() {
    _resource.dispose();
    _team.dispose();
    _window.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'Assign resource',
      formKey: _formKey,
      onSave: () async {
        if (!_formKey.currentState!.validate()) {
          return;
        }
        await widget.controller.addAllocation(
          ResourceAllocation(
            id: _id('res'),
            resource: _resource.text.trim(),
            team: _team.text.trim(),
            window: _window.text.trim(),
            priority: _priority,
            status: _priority == 'Urgent' ? 'Confirmed' : 'Queued',
          ),
        );
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      children: [
        TextFormField(
          controller: _resource,
          decoration: const InputDecoration(labelText: 'Resource'),
          validator: requiredField,
        ),
        TextFormField(
          controller: _team,
          decoration: const InputDecoration(labelText: 'Team'),
          validator: requiredField,
        ),
        TextFormField(
          controller: _window,
          decoration: const InputDecoration(labelText: 'Time window'),
          validator: requiredField,
        ),
        DropdownButtonFormField<String>(
          initialValue: _priority,
          decoration: const InputDecoration(labelText: 'Priority'),
          items: const ['Normal', 'Urgent']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() => _priority = value ?? _priority),
        ),
      ],
    );
  }
}

Future<void> showInterviewForm(
  BuildContext context,
  OpsController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => InterviewForm(controller: controller),
  );
}

class InterviewForm extends StatefulWidget {
  const InterviewForm({super.key, required this.controller});

  final OpsController controller;

  @override
  State<InterviewForm> createState() => _InterviewFormState();
}

class _InterviewFormState extends State<InterviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _candidate = TextEditingController();
  final _role = TextEditingController();
  final _date = TextEditingController();
  final _interviewer = TextEditingController();
  String _stage = 'Screen';

  @override
  void dispose() {
    _candidate.dispose();
    _role.dispose();
    _date.dispose();
    _interviewer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'Schedule interview',
      formKey: _formKey,
      onSave: () async {
        if (!_formKey.currentState!.validate()) {
          return;
        }
        await widget.controller.addInterview(
          InterviewSlot(
            id: _id('int'),
            candidate: _candidate.text.trim(),
            role: _role.text.trim(),
            dateLabel: _date.text.trim(),
            stage: _stage,
            interviewer: _interviewer.text.trim(),
          ),
        );
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      children: [
        TextFormField(
          controller: _candidate,
          decoration: const InputDecoration(labelText: 'Candidate'),
          validator: requiredField,
        ),
        TextFormField(
          controller: _role,
          decoration: const InputDecoration(labelText: 'Role'),
          validator: requiredField,
        ),
        TextFormField(
          controller: _date,
          decoration: const InputDecoration(labelText: 'Date and time'),
          validator: requiredField,
        ),
        TextFormField(
          controller: _interviewer,
          decoration: const InputDecoration(labelText: 'Interviewer'),
          validator: requiredField,
        ),
        DropdownButtonFormField<String>(
          initialValue: _stage,
          decoration: const InputDecoration(labelText: 'Stage'),
          items: const ['Screen', 'Panel', 'Skills review', 'Offer review']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() => _stage = value ?? _stage),
        ),
      ],
    );
  }
}

Future<void> showPayrollForm(
  BuildContext context,
  OpsController controller,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PayrollForm(controller: controller),
  );
}

class PayrollForm extends StatefulWidget {
  const PayrollForm({super.key, required this.controller});

  final OpsController controller;

  @override
  State<PayrollForm> createState() => _PayrollFormState();
}

class _PayrollFormState extends State<PayrollForm> {
  final _formKey = GlobalKey<FormState>();
  final _period = TextEditingController();
  final _department = TextEditingController();
  final _hours = TextEditingController();
  final _variance = TextEditingController();
  String _status = 'Draft';

  @override
  void dispose() {
    _period.dispose();
    _department.dispose();
    _hours.dispose();
    _variance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'Payroll report',
      formKey: _formKey,
      onSave: () async {
        if (!_formKey.currentState!.validate()) {
          return;
        }
        await widget.controller.addPayroll(
          PayrollReport(
            id: _id('pay'),
            period: _period.text.trim(),
            department: _department.text.trim(),
            hours: _hours.text.trim(),
            variance: _variance.text.trim(),
            status: _status,
          ),
        );
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      children: [
        TextFormField(
          controller: _period,
          decoration: const InputDecoration(labelText: 'Period'),
          validator: requiredField,
        ),
        TextFormField(
          controller: _department,
          decoration: const InputDecoration(labelText: 'Department'),
          validator: requiredField,
        ),
        TextFormField(
          controller: _hours,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Hours'),
          validator: requiredField,
        ),
        TextFormField(
          controller: _variance,
          decoration: const InputDecoration(labelText: 'Variance'),
          validator: requiredField,
        ),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const ['Draft', 'Needs approval', 'Ready']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() => _status = value ?? _status),
        ),
      ],
    );
  }
}

class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSave,
    this.saveKey,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final Future<void> Function() onSave;
  final Key? saveKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...children.expand(
                  (child) => [child, const SizedBox(height: 12)],
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: saveKey,
                    onPressed: onSave,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> confirmReset(
  BuildContext context,
  OpsController controller,
) async {
  final approved = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Clear local records?'),
        content: const Text(
          'This removes incidents, allocations, interviews, and payroll reports saved on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      );
    },
  );
  if (approved == true) {
    await controller.resetWorkspace();
  }
}

String? requiredField(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return null;
}

String _id(String prefix) {
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

String formatDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${months[value.month - 1]} ${value.day}, $hour:$minute';
}

Color severityColor(String severity) {
  return switch (severity) {
    'High' => const Color(0xFFD1641D),
    'Medium' => brandGold,
    'Low' => brandBlue,
    _ => brandTeal,
  };
}

Color statusColor(String status) {
  return switch (status) {
    'Closed' => const Color(0xFF2EAD6B),
    'Ready' => const Color(0xFF2EAD6B),
    'Assigned' => brandBlue,
    'Scheduled' => brandTeal,
    'Confirmed' => brandTeal,
    'Needs approval' => brandGold,
    'Open' => const Color(0xFFD1641D),
    _ => brandGold,
  };
}
