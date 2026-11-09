
import 'dart:math';

import 'package:flutter/material.dart';

// ------------------------------------------------------------
// QUESTION MODEL
// ------------------------------------------------------------

class McqQuestion {
  final String topic;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  const McqQuestion({
    required this.topic,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

// ------------------------------------------------------------
// QUESTION BANK: 50 BJT COMMON-EMITTER QUESTIONS
// ------------------------------------------------------------

const List<McqQuestion> mcqQuestionBank = [

  // TOPIC 1: BJT FUNDAMENTALS AND OPERATING REGIONS (1-10)

  McqQuestion(
    topic: 'BJT Fundamentals',
    question: 'What is the full form of BJT?',
    options: [
      'Binary Junction Transistor',
      'Bipolar Junction Transistor',
      'Basic Junction Technology',
      'Bilateral Junction Terminal',
    ],
    correctAnswer: 1,
    explanation: 'BJT stands for Bipolar Junction Transistor. It is a semiconductor device that uses both electrons and holes as charge carriers.',
  ),

  McqQuestion(
    topic: 'BJT Fundamentals',
    question: 'How many semiconductor regions are present in a BJT?',
    options: ['Two', 'Three', 'Four', 'Five'],
    correctAnswer: 1,
    explanation: 'A BJT consists of three semiconductor regions: emitter, base and collector.',
  ),

  McqQuestion(
    topic: 'BJT Fundamentals',
    question: 'Which of the following correctly identifies the three terminals of a BJT?',
    options: [
      'Gate, source and drain',
      'Anode, cathode and gate',
      'Emitter, base and collector',
      'Input, output and ground',
    ],
    correctAnswer: 2,
    explanation: 'The three terminals of a bipolar junction transistor are emitter, base and collector.',
  ),

  McqQuestion(
    topic: 'BJT Fundamentals',
    question: 'Which type of transistor is BC547?',
    options: [
      'PNP BJT',
      'NPN BJT',
      'N-channel MOSFET',
      'PN junction diode',
    ],
    correctAnswer: 1,
    explanation: 'BC547 is a general-purpose NPN bipolar junction transistor.',
  ),

  McqQuestion(
    topic: 'BJT Fundamentals',
    question: 'In an NPN transistor, the majority charge carriers are:',
    options: ['Holes', 'Electrons', 'Protons', 'Ions'],
    correctAnswer: 1,
    explanation: 'Electrons are the majority carriers in the N-type emitter and collector regions of an NPN transistor.',
  ),

  McqQuestion(
    topic: 'BJT Fundamentals',
    question: 'Which region of a BJT is generally very thin and lightly doped?',
    options: ['Emitter', 'Base', 'Collector', 'All three equally'],
    correctAnswer: 1,
    explanation: 'The base is thin and lightly doped so that most carriers injected by the emitter can cross it and reach the collector.',
  ),

  McqQuestion(
    topic: 'BJT Fundamentals',
    question: 'What is the primary function of the emitter region?',
    options: [
      'To inject charge carriers into the base',
      'To dissipate all circuit power',
      'To provide the output voltage only',
      'To block all charge carriers',
    ],
    correctAnswer: 0,
    explanation: 'The emitter is heavily doped so that it can inject a large number of majority carriers into the base.',
  ),

  McqQuestion(
    topic: 'BJT Fundamentals',
    question: 'Which relationship between transistor currents is correct?',
    options: [
      'IE = IC - IB',
      'IE = IC + IB',
      'IB = IE + IC',
      'IC = IE + IB',
    ],
    correctAnswer: 1,
    explanation: 'By Kirchhoff’s Current Law, emitter current is the sum of collector current and base current: IE = IC + IB.',
  ),

  McqQuestion(
    topic: 'BJT Fundamentals',
    question: 'Which operating region is used when a BJT works as a linear amplifier?',
    options: ['Cutoff', 'Saturation', 'Active', 'Breakdown'],
    correctAnswer: 2,
    explanation: 'The active region allows the collector current to be controlled by the base current, making amplification possible.',
  ),

  McqQuestion(
    topic: 'BJT Fundamentals',
    question: 'In the cutoff region, an ideal transistor behaves like:',
    options: [
      'A closed switch',
      'An open switch',
      'A constant-current source',
      'A short circuit between collector and emitter',
    ],
    correctAnswer: 1,
    explanation: 'In cutoff, both junctions are reverse biased and the transistor is ideally OFF, with negligible collector current.',
  ),

  // TOPIC 2: COMMON-EMITTER CONFIGURATION (11-18)

  McqQuestion(
    topic: 'Common-Emitter Configuration',
    question: 'Why is the common-emitter configuration called "common emitter"?',
    options: [
      'The emitter is connected to the input only',
      'The emitter is common to both input and output circuits',
      'The collector is grounded',
      'The base is common to both circuits',
    ],
    correctAnswer: 1,
    explanation: 'The emitter terminal is shared by the input circuit (base-emitter) and output circuit (collector-emitter).',
  ),

  McqQuestion(
    topic: 'Common-Emitter Configuration',
    question: 'In a common-emitter configuration, the input voltage is applied between:',
    options: [
      'Collector and emitter',
      'Base and collector',
      'Base and emitter',
      'Collector and ground only',
    ],
    correctAnswer: 2,
    explanation: 'The input is applied across the base-emitter junction.',
  ),

  McqQuestion(
    topic: 'Common-Emitter Configuration',
    question: 'In a common-emitter configuration, the output is taken between:',
    options: [
      'Base and emitter',
      'Collector and emitter',
      'Base and collector',
      'Base and ground only',
    ],
    correctAnswer: 1,
    explanation: 'The output voltage is measured between the collector and emitter terminals.',
  ),

  McqQuestion(
    topic: 'Common-Emitter Configuration',
    question: 'Which two transistor currents are primarily used to describe current gain in CE configuration?',
    options: [
      'Emitter current and collector current',
      'Collector current and base current',
      'Base current and emitter voltage',
      'Collector voltage and base voltage',
    ],
    correctAnswer: 1,
    explanation: 'The common-emitter current gain relates collector current to base current.',
  ),

  McqQuestion(
    topic: 'Common-Emitter Configuration',
    question: 'What is the approximate phase difference between input and output voltages of a CE amplifier?',
    options: ['0°', '90°', '180°', '360°'],
    correctAnswer: 2,
    explanation: 'A common-emitter amplifier produces an inverted output, corresponding to a phase difference of approximately 180°.',
  ),

  McqQuestion(
    topic: 'Common-Emitter Configuration',
    question: 'Which combination of gains can a common-emitter amplifier provide?',
    options: [
      'Only voltage gain',
      'Only current gain',
      'Both voltage and current gain',
      'Neither voltage nor current gain',
    ],
    correctAnswer: 2,
    explanation: 'A CE amplifier can provide both current gain and voltage gain, resulting in significant power gain.',
  ),

  McqQuestion(
    topic: 'Common-Emitter Configuration',
    question: 'For normal active-region operation of an NPN transistor, the base-emitter junction should be:',
    options: [
      'Forward biased',
      'Reverse biased',
      'Short-circuited',
      'Disconnected',
    ],
    correctAnswer: 0,
    explanation: 'The base-emitter junction is forward biased in the active region.',
  ),

  McqQuestion(
    topic: 'Common-Emitter Configuration',
    question: 'For normal active-region operation of an NPN transistor, the collector-base junction should be:',
    options: [
      'Forward biased',
      'Reverse biased',
      'Short-circuited',
      'Unconnected',
    ],
    correctAnswer: 1,
    explanation: 'The collector-base junction is reverse biased in the active region so that carriers are collected efficiently.',
  ),

  // TOPIC 3: INPUT CHARACTERISTICS (19-25)

  McqQuestion(
    topic: 'Input Characteristics',
    question: 'What is plotted on the input characteristic curve of a CE transistor?',
    options: [
      'IC versus VCE',
      'IB versus VBE',
      'IE versus VCE',
      'VCE versus IC',
    ],
    correctAnswer: 1,
    explanation: 'The input characteristic represents the variation of base current IB with base-emitter voltage VBE.',
  ),

  McqQuestion(
    topic: 'Input Characteristics',
    question: 'While plotting the input characteristics, which voltage is maintained constant?',
    options: ['VBE', 'VCE', 'VBB', 'IB'],
    correctAnswer: 1,
    explanation: 'For each input characteristic curve, VCE is maintained at a fixed value while VBE and IB are varied and measured.',
  ),

  McqQuestion(
    topic: 'Input Characteristics',
    question: 'The input characteristic of a CE transistor resembles the characteristic of which device?',
    options: [
      'A forward-biased diode',
      'A reverse-biased Zener diode',
      'A resistor',
      'An ideal capacitor',
    ],
    correctAnswer: 0,
    explanation: 'The base-emitter junction behaves like a forward-biased PN junction diode.',
  ),

  McqQuestion(
    topic: 'Input Characteristics',
    question: 'For a silicon BJT, the base-emitter voltage during normal conduction is typically around:',
    options: ['0.07 V', '0.7 V', '7 V', '70 V'],
    correctAnswer: 1,
    explanation: 'A silicon base-emitter junction commonly has a forward voltage around 0.6–0.7 V, depending on current and temperature.',
  ),

  McqQuestion(
    topic: 'Input Characteristics',
    question: 'The dynamic input resistance of a CE transistor is approximately:',
    options: [
      'ΔIB / ΔVBE',
      'ΔVBE / ΔIB',
      'ΔIC / ΔVCE',
      'VCE / IC',
    ],
    correctAnswer: 1,
    explanation: 'Dynamic input resistance is the change in base-emitter voltage divided by the corresponding change in base current, with VCE held constant.',
  ),

  McqQuestion(
    topic: 'Input Characteristics',
    question: 'What happens to base current when VBE is increased beyond the forward-conduction region?',
    options: [
      'It generally increases rapidly',
      'It always becomes zero',
      'It remains exactly constant',
      'It becomes equal to VCE',
    ],
    correctAnswer: 0,
    explanation: 'The forward-biased base-emitter junction conducts more strongly as VBE increases, causing IB to rise rapidly.',
  ),

  McqQuestion(
    topic: 'Input Characteristics',
    question: 'Why are input characteristic curves plotted for different values of VCE?',
    options: [
      'To observe the influence of VCE on the input behaviour',
      'To change the transistor type',
      'To measure only the power supply frequency',
      'To eliminate the base current',
    ],
    correctAnswer: 0,
    explanation: 'Comparing curves at different VCE values reveals how collector-emitter voltage affects the input characteristic.',
  ),

  // TOPIC 4: OUTPUT CHARACTERISTICS (26-32)

  McqQuestion(
    topic: 'Output Characteristics',
    question: 'What is plotted on the output characteristic curve of a CE transistor?',
    options: [
      'IB versus VBE',
      'IC versus VCE',
      'IE versus VBE',
      'VBE versus VCE',
    ],
    correctAnswer: 1,
    explanation: 'The output characteristic represents collector current IC as a function of collector-emitter voltage VCE.',
  ),

  McqQuestion(
    topic: 'Output Characteristics',
    question: 'While plotting one output characteristic curve, which quantity is kept constant?',
    options: ['VCE', 'IB', 'IC', 'VBE'],
    correctAnswer: 1,
    explanation: 'Each output curve corresponds to a fixed base current IB. Multiple curves are obtained by changing IB.',
  ),

  McqQuestion(
    topic: 'Output Characteristics',
    question: 'In the active region, for a fixed base current, collector current is ideally:',
    options: [
      'Nearly independent of VCE',
      'Always zero',
      'Exactly equal to VCE',
      'Directly proportional to VCE',
    ],
    correctAnswer: 0,
    explanation: 'In the ideal active region, IC is mainly controlled by IB and changes only slightly with VCE. Real transistors show a small slope due to the Early effect.',
  ),

  McqQuestion(
    topic: 'Output Characteristics',
    question: 'At very low VCE, a BJT may enter which operating region?',
    options: ['Active', 'Cutoff', 'Saturation', 'Breakdown'],
    correctAnswer: 2,
    explanation: 'At low collector-emitter voltage, the transistor may enter saturation, where both junctions are forward biased.',
  ),

  McqQuestion(
    topic: 'Output Characteristics',
    question: 'In the cutoff region, the collector current is:',
    options: [
      'Approximately zero, ignoring leakage',
      'Always maximum',
      'Equal to base current',
      'Independent of all junction conditions',
    ],
    correctAnswer: 0,
    explanation: 'In ideal cutoff, the transistor is OFF and collector current is zero. Real devices have a small leakage current.',
  ),

  McqQuestion(
    topic: 'Output Characteristics',
    question: 'What does the breakdown region indicate?',
    options: [
      'Normal linear amplification',
      'A junction voltage has exceeded its breakdown limit',
      'The transistor is in cutoff',
      'The base current is exactly zero',
    ],
    correctAnswer: 1,
    explanation: 'Breakdown occurs when a reverse-biased junction exceeds its rated breakdown voltage. Excessive current can damage the transistor.',
  ),

  McqQuestion(
    topic: 'Output Characteristics',
    question: 'The dynamic output resistance of a CE transistor at constant IB is approximately:',
    options: [
      'ΔIC / ΔVCE',
      'ΔVCE / ΔIC',
      'ΔVBE / ΔIB',
      'IC / IB',
    ],
    correctAnswer: 1,
    explanation: 'Dynamic output resistance is the change in VCE divided by the corresponding change in IC at constant IB.',
  ),

  // TOPIC 5: CURRENT GAIN, RESISTANCE AND CALCULATIONS (33-42)

  McqQuestion(
    topic: 'Calculations and Parameters',
    question: 'The DC current gain βDC in CE configuration is defined as:',
    options: [
      'IB / IC',
      'IC / IB',
      'IE / IC',
      'VCE / VBE',
    ],
    correctAnswer: 1,
    explanation: 'The DC common-emitter current gain is βDC = IC / IB.',
  ),

  McqQuestion(
    topic: 'Calculations and Parameters',
    question: 'The AC current gain βAC is defined as:',
    options: [
      'ΔIB / ΔIC',
      'ΔIC / ΔIB',
      'IC / IE',
      'VCE / IC',
    ],
    correctAnswer: 1,
    explanation: 'The small-signal current gain is βAC = ΔIC / ΔIB, measured around an operating point.',
  ),

  McqQuestion(
    topic: 'Calculations and Parameters',
    question: 'If IC = 4 mA and IB = 40 μA, what is βDC?',
    options: ['10', '40', '100', '400'],
    correctAnswer: 2,
    explanation: 'βDC = 4 mA / 40 μA = 4000 μA / 40 μA = 100.',
  ),

  McqQuestion(
    topic: 'Calculations and Parameters',
    question: 'If IC = 6 mA and βDC = 100, what is IB?',
    options: ['6 μA', '60 μA', '600 μA', '6 mA'],
    correctAnswer: 1,
    explanation: 'IB = IC / βDC = 6 mA / 100 = 0.06 mA = 60 μA.',
  ),

  McqQuestion(
    topic: 'Calculations and Parameters',
    question: 'If IB increases by 20 μA and IC increases by 2 mA, what is βAC?',
    options: ['10', '20', '100', '200'],
    correctAnswer: 2,
    explanation: 'βAC = ΔIC / ΔIB = 2 mA / 20 μA = 2000 μA / 20 μA = 100.',
  ),

  McqQuestion(
    topic: 'Calculations and Parameters',
    question: 'If IC = 9.5 mA and IB = 0.1 mA, what is the emitter current IE?',
    options: ['9.4 mA', '9.5 mA', '9.6 mA', '10.5 mA'],
    correctAnswer: 2,
    explanation: 'IE = IC + IB = 9.5 mA + 0.1 mA = 9.6 mA.',
  ),

  McqQuestion(
    topic: 'Calculations and Parameters',
    question: 'If βDC = 80 and IB = 50 μA, what is IC?',
    options: ['0.625 mA', '2 mA', '4 mA', '8 mA'],
    correctAnswer: 2,
    explanation: 'IC = βDC × IB = 80 × 50 μA = 4000 μA = 4 mA.',
  ),

  McqQuestion(
    topic: 'Calculations and Parameters',
    question: 'What is the SI unit of electrical resistance?',
    options: ['Volt', 'Ampere', 'Ohm', 'Watt'],
    correctAnswer: 2,
    explanation: 'Electrical resistance is measured in ohms (Ω).',
  ),

  McqQuestion(
    topic: 'Calculations and Parameters',
    question: 'Which expression represents the input resistance in a CE configuration?',
    options: [
      'ΔVBE / ΔIB at constant VCE',
      'ΔVCE / ΔIC at constant IB',
      'IC / IB',
      'IE / IB',
    ],
    correctAnswer: 0,
    explanation: 'The dynamic input resistance is obtained from the slope of the input characteristic: ΔVBE / ΔIB at constant VCE.',
  ),

  McqQuestion(
    topic: 'Calculations and Parameters',
    question: 'Which expression represents the output resistance in a CE configuration?',
    options: [
      'ΔVBE / ΔIB at constant VCE',
      'ΔVCE / ΔIC at constant IB',
      'IC / IB',
      'IB / IC',
    ],
    correctAnswer: 1,
    explanation: 'The dynamic output resistance is obtained from the slope of the output characteristic: ΔVCE / ΔIC at constant IB.',
  ),

  // TOPIC 6: LABORATORY INSTRUMENTS AND PRACTICAL VIVA (43-50)

  McqQuestion(
    topic: 'Laboratory Practice',
    question: 'Which instrument is used to measure current in a circuit?',
    options: ['Voltmeter', 'Ammeter', 'Oscilloscope only', 'Wattmeter'],
    correctAnswer: 1,
    explanation: 'An ammeter measures current and is connected in series with the branch being measured.',
  ),

  McqQuestion(
    topic: 'Laboratory Practice',
    question: 'How should a voltmeter be connected to measure the voltage across a component?',
    options: [
      'In series with the component',
      'In parallel with the component',
      'In place of the power supply',
      'Across an open switch only',
    ],
    correctAnswer: 1,
    explanation: 'A voltmeter is connected in parallel so it measures the potential difference across the component.',
  ),

  McqQuestion(
    topic: 'Laboratory Practice',
    question: 'Why is an ammeter connected in series?',
    options: [
      'So the branch current passes through it',
      'To increase the supply voltage',
      'To make the resistance infinite',
      'To bypass the component',
    ],
    correctAnswer: 0,
    explanation: 'A series connection ensures the current in the branch also flows through the ammeter. An ammeter has very low internal resistance.',
  ),

  McqQuestion(
    topic: 'Laboratory Practice',
    question: 'Why should the power supply generally be switched OFF before changing circuit connections?',
    options: [
      'To prevent accidental short circuits and component damage',
      'To increase transistor gain',
      'To make the voltmeter read zero permanently',
      'To change the transistor from NPN to PNP',
    ],
    correctAnswer: 0,
    explanation: 'Switching off the supply before rewiring reduces the risk of short circuits, accidental current flow and damage.',
  ),

  McqQuestion(
    topic: 'Laboratory Practice',
    question: 'Why is a resistor used in series with the base of a BJT?',
    options: [
      'To limit and control base current',
      'To increase the transistor size',
      'To eliminate the collector terminal',
      'To make the base-emitter junction reverse biased automatically',
    ],
    correctAnswer: 0,
    explanation: 'A base resistor limits current into the base and helps establish the desired operating condition.',
  ),

  McqQuestion(
    topic: 'Laboratory Practice',
    question: 'What is the main purpose of taking readings at several fixed values of base current in the output experiment?',
    options: [
      'To obtain a family of output characteristic curves',
      'To measure only the transistor temperature',
      'To find the colour code of the resistor',
      'To keep collector current at zero',
    ],
    correctAnswer: 0,
    explanation: 'Each selected base current produces one IC versus VCE curve. Together, these form the output characteristics.',
  ),

  McqQuestion(
    topic: 'Laboratory Practice',
    question: 'Which set of quantities is required to plot the input characteristic of a CE transistor?',
    options: [
      'IB and VBE at constant VCE',
      'IC and VCE at constant IB',
      'IE and VCE at constant VBE',
      'β and temperature only',
    ],
    correctAnswer: 0,
    explanation: 'The input characteristic is a plot of IB against VBE for a fixed VCE.',
  ),

  McqQuestion(
    topic: 'Laboratory Practice',
    question: 'Which set of quantities is required to plot the output characteristic of a CE transistor?',
    options: [
      'IB and VBE at constant VCE',
      'IC and VCE at constant IB',
      'IE and VBE at constant IC',
      'β and frequency only',
    ],
    correctAnswer: 1,
    explanation: 'The output characteristic is a plot of IC against VCE for a fixed IB.',
  ),
];

// ------------------------------------------------------------
// MCQ SCREEN
// ------------------------------------------------------------

class McqScreen extends StatefulWidget {
  const McqScreen({super.key});

  @override
  State<McqScreen> createState() => _McqScreenState();
}

class _McqScreenState extends State<McqScreen> {
  static const Color backgroundColor = Color(0xFF0F172A);
  static const Color cardColor = Color(0xFF1E293B);
  static const Color accentColor = Color(0xFF38BDF8);

  late List<McqQuestion> _quizQuestions;
  late List<int?> _selectedAnswers;

  int _currentQuestion = 0;
  bool _quizCompleted = false;

  @override
  void initState() {
    super.initState();
    _startNewQuiz();
  }

  // Select 10 different questions from the 50-question bank.
  void _startNewQuiz() {
    final shuffledQuestions = List<McqQuestion>.from(mcqQuestionBank);
    shuffledQuestions.shuffle(Random());

    _quizQuestions = shuffledQuestions.take(10).toList();
    _selectedAnswers = List<int?>.filled(10, null);

    _currentQuestion = 0;
    _quizCompleted = false;
  }

  int get _score {
    int result = 0;

    for (int i = 0; i < _quizQuestions.length; i++) {
      if (_selectedAnswers[i] == _quizQuestions[i].correctAnswer) {
        result++;
      }
    }

    return result;
  }

  void _selectAnswer(int optionIndex) {
    setState(() {
      _selectedAnswers[_currentQuestion] = optionIndex;
    });
  }

  void _goToPrevious() {
    if (_currentQuestion > 0) {
      setState(() {
        _currentQuestion--;
      });
    }
  }

  void _goToNext() {
    if (_selectedAnswers[_currentQuestion] == null) return;

    if (_currentQuestion < 9) {
      setState(() {
        _currentQuestion++;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    setState(() {
      _quizCompleted = true;
    });
  }

  void _restartQuiz() {
    setState(() {
      _startNewQuiz();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: _quizCompleted ? _buildResults() : _buildQuestionScreen(),
      ),
    );
  }

  // ----------------------------------------------------------
  // QUESTION VIEW
  // ----------------------------------------------------------

  Widget _buildQuestionScreen() {
    final question = _quizQuestions[_currentQuestion];
    final selectedAnswer = _selectedAnswers[_currentQuestion];

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            const Icon(Icons.quiz, color: accentColor, size: 27),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'MCQ Practice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${_currentQuestion + 1} / 10',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_currentQuestion + 1) / 10,
            minHeight: 7,
            backgroundColor: Colors.white12,
            color: accentColor,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          question.topic.toUpperCase(),
          style: const TextStyle(
            color: accentColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            question.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 20),

        ...List.generate(question.options.length, (index) {
          final isSelected = selectedAnswer == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => _selectAnswer(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withOpacity(0.15)
                      : cardColor,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.white12,
                    width: isSelected ? 1.7 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? accentColor : Colors.white54,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        question.options[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 12),

        Row(
          children: [
            if (_currentQuestion > 0)
              OutlinedButton(
                onPressed: _goToPrevious,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),
                child: const Text('Previous'),
              ),

            const Spacer(),

            FilledButton(
              onPressed: selectedAnswer == null ? null : _goToNext,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: backgroundColor,
                disabledBackgroundColor: Colors.white12,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
              ),
              child: Text(
                _currentQuestion == 9 ? 'Submit quiz' : 'Next',
              ),
            ),
          ],
        ),

        if (selectedAnswer == null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Select an option to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // ----------------------------------------------------------
  // RESULTS VIEW
  // ----------------------------------------------------------

  Widget _buildResults() {
    final percentage = (_score * 10).toString();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 12),

        const Icon(
          Icons.emoji_events_rounded,
          color: Colors.amber,
          size: 65,
        ),

        const SizedBox(height: 12),

        const Text(
          'Quiz Completed!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accentColor.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Text(
                '$_score / 10',
                style: const TextStyle(
                  color: accentColor,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$percentage% accuracy',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: _score / 10,
                minHeight: 8,
                backgroundColor: Colors.white12,
                color: accentColor,
              ),
              const SizedBox(height: 12),
              Text(
                _score >= 8
                    ? 'Excellent performance!'
                    : _score >= 5
                        ? 'Good effort. Keep practising.'
                        : 'Revise the concepts and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'ANSWER REVIEW',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.3,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 12),

        ...List.generate(_quizQuestions.length, (index) {
          final question = _quizQuestions[index];
          final selected = _selectedAnswers[index];
          final isCorrect = selected == question.correctAnswer;

          return Container(
            margin: const EdgeInsets.only(bottom: 13),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCorrect
                    ? Colors.green.withOpacity(0.7)
                    : Colors.redAccent.withOpacity(0.7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${index + 1}. ${question.question}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  'Your answer: ${selected == null ? 'Not answered' : question.options[selected]}',
                  style: TextStyle(
                    color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Correct answer: ${question.options[question.correctAnswer]}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  question.explanation,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 10),

        FilledButton.icon(
          onPressed: _restartQuiz,
          icon: const Icon(Icons.refresh),
          label: const Text('Try another 10 questions'),
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
