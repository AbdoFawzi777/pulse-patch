// lib/features/knowledge/medical_knowledge_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/ai/ai_model_router.dart';
import '../../domain/ai/ai_provider.dart';
import '../../domain/ai/health_context_builder.dart';
import '../../domain/knowledge/medical_knowledge_engine.dart';
import '../../domain/knowledge/medical_knowledge_models.dart';

class MedicalKnowledgeAssistantScreen extends ConsumerStatefulWidget {
  const MedicalKnowledgeAssistantScreen({super.key});

  @override
  ConsumerState<MedicalKnowledgeAssistantScreen> createState() =>
      _MedicalKnowledgeAssistantScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final KnowledgeAnswer? answer;
  final AiResponse? aiResponse;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.answer,
    this.aiResponse,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _MedicalKnowledgeAssistantScreenState
    extends ConsumerState<MedicalKnowledgeAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  AiRoutingPreference _selectedPreference = AiRoutingPreference.auto;

  final List<Map<String, String>> _suggestedTopics = [
    {
      'en': 'Normal resting heart rate ranges',
      'ar': 'معدل نبض القلب الطبيعي أثناء الراحة',
    },
    {
      'en': 'What does SpO2 below 90% mean?',
      'ar': 'ماذا يعني انخفاض نسبة الأكسجين عن 90%؟',
    },
    {
      'en': 'WHO blood pressure classification',
      'ar': 'تصنيف فئات ضغط الدم المعتمدة من منظمة الصحة',
    },
    {
      'en': 'PPG estimates vs arm cuff readings',
      'ar': 'الفرق بين قياس الضغط بالنبض وجهاز الذراع',
    },
    {
      'en': 'Nocturnal heart rate dipping in sleep',
      'ar': 'الهبوط الليلي لمعدل النبض أثناء النوم',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Warm up knowledge engine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(medicalKnowledgeEngineProvider).initialize();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: cleanQuery, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final router = ref.read(aiModelRouterProvider);
    router.preference = _selectedPreference;

    // Build context
    const contextBuilder = HealthContextBuilder();
    final request = await contextBuilder.buildRequest(
      query: cleanQuery,
      language: isArabic ? 'ar' : 'en',
    );

    // Also query engine directly to ensure KnowledgeAnswer compatibility
    final engine = ref.read(medicalKnowledgeEngineProvider);
    final engineAnswer = await engine.query(cleanQuery);

    AiResponse aiResponse;
    try {
      aiResponse = await router.routeAndExecute(request);
    } catch (_) {
      // Fallback
      aiResponse = AiResponse(
        text: isArabic ? engineAnswer.responseAr : engineAnswer.responseEn,
        providerName: 'Local Evidence RAG (Offline)',
        isCloud: false,
        citations: engineAnswer.citations,
        isEmergency: engineAnswer.isEmergency,
        emergencyAdvice: (isArabic ? engineAnswer.emergencyNoticeAr : engineAnswer.emergencyNoticeEn),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(
          text: aiResponse.text,
          isUser: false,
          answer: engineAnswer,
          aiResponse: aiResponse,
        ));
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.menu_book_outlined, color: Colors.cyanAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'المساعد الطبي المرجعي' : 'Medical Reference Assistant',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // AI Provider Selector Menu
          PopupMenuButton<AiRoutingPreference>(
            icon: const Icon(Icons.psychology_outlined, color: AppColors.accentCyan),
            tooltip: isArabic ? 'نمط الذكاء الاصطناعي' : 'AI Routing Mode',
            onSelected: (pref) {
              setState(() => _selectedPreference = pref);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AiRoutingPreference.auto,
                child: Text(
                  isArabic ? 'تلقائي (سحابي / محلي)' : 'Auto (Cloud / Local)',
                  style: TextStyle(
                    fontWeight: _selectedPreference == AiRoutingPreference.auto ? FontWeight.bold : FontWeight.normal,
                    color: _selectedPreference == AiRoutingPreference.auto ? AppColors.accentCyan : null,
                  ),
                ),
              ),
              PopupMenuItem(
                value: AiRoutingPreference.cloudOnly,
                child: Text(
                  isArabic ? 'سحابي فقط (Gemini 3.8 Flash)' : 'Cloud Only (Gemini 3.8 Flash)',
                  style: TextStyle(
                    fontWeight: _selectedPreference == AiRoutingPreference.cloudOnly ? FontWeight.bold : FontWeight.normal,
                    color: _selectedPreference == AiRoutingPreference.cloudOnly ? AppColors.accentCyan : null,
                  ),
                ),
              ),
              PopupMenuItem(
                value: AiRoutingPreference.offlineOnly,
                child: Text(
                  isArabic ? 'محلي فقط (قاعدة الأدلة)' : 'Offline Only (Local RAG)',
                  style: TextStyle(
                    fontWeight: _selectedPreference == AiRoutingPreference.offlineOnly ? FontWeight.bold : FontWeight.normal,
                    color: _selectedPreference == AiRoutingPreference.offlineOnly ? AppColors.accentCyan : null,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: isArabic ? 'مسح المحادثة' : 'Clear Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Clinical Disclaimer Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? Colors.blueGrey.shade900.withValues(alpha: 0.5) : Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: Colors.cyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'قاعدة المعرفة للأغراض التثقيفية فقط. لا تقدم تشخيصاً طبياً. في الطوارئ اتصل بالإسعاف (123).'
                          : 'Educational reference only. Non-diagnostic. In medical emergencies, call 123 immediately.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active Provider Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: isDark ? const Color(0xFF070B1E) : Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isArabic
                            ? 'النمط النشط: ${_selectedPreference.labelAr}'
                            : 'Active: ${_selectedPreference.labelEn.split('(').first.trim()}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    isArabic ? 'موثق: WHO · ESC · AHA' : 'Evidence: WHO · ESC · AHA',
                    style: const TextStyle(fontSize: 10, color: AppColors.accentCyan),
                  ),
                ],
              ),
            ),

            // Chat Messages List
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(isArabic, isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        if (msg.isUser) {
                          return _buildUserBubble(msg.text, isDark);
                        } else {
                          return _buildAssistantCard(msg, isArabic, isDark);
                        }
                      },
                    ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                  ),
                ),
              ),

            // Quick Query Chips (Suggested Topics)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: _suggestedTopics.map((topic) {
                  final text = isArabic ? topic['ar']! : topic['en']!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: isDark ? const Color(0xFF1E2238) : Colors.grey.shade200,
                      label: Text(
                        text,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.cyanAccent.shade100 : Colors.indigo.shade900,
                        ),
                      ),
                      onPressed: () => _handleSend(text),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Message Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0C16) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleSend,
                      decoration: InputDecoration(
                        hintText: isArabic
                            ? 'اسأل عن النبض، الأكسجين، الضغط، النوم...'
                            : 'Ask about heart rate, SpO2, blood pressure, sleep...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF16192E) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.shade700,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 20),
                    onPressed: () => _handleSend(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isArabic, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyan.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.local_library_outlined, size: 56, color: Colors.cyanAccent),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'موسوعة المراجع الطبية المعتمدة' : 'Authoritative Medical Knowledge Base',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'ابحث في إرشادات منظمة الصحة العالمية (WHO)، والجمعية الأوروبية لأمراض القلب (ESC)، وجمعية القلب الأمريكية (AHA)، ومراجعات ببمد (PMC).'
                  : 'Search peer-reviewed guidelines from WHO, European Society of Cardiology (ESC), American Heart Association (AHA), and PubMed Central (PMC).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isArabic ? 'مواضيع شائعة للاستفسار:' : 'Common Topics:',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestedTopics.map((topic) {
                final text = isArabic ? topic['ar']! : topic['en']!;
                return OutlinedButton.icon(
                  icon: const Icon(Icons.search, size: 14, color: Colors.cyan),
                  label: Text(text, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _handleSend(text),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBubble(String text, bool isDark) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.cyan.shade700,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildAssistantCard(_ChatMessage msg, bool isArabic, bool isDark) {
    final answer = msg.answer;
    final aiResponse = msg.aiResponse;

    final isEmergency = (answer?.isEmergency ?? false) || (aiResponse?.isEmergency ?? false);
    final emergencyText = (isArabic ? answer?.emergencyNoticeAr : answer?.emergencyNoticeEn) ??
        aiResponse?.emergencyAdvice ??
        'EMERGENCY WARNING: The symptoms described may indicate an acute cardiovascular or respiratory emergency. Seek emergency medical care immediately (Egyptian Ambulance 123).';

    final citations = answer?.citations.isNotEmpty == true
        ? answer!.citations
        : (aiResponse?.citations ?? const <MedicalCitation>[]);

    final providerTag = aiResponse?.providerName ?? 'Local Evidence RAG (Offline)';

    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131728) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmergency ? Colors.redAccent.withValues(alpha: 0.6) : (isDark ? Colors.white10 : Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider tag & timestamp header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      aiResponse?.isCloud == true ? Icons.cloud_outlined : Icons.shield_outlined,
                      size: 12,
                      color: AppColors.accentCyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      providerTag,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentCyan,
                      ),
                    ),
                  ],
                ),
              ),
              if (aiResponse?.latencyMs != null && aiResponse!.latencyMs > 0)
                Text(
                  '${aiResponse.latencyMs}ms',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Emergency Alert Box if triggered
          if (isEmergency) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      emergencyText,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Answer Body
          SelectableText(
            msg.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Evidence Citations Accordion
          if (citations.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: Colors.tealAccent),
                const SizedBox(width: 6),
                Text(
                  isArabic ? 'المصادر الطبية المعتمدة المستشهد بها:' : 'Authoritative Medical Sources:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...citations.map((c) => _buildCitationCard(c, isArabic, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildCitationCard(MedicalCitation citation, bool isArabic, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2036) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  citation.organization,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                ),
              ),
              Text(
                '${citation.year} • ${citation.license}',
                style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isArabic ? citation.titleAr : citation.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            isArabic ? 'القسم: ${citation.sectionHeadingAr}' : 'Section: ${citation.sectionHeading}',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          SelectableText(
            citation.sourceUrl,
            style: const TextStyle(fontSize: 10, color: Colors.cyan, decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }
}
