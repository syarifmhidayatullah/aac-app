import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/board_repository.dart';
import 'data/db.dart';
import 'data/seed.dart';
import 'services/speech_service.dart';
import 'state/communication_state.dart';
import 'ui/communication_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final profileId = await seedIfEmpty(db);

  runApp(AacApp(
    database: db,
    profileId: profileId,
    speech: FlutterTtsSpeechService(),
  ));
}

class AacApp extends StatelessWidget {
  const AacApp({
    super.key,
    required this.database,
    required this.profileId,
    required this.speech,
  });

  final AppDatabase database;
  final String profileId;
  final SpeechService speech;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommunicationState(
        repository: BoardRepository(database),
        speech: speech,
        profileId: profileId,
      )..loadRoot(),
      child: MaterialApp(
        title: 'AAC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          visualDensity: VisualDensity.comfortable,
        ),
        home: const CommunicationScreen(),
      ),
    );
  }
}
