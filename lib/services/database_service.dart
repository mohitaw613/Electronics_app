import 'package:postgres/postgres.dart';

class DatabaseService {
  static final endpoint = Endpoint(
    host: 'ep-shy-river-b3ymnajr-pooler.c-4.ap-southeast-1.aws.neon.tech',
    database: 'neondb',
    username: 'neondb_owner',
    password: 'YOUR_PASSWORD',
  );

  static final connection = Connection.open(
    endpoint,
    settings: const ConnectionSettings(
      sslMode: SslMode.require,
    ),
  );
}
