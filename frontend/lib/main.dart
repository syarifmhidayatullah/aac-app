import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/board_repository.dart';
import 'data/db.dart';
import 'data/seed.dart';
import 'services/image_store.dart';
import 'services/speech_service.dart';
import 'state/account_state.dart';
import 'state/communication_state.dart';
import 'ui/communication_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final imageStore = await ImageStore.init();
  final prefs = await SharedPreferences.getInstance();

  final account = AccountState(db: db, prefs: prefs, imageStore: imageStore)
    ..init();

  // Profile aktif: yang tersimpan (kalau masih ada), selain itu profile
  // pertama / hasil seeding.
  final repository = BoardRepository(db);
  var profileId = await seedIfEmpty(db);
  final saved = account.activeProfileId;
  if (saved != null && await repository.profileExists(saved)) {
    profileId = saved;
  } else {
    await account.setActiveProfile(profileId);
  }

  runApp(AacApp(
    database: db,
    repository: repository,
    profileId: profileId,
    speech: FlutterTtsSpeechService(),
    imageStore: imageStore,
    account: account,
  ));
}

class AacApp extends StatelessWidget {
  const AacApp({
    super.key,
    required this.database,
    required this.repository,
    required this.profileId,
    required this.speech,
    required this.imageStore,
    required this.account,
  });

  final AppDatabase database;
  final BoardRepository repository;
  final String profileId;
  final SpeechService speech;
  final ImageStore imageStore;
  final AccountState account;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ImageStore>.value(value: imageStore),
        Provider<BoardRepository>.value(value: repository),
        Provider<SpeechService>.value(value: speech),
        ChangeNotifierProvider<AccountState>.value(value: account),
        ChangeNotifierProvider(
          create: (context) => CommunicationState(
            repository: repository,
            speech: speech,
            profileId: profileId,
          )..loadRoot(),
        ),
      ],
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
