import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warisan_kita/viewmodels/admin_viewmodel.dart';

class PendingArtisansView extends StatelessWidget {
  const PendingArtisansView({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminViewModel>();
    if (admin.pendingArtisans.isEmpty) {
      return const Center(child: Text('No artisan applications are pending.'));
    }
    return ListView.builder(
      itemCount: admin.pendingArtisans.length,
      itemBuilder: (context, index) {
        final artisan = admin.pendingArtisans[index];
        return ListTile(
          title: Text(artisan.name),
          subtitle: Text(artisan.craftType),
          trailing: FilledButton(
            onPressed: () => admin.approveArtisan(artisan.id),
            child: const Text('Approve'),
          ),
        );
      },
    );
  }
}
