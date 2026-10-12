import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/faq_provider.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FAQProvider>(context, listen: false).loadFAQs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help Center")),
      body: Consumer<FAQProvider>(
        builder: (context, faqProvider, _) {
          // Loading state
          if (faqProvider.state == FAQState.loading) {
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: 5,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: ShimmerWidget.rectangular(height: 60),
              ),
            );
          }

          // Error state
          if (faqProvider.state == FAQState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load FAQs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    faqProvider.errorMessage ?? 'Something went wrong',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => faqProvider.loadFAQs(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (faqProvider.faqs.isEmpty) {
            return const Center(
              child: Text(
                'No FAQs available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Loaded state - show FAQs as expansion tiles
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: faqProvider.faqs.length,
            itemBuilder: (context, index) {
              final faq = faqProvider.faqs[index];
              final question = faq['question'] ?? 'Question';
              final answer = faq['answer'] ?? 'Answer';
              final category = faq['category'] ?? 'General';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                child: ExpansionTile(
                  title: Text(
                    question,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        answer,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
