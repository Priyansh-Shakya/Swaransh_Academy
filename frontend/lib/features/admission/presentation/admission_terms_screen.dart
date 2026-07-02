import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';

//! T&C Language Provider
final termsLanguageProvider = StateProvider<bool>((ref) => true);
// true = English
// false = Hindi

class LanguageChip extends ConsumerWidget {
  const LanguageChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eng = ref.watch(termsLanguageProvider);

    return ActionChip(
      label: Text(eng ? 'हिं' : 'Eng'),
      onPressed: () {
        debugPrint('T&C language toggled: ${!eng ? 'Eng' : 'Hin'}');
        ref.read(termsLanguageProvider.notifier).state = !eng;
      },
    );
  }
}

class AdmissionTermsScreen extends ConsumerStatefulWidget {
  const AdmissionTermsScreen({super.key});

  @override
  ConsumerState<AdmissionTermsScreen> createState() =>
      _AdmissionTermsScreenState();
}

class _AdmissionTermsScreenState extends ConsumerState<AdmissionTermsScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: AppColors.ivory,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _StepIndicator(current: 2, total: 3),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                // 💡 Watch the data strictly inside the Consumer builder block using innerRef
                final isEnglish = ref.watch(termsLanguageProvider);
                final currentTerms = isEnglish ? _terms : _terms_hindi;

                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please read carefully',
                            style: AppTypography.headlineLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'By proceeding to payment you agree to all terms below.',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          ...currentTerms.map(
                            (t) => _TermsClause(
                              number: t.$1,
                              title: t.$2,
                              body: t.$3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                    //! Place language chip at bottom so that it is at Top of Stack
                    Positioned(top: 10, right: 10, child: const LanguageChip()),
                  ],
                );
              },
            ),
          ),
          // Fixed bottom bar: checkbox + button
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _accepted,
                      activeColor: AppColors.gold,
                      onChanged: (v) => setState(() => _accepted = v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        'I have read and agree to the Terms & Conditions of '
                        'Swaransh Academy of Music & Art.',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _accepted
                        ? () => context.push('/admission/payment')
                        : null,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Text('Continue to Payment'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsClause extends StatefulWidget {
  const _TermsClause({
    required this.number,
    required this.title,
    required this.body,
  });
  final int number;
  final String title;
  final String body;

  @override
  State<_TermsClause> createState() => _TermsClauseState();
}

class _TermsClauseState extends State<_TermsClause> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${widget.number}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(widget.body, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: List.generate(total, (i) {
          final active = i < current;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: active ? AppColors.gold : AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---- Terms content - edit here ----
// Tuple: (clause number, title, body text)
const _terms = [
  (
    1,
    'Admission & Registration',
    'Admission is confirmed only after successful submission of the admission form and payment of the applicable fees. '
        'Students/Parents are responsible for providing accurate information. Any false or misleading information may result '
        'in cancellation of admission.',
  ),
  (
    2,
    'Fee Structure',
    'The course fee includes professional instruction, use of academy musical instruments (where applicable), '
        'instrument usage and maintenance, and access to academy practice facilities during scheduled class hours.',
  ),
  (
    3,
    'Registration Charges',
    'Registration/Admission charges cover administrative processing, student registration, documentation, '
        'profile creation, and batch allocation. These charges are one-time, non-refundable, and non-transferable.',
  ),
  (
    4,
    'Fee Payment',
    'Fees are payable as per the selected payment cycle (Monthly/Quarterly/Half-Yearly/Yearly). '
        'Classes are conducted according to the academy schedule. Continued non-payment may result in suspension '
        'or cancellation of classes.',
  ),
  (
    5,
    'Refund Policy',
    'All fees paid to the academy are generally non-refundable. In exceptional and genuine circumstances, '
        'the academy may, at its sole discretion, approve a partial refund after deducting the non-refundable '
        'registration charges, the value of classes already attended, and any applicable administrative charges. '
        'The academy\'s decision regarding refunds shall be final.',
  ),
  (
    6,
    'Teaching Methodology',
    'Music education consists of instructor-guided teaching combined with supervised self-practice. '
        'Teachers provide demonstrations, corrections, monitoring, and personalized guidance throughout the class. '
        'Students are expected to practice independently during portions of the session. Continuous one-to-one '
        'supervision for the entire class duration is not part of the academy\'s teaching methodology.',
  ),
  (
    7,
    'Attendance & Practice',
    'Regular attendance and consistent personal practice are essential for musical progress. '
        'Students are expected to actively participate during classes and practice independently as instructed.',
  ),
  (
    8,
    'Missed Classes',
    'Students who are unable to attend classes should inform the academy in advance whenever possible. '
        'Missed classes may be adjusted only in accordance with the academy\'s policy and management approval.',
  ),
  (
    9,
    'Instrument Usage',
    'Students shall handle academy instruments with care. Any intentional damage, negligence, or misuse '
        'may result in repair or replacement charges being recovered from the responsible student.',
  ),
  (
    10,
    'Discipline & Behaviour',
    'Students and accompanying persons are expected to maintain respectful behaviour within academy premises. '
        'Misconduct, abusive language, harassment, creating disturbances, or damage to academy property may '
        'result in immediate cancellation of admission without refund and may invite legal action where necessary.',
  ),
  (
    11,
    'Batch & Faculty',
    'The academy reserves the right to change batch timings, class schedules, or assign substitute instructors '
        'whenever required for operational or academic reasons.',
  ),
  (
    12,
    'Holidays & Closures',
    'The academy shall remain closed on notified holidays or due to unavoidable circumstances. '
        'Classes affected by such closures shall be managed according to the academy\'s academic schedule.',
  ),
  (
    13,
    'Media & Photography',
    'The academy may photograph or record classes, performances, or events for promotional or educational purposes. '
        'Students who object must notify the academy in writing at the time of admission.',
  ),
  (
    14,
    'Personal Belongings',
    'The academy is not responsible for the loss, theft, or damage of students\' personal belongings. '
        'Students are advised to keep their valuables secure at all times.',
  ),
  (
    15,
    'Learning Outcomes',
    'The academy provides professional guidance and training. Musical progress depends upon the student\'s attendance, '
        'practice, dedication, and aptitude. The academy does not guarantee examination results, competition success, '
        'professional opportunities, or any specific level of performance.',
  ),
  (
    16,
    'Parent/Guardian Interaction',
    'Parents and guardians are requested not to interfere with the teaching methodology or disrupt ongoing classes. '
        'Any concerns or feedback should be discussed with academy management outside class hours.',
  ),
  (
    17,
    'Acceptance of Terms',
    'By submitting the admission form, the student and/or parent/guardian confirms that all information provided '
        'is accurate, has read and understood these Terms & Conditions, and agrees to abide by all academy rules '
        'and decisions made by the academy management.',
  ),
  (
    18,
    'Late Arrival',
    'Students are expected to arrive on time for their scheduled classes. Time lost due to late arrival '
        'may not be compensated by extending the class duration.',
  ),
  (
    19,
    'Academy Property',
    'Furniture, instruments, books, electronic equipment, and other academy property shall be used responsibly. '
        'Any intentional damage or misuse may result in repair or replacement charges.',
  ),
];

const _terms_hindi = [
  (
    1,
    'प्रवेश एवं पंजीकरण',
    'प्रवेश तभी मान्य होगा जब प्रवेश प्रपत्र सफलतापूर्वक जमा किया जाए तथा निर्धारित शुल्क का भुगतान किया जाए। '
        'विद्यार्थी/अभिभावक द्वारा दी गई सभी जानकारी सही होना आवश्यक है। गलत या भ्रामक जानकारी पाए जाने पर '
        'अकादमी प्रवेश निरस्त करने का अधिकार सुरक्षित रखती है।',
  ),
  (
    2,
    'शुल्क संरचना',
    'पाठ्यक्रम शुल्क में व्यावसायिक प्रशिक्षण, अकादमी के वाद्य यंत्रों का उपयोग (जहाँ लागू हो), '
        'वाद्य यंत्रों के रख-रखाव एवं निर्धारित कक्षा समय के दौरान अभ्यास सुविधाओं का उपयोग सम्मिलित है।',
  ),
  (
    3,
    'पंजीकरण शुल्क',
    'पंजीकरण/प्रवेश शुल्क में प्रशासनिक प्रक्रिया, विद्यार्थी पंजीकरण, दस्तावेज़ीकरण, '
        'विद्यार्थी प्रोफ़ाइल निर्माण एवं बैच आवंटन सम्मिलित हैं। यह शुल्क एकमुश्त, '
        'अप्रतिदेय (Non-Refundable) तथा अहस्तांतरणीय (Non-Transferable) है।',
  ),
  (
    4,
    'शुल्क भुगतान',
    'शुल्क मासिक, त्रैमासिक, अर्धवार्षिक अथवा वार्षिक योजना के अनुसार देय होगा। '
        'कक्षाएँ अकादमी के निर्धारित समय-सारणी के अनुसार संचालित होंगी। निर्धारित समय पर शुल्क न जमा करने की स्थिति में '
        'अकादमी कक्षाएँ स्थगित अथवा प्रवेश निरस्त कर सकती है।',
  ),
  (
    5,
    'शुल्क वापसी नीति',
    'अकादमी में जमा किया गया शुल्क सामान्यतः वापस नहीं किया जाएगा। '
        'विशेष एवं वास्तविक परिस्थितियों में अकादमी अपने विवेकानुसार आंशिक शुल्क वापसी पर विचार कर सकती है। '
        'ऐसी स्थिति में अप्रतिदेय पंजीकरण शुल्क, ली गई कक्षाओं का शुल्क तथा लागू प्रशासनिक शुल्क काटने के बाद '
        'शेष राशि लौटाई जा सकती है। शुल्क वापसी संबंधी अकादमी का निर्णय अंतिम एवं मान्य होगा।',
  ),
  (
    6,
    'शिक्षण पद्धति',
    'संगीत शिक्षा में शिक्षक द्वारा मार्गदर्शन एवं विद्यार्थी द्वारा स्व-अभ्यास दोनों समान रूप से आवश्यक हैं। '
        'शिक्षक प्रदर्शन, त्रुटि सुधार, मार्गदर्शन एवं प्रगति की निगरानी करेंगे। '
        'विद्यार्थियों से अपेक्षा की जाती है कि वे कक्षा के दौरान निर्धारित समय में स्वयं अभ्यास करें। '
        'पूरी कक्षा अवधि में प्रत्येक विद्यार्थी को लगातार व्यक्तिगत रूप से पढ़ाना अकादमी की शिक्षण पद्धति का भाग नहीं है।',
  ),
  (
    7,
    'उपस्थिति एवं अभ्यास',
    'संगीत में प्रगति हेतु नियमित उपस्थिति एवं निरंतर अभ्यास आवश्यक है। '
        'विद्यार्थियों से अपेक्षा की जाती है कि वे कक्षा में सक्रिय रूप से भाग लें तथा शिक्षक के निर्देशानुसार अभ्यास करें।',
  ),
  (
    8,
    'अनुपस्थित कक्षाएँ',
    'यदि विद्यार्थी किसी कारणवश कक्षा में उपस्थित नहीं हो सकता है तो यथासंभव पूर्व सूचना देना आवश्यक है। '
        'छूटी हुई कक्षाओं का समायोजन केवल अकादमी की नीति एवं प्रबंधन की स्वीकृति के अनुसार किया जाएगा।',
  ),
  (
    9,
    'वाद्य यंत्रों का उपयोग',
    'विद्यार्थी अकादमी के वाद्य यंत्रों का सावधानीपूर्वक उपयोग करेंगे। '
        'जानबूझकर की गई क्षति, लापरवाही अथवा दुरुपयोग की स्थिति में मरम्मत अथवा प्रतिस्थापन का खर्च संबंधित विद्यार्थी से लिया जा सकता है।',
  ),
  (
    10,
    'अनुशासन एवं व्यवहार',
    'विद्यार्थी एवं उनके साथ आने वाले सभी व्यक्तियों से अकादमी परिसर में सम्मानजनक व्यवहार की अपेक्षा की जाती है। '
        'दुर्व्यवहार, अभद्र भाषा, उत्पीड़न, झगड़ा, अव्यवस्था फैलाना अथवा अकादमी की संपत्ति को नुकसान पहुँचाना '
        'प्रवेश निरस्त किए जाने तथा आवश्यक होने पर कानूनी कार्यवाही का आधार बन सकता है।',
  ),
  (
    11,
    'बैच एवं शिक्षक',
    'शैक्षणिक अथवा प्रशासनिक आवश्यकताओं के अनुसार अकादमी बैच समय, कक्षा कार्यक्रम '
        'या शिक्षक में परिवर्तन करने का अधिकार सुरक्षित रखती है।',
  ),
  (
    12,
    'अवकाश एवं अवरोध',
    'घोषित अवकाश अथवा अपरिहार्य परिस्थितियों में अकादमी बंद रह सकती है। '
        'ऐसी स्थिति में कक्षाओं का संचालन अकादमी की शैक्षणिक योजना के अनुसार किया जाएगा।',
  ),
  (
    13,
    'फोटोग्राफी एवं वीडियो रिकॉर्डिंग',
    'अकादमी कक्षाओं, प्रस्तुतियों अथवा कार्यक्रमों के फोटो एवं वीडियो प्रचार अथवा शैक्षणिक उद्देश्य से उपयोग कर सकती है। '
        'यदि किसी विद्यार्थी को इस पर आपत्ति हो तो प्रवेश के समय लिखित रूप में सूचित करना आवश्यक होगा।',
  ),
  (
    14,
    'व्यक्तिगत सामान',
    'विद्यार्थियों के व्यक्तिगत सामान की हानि, चोरी अथवा क्षति के लिए अकादमी उत्तरदायी नहीं होगी। '
        'विद्यार्थियों से अपने कीमती सामान की सुरक्षा स्वयं करने का अनुरोध किया जाता है।',
  ),
  (
    15,
    'शैक्षणिक परिणाम',
    'अकादमी गुणवत्तापूर्ण प्रशिक्षण एवं मार्गदर्शन प्रदान करती है। '
        'विद्यार्थी की प्रगति उसकी उपस्थिति, अभ्यास, समर्पण एवं व्यक्तिगत क्षमता पर निर्भर करती है। '
        'अकादमी किसी परीक्षा, प्रतियोगिता, व्यावसायिक सफलता अथवा किसी निश्चित स्तर की उपलब्धि की गारंटी नहीं देती।',
  ),
  (
    16,
    'अभिभावक सहभागिता',
    'अभिभावकों से अनुरोध है कि वे कक्षा के दौरान शिक्षण प्रक्रिया में हस्तक्षेप न करें तथा कक्षा का वातावरण बाधित न करें। '
        'किसी भी सुझाव अथवा समस्या पर चर्चा कक्षा समय के अतिरिक्त अकादमी प्रबंधन से की जा सकती है।',
  ),
  (
    17,
    'नियमों की स्वीकृति',
    'प्रवेश प्रपत्र जमा करने के साथ विद्यार्थी एवं/अथवा अभिभावक यह स्वीकार करते हैं कि उनके द्वारा दी गई सभी जानकारी सही है, '
        'उन्होंने इन नियमों एवं शर्तों को पढ़ एवं समझ लिया है तथा अकादमी के सभी नियमों एवं निर्णयों का पालन करेंगे।',
  ),
  (
    18,
    'विलंब से आगमन',
    'विद्यार्थियों से निर्धारित समय पर कक्षा में उपस्थित होने की अपेक्षा की जाती है। '
        'देर से आने के कारण खोया हुआ समय कक्षा की अवधि बढ़ाकर पूरा नहीं किया जाएगा।',
  ),
  (
    19,
    'अकादमी की संपत्ति',
    'फर्नीचर, वाद्य यंत्र, पुस्तकें, इलेक्ट्रॉनिक उपकरण एवं अकादमी की अन्य संपत्ति का उपयोग सावधानीपूर्वक किया जाना चाहिए। '
        'जानबूझकर की गई क्षति अथवा दुरुपयोग की स्थिति में मरम्मत या प्रतिस्थापन का खर्च संबंधित विद्यार्थी से वसूला जा सकता है।',
  ),
];
