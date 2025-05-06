import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skillpe/services/base_url.dart';
import '../components/header_component.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/progress_slider_component.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuizPage extends StatefulWidget {
  final String? quizId;
  final String? courseId;
  final String? roadmapId;
  final String? contentId;
  final String title;
  final bool isLastContent;

  const QuizPage({
    Key? key,
    this.quizId,
    this.courseId,
    this.roadmapId,
    this.contentId,
    this.title = 'Quiz',
    this.isLastContent = false,
  }) : super(key: key);

  // Factory constructor to create from route arguments
  static QuizPage fromRouteArguments(Map<String, dynamic> args) {
    return QuizPage(
      title: args['title'] ?? 'Quiz',
      quizId: args['quizId'],
      courseId: args['courseId'],
      roadmapId: args['roadmapId'],
      contentId: args['contentId'],
      isLastContent: args['isLastContent'] ?? false,
    );
  }

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // API related
  String baseUrl = getBaseUrl();
  String? _authToken;

  // Quiz state
  bool _isLoading = true;
  int _currentQuestionNumber = 1;
  String _questionId = '';
  String _questionText = '';
  String _questionType = ''; // 'mcq', 'poll', or 'input'
  int _totalQuestions = 0;
  List<Map<String, dynamic>> _options = [];

  // User interaction state
  String? _selectedOptionId;
  bool _hasSubmitted = false;
  bool _isCorrect = false;
  Map<String, dynamic> _pollResults = {};
  Map<String, dynamic> _pollSummary = {};
  TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    // Log parameters for debugging
    debugPrint('QuizPage initialized with:');
    debugPrint('quizId: ${widget.quizId}');
    debugPrint('courseId: ${widget.courseId}');
    debugPrint('roadmapId: ${widget.roadmapId}');
    debugPrint('contentId: ${widget.contentId}');
    debugPrint('isLastContent: ${widget.isLastContent}');
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // Load auth token from SharedPreferences
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    // Fetch the first question after getting the auth token
    _fetchCurrentQuestion();
  }

  // Fetch the current question
  Future<void> _fetchCurrentQuestion() async {
    if (widget.quizId == null) {
      debugPrint('ERROR: Quiz ID is missing');
      setState(() {
        _isLoading = false;
        _questionText = 'Quiz ID is required';
      });
      return;
    }

    debugPrint('======== FETCH QUESTION ========');
    debugPrint('Quiz ID: ${widget.quizId}');
    debugPrint('Fetching question number: $_currentQuestionNumber');

    setState(() {
      _isLoading = true;
      _hasSubmitted = false;
      _selectedOptionId = null;
      _isCorrect = false;
      _pollResults = {};
      _pollSummary = {};
      _inputController.clear();
    });

    try {
      final String url =
          '$baseUrl/quiz/${widget.quizId}/question/$_currentQuestionNumber';
      debugPrint('Request URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Question API response: $data');

        if (data['success'] == true) {
          final previousTotal = _totalQuestions;

          setState(() {
            _questionId = data['questionId'] ?? '';
            _questionText = data['question'] ?? 'No question provided';
            _questionType = data['type'] ?? 'mcq';
            _totalQuestions = data['totalQuestions'] ?? 1;

            // Parse options for MCQ and poll questions
            if (_questionType == 'mcq' || _questionType == 'poll') {
              _options =
                  (data['options'] as List)
                      .map<Map<String, dynamic>>(
                        (option) => {
                          'id': option['_id'],
                          'text': option['option'],
                          'percentage': 0,
                          'votes': 0,
                        },
                      )
                      .toList();
            }

            _isLoading = false;
          });

          debugPrint('Question loaded successfully');
          debugPrint('Question ID: $_questionId');
          debugPrint('Question type: $_questionType');
          debugPrint(
            'Total questions updated from $previousTotal to $_totalQuestions',
          );
          debugPrint(
            'Is this the last question? ${_currentQuestionNumber == _totalQuestions ? 'YES' : 'NO'}',
          );
        } else {
          debugPrint('ERROR: API returned success: false');
          setState(() {
            _isLoading = false;
            _questionText = 'Failed to load question';
          });
        }
      } else {
        debugPrint('ERROR: API returned status ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _questionText = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('ERROR: Exception occurred: $e');
      setState(() {
        _isLoading = false;
        _questionText = 'Error loading question: $e';
      });
    }

    debugPrint('================================');
  }

  // Submit the user's answer
  Future<void> _submitAnswer() async {
    if (widget.quizId == null || _questionId.isEmpty) {
      debugPrint('Cannot submit answer: quizId or questionId is missing');
      return;
    }

    debugPrint('Starting answer submission process');
    debugPrint('Question type: $_questionType');
    debugPrint('Current question: $_currentQuestionNumber of $_totalQuestions');

    if (_questionType == 'mcq' || _questionType == 'poll') {
      if (_selectedOptionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an option')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    // Prepare request payload
    final Map<String, dynamic> payload = {
      'questionId': _questionId,
      'courseId': widget.courseId,
    };

    // Add answer based on question type
    if (_questionType == 'mcq' || _questionType == 'poll') {
      payload['answer'] = _selectedOptionId;
    } else if (_questionType == 'input') {
      payload['answer'] = _inputController.text;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quiz/answer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode(payload),
      );

      debugPrint('Answer API response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('Submit answer response: $data');

        setState(() {
          _hasSubmitted = true;

          if (_questionType == 'mcq') {
            _isCorrect = data['isCorrect'] ?? false;
          } else if (_questionType == 'poll' && data['pollResults'] != null) {
            _pollResults = data['pollResults'];
            _pollSummary = data['pollSummary'] ?? {};

            // Update options with poll results
            for (var option in _options) {
              final optionId = option['id'];
              if (_pollResults.containsKey(optionId)) {
                final pollResult = _pollResults[optionId];
                option['percentage'] = pollResult['percentage'] ?? 0;
                option['votes'] = pollResult['count'] ?? 0;
                option['isSelected'] = pollResult['isSelected'] ?? false;
              }
            }
          }

          _isLoading = false;
        });
      } else {
        debugPrint(
          'Error submitting answer: ${response.statusCode} ${response.body}',
        );
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting answer: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting answer: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting answer: $e')));
    }
  }

  // Move to the next question
  void _nextQuestion() {
    debugPrint('_nextQuestion called');
    debugPrint('Current question: $_currentQuestionNumber of $_totalQuestions');
    debugPrint('isLastQuestion: ${isLastQuestion}');

    if (!isLastQuestion) {
      debugPrint('Moving to next question');
      setState(() {
        _currentQuestionNumber++;
      });
      _fetchCurrentQuestion();
    } else {
      debugPrint('Last question completed, updating progress');
      // Quiz is completed, update progress and navigate to roadmaps
      _updateProgress();
    }
  }

  // Update progress after completing the quiz
  Future<void> _updateProgress() async {
    debugPrint('_updateProgress called');
    debugPrint('QuizId: ${widget.quizId}');
    debugPrint('CourseId: ${widget.courseId}');
    debugPrint('RoadmapId: ${widget.roadmapId}');
    debugPrint('ContentId: ${widget.contentId}');
    debugPrint('IsLastContent: ${widget.isLastContent}');

    // Choose contentId for API call (prefer the dedicated contentId if available)
    final String? contentIdForProgress = widget.contentId ?? widget.quizId;

    if (widget.courseId == null ||
        widget.roadmapId == null ||
        contentIdForProgress == null) {
      debugPrint(
        'Missing required parameters for progress update, navigating without update',
      );
      _navigateToRoadmaps();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Prepare request payload
      final Map<String, dynamic> payload = {
        'contentId': contentIdForProgress,
        'roadmapId': widget.roadmapId,
        'courseId': widget.courseId,
      };

      debugPrint('Updating progress with payload: $payload');

      final response = await http.post(
        Uri.parse('$baseUrl/application/update-progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode(payload),
      );

      debugPrint('Update progress API response status: ${response.statusCode}');

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('Update progress response: $data');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress updated successfully!')),
        );

        // Check if this is the last content and navigate accordingly
        if (widget.isLastContent) {
          debugPrint('This is the last content, navigating to completion page');
          Navigator.pushReplacementNamed(
            context,
            '/completed-roadmap',
            arguments: {'courseTitle': widget.title},
          );
          return; // Exit early to avoid calling _navigateToRoadmaps
        }
      } else {
        debugPrint(
          'Error updating progress: ${response.statusCode} ${response.body}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating progress: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating progress: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating progress: $e')));
    }

    // Navigate to roadmaps for non-last content or if API failed
    debugPrint('Now navigating to roadmaps page');
    _navigateToRoadmaps();
  }

  // Navigate to roadmaps page
  void _navigateToRoadmaps() {
    debugPrint('Navigating back to roadmaps page');
    Navigator.pushReplacementNamed(
      context,
      '/roadmaps',
      arguments: {'courseId': widget.courseId},
    );
  }

  void _resetQuestion() {
    setState(() {
      _hasSubmitted = false;
      _selectedOptionId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: HeaderComponent(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            ProgressSliderComponent(
              currentValue: _currentQuestionNumber,
              totalValue: _totalQuestions > 0 ? _totalQuestions : 1,
              isEnabled: false,
              progressColor: const Color(0xFF00CC99),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              height: 1,
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : const Color.fromRGBO(0, 0, 0, 0.12),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),

            _isLoading
                ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
                : Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors:
                            isDark
                                ? [
                                  theme.colorScheme.surface.withValues(
                                    alpha: 0.5,
                                  ),
                                  theme.scaffoldBackgroundColor,
                                ]
                                : [
                                  const Color(
                                    0xFFFFF9C4,
                                  ).withValues(alpha: 0.5),
                                  Colors.white,
                                ],
                        stops: const [0.0, 0.4],
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: SvgPicture.asset(
                                  'assets/svg/quiz_bulb.svg',
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.scaleDown,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Text(
                                  _questionText,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.43,
                                    letterSpacing: 0.14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              bottom: 16.0,
                              top: 16.0,
                            ),
                            child:
                                _questionType == 'mcq' ||
                                        _questionType == 'poll'
                                    ? _buildOptionsView()
                                    : _buildInputView(),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildControlsArea(),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _options.length,
      itemBuilder: (context, index) {
        final option = _options[index];
        final isSelected = _selectedOptionId == option['id'];

        // Determine card styling based on question type and submission state
        Color borderColor =
            isDark ? theme.colorScheme.outline : const Color(0xFFE5E5E5);
        Color backgroundColor =
            isDark ? theme.colorScheme.surface : Colors.white;
        Color textColor =
            isDark
                ? theme.textTheme.bodyMedium!.color!
                : const Color(0xFF111111);
        double borderWidth = 1.0;

        if (_hasSubmitted) {
          if (_questionType == 'mcq') {
            if (isSelected) {
              if (_isCorrect) {
                borderColor = const Color(0xFF00CC99);
                backgroundColor =
                    isDark
                        ? const Color(0xFF00CC99).withValues(alpha: 0.2)
                        : const Color(0xFFEBFFFA);
                textColor = const Color(0xFF00CC99);
                borderWidth = 2.0;
              } else {
                borderColor = const Color(0xFFFE4E4E);
                backgroundColor =
                    isDark
                        ? const Color(0xFFFE4E4E).withValues(alpha: 0.2)
                        : const Color(0xFFFFECEC);
                textColor = const Color(0xFFFE4E4E);
                borderWidth = 2.0;
              }
            }
          } else if (_questionType == 'poll' && option['isSelected'] == true) {
            borderColor = theme.colorScheme.primary;
            backgroundColor =
                isDark
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : const Color(0xFFFEFEF1);
            borderWidth = 2.0;
          }
        } else if (isSelected) {
          borderColor = theme.colorScheme.primary;
          backgroundColor =
              isDark
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : const Color(0xFFFEFEF1);
          borderWidth = 2.0;
        }

        return GestureDetector(
          onTap:
              _hasSubmitted
                  ? null
                  : () {
                    setState(() {
                      _selectedOptionId = option['id'];
                    });
                  },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: borderWidth),
              color:
                  (!_hasSubmitted || _questionType != 'poll')
                      ? backgroundColor
                      : null,
              gradient:
                  (_hasSubmitted && _questionType == 'poll')
                      ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors:
                            isDark
                                ? [
                                  const Color.fromARGB(255, 209, 216, 6),
                                  const Color.fromARGB(
                                    255,
                                    227,
                                    218,
                                    33,
                                  ).withValues(alpha: 0.2),
                                  Colors.black.withValues(alpha: 0.5),
                                ]
                                : [
                                  const Color(0xFFF7F5A1),
                                  const Color(
                                    0xFFF7F5A1,
                                  ).withValues(alpha: 0.2),
                                  Colors.white.withValues(alpha: 0.5),
                                ],
                        stops: [
                          0.0,
                          option['percentage'] / 100 * 0.9,
                          option['percentage'] / 100,
                        ],
                      )
                      : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        option['text'],
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.67,
                          letterSpacing: 0.12,
                          fontFeatures: const [
                            FontFeature.proportionalFigures(),
                            FontFeature.enable('dlig'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    if (_hasSubmitted && _questionType == 'poll')
                      Text(
                        '${option['percentage']}% (${option['votes']} ${option['votes'] > 1 ? 'votes' : 'vote'})',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          color: !isDark ? Color(0xFF111111) : Colors.white,
                        ),
                      )
                    else
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color:
                            isSelected ? const Color(0xFFECE713) : Colors.grey,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputView() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type your answer:',
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.43,
            letterSpacing: 0.14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _inputController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            hintText: 'Enter your answer here',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          maxLines: 5,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.67,
            letterSpacing: 0.12,
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildControlsArea() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_hasSubmitted && _questionType == 'mcq')
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Text(
                _isCorrect ? 'Correct!' : 'Wrong answer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color:
                      _isCorrect
                          ? const Color(0xFF00CC99)
                          : const Color(0xFFFE4E4E),
                ),
              ),
            ),
          if (_hasSubmitted && _questionType == 'poll')
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Poll Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: isDark ? Colors.white : Color(0xFF111111),
                ),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_hasSubmitted) {
                  if (_questionType == 'mcq' && !_isCorrect) {
                    _resetQuestion(); // Try again for wrong MCQ answers
                  } else {
                    if (isLastQuestion) {
                      _updateProgress(); // Update progress and navigate to roadmaps
                    } else {
                      _nextQuestion(); // Move to next question
                    }
                  }
                } else {
                  if (_questionType == 'input' &&
                      _inputController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your answer')),
                    );
                  } else {
                    _submitAnswer();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(),
                foregroundColor: _getButtonTextColor(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                _getButtonText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_hasSubmitted) {
      if (_questionType == 'mcq' && !_isCorrect) {
        return 'Try Again';
      } else {
        return _currentQuestionNumber < _totalQuestions ? 'Continue' : 'Finish';
      }
    } else {
      return 'Submit';
    }
  }

  Color _getButtonColor() {
    if (_hasSubmitted) {
      if (_questionType == 'mcq') {
        return _isCorrect ? const Color(0xFF00CC99) : const Color(0xFFFFA726);
      } else {
        return const Color(0xFF3C96FF);
      }
    } else {
      return const Color(0xFFECE713);
    }
  }

  Color _getButtonTextColor() {
    if (_hasSubmitted) {
      return Colors.white;
    } else {
      return const Color(0xFF111111);
    }
  }

  bool get isLastQuestion {
    debugPrint(
      'isLastQuestion check: _currentQuestionNumber=$_currentQuestionNumber, _totalQuestions=$_totalQuestions',
    );
    return _currentQuestionNumber >= _totalQuestions;
  }
}
