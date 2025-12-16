import 'package:flutter/material.dart';
import '../../../data/services/json_service.dart';

class EsmaulHusnaView extends StatelessWidget {
  const EsmaulHusnaView({super.key});

  @override
  Widget build(BuildContext context) {
    final JsonService jsonService = JsonService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Esmaül Hüsna"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: jsonService.getEsmaulHusna(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.teal,
                    ),
                  ),
                  subtitle: Text(
                    item['meaning'],
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Text(
                    item['arabic'],
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
