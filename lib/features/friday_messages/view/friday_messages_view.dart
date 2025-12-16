import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/services/json_service.dart';

class FridayMessagesView extends StatelessWidget {
  const FridayMessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    final JsonService jsonService = JsonService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cuma Mesajları"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<String>>(
        future: jsonService.getFridayMessages(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final messages = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return Card(
                color: Colors.teal.shade50,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Share.share(message),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.share),
                          label: const Text("Paylaş"),
                        ),
                      ),
                    ],
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
