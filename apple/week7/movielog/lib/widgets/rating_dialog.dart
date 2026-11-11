import 'package:flutter/material.dart';

import '../data/models/rating_request.dart';
import '../theme/app_theme.dart';
import '../view_models/submit_status.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

/// 평점 등록·수정에 함께 쓰는 Dialog — 별점(1~5 정수) + 선택 코멘트
///
/// 저장 로직은 [onSubmit] 콜백으로 받아 Dialog 안에서 실행합니다.
/// - [onSubmit]이 예외 없이 끝나면 `true`를 반환하며 닫힙니다.
/// - 취소를 누르면 [onSubmit]을 호출하지 않고 `false`를 반환합니다. (API 요청 없음)
/// - 실패하면 닫지 않고 입력을 그대로 둔 채 오류 문구를 보여줘 다시 시도할 수 있게 합니다.
/// - 저장 중에는 버튼 로딩, 입력 잠금, 뒤로가기([PopScope]) 차단.
///   바깥 탭은 호출부의 `barrierDismissible: false`로 막습니다.
///
/// 수정할 때는 [initialScore]·[initialComment]에 기존 값을 넣어 채운 채로 엽니다.
/// Dialog 안에서 값을 바꾸는 동안 원본 평점 객체는 건드리지 않으므로 취소 시 복구할 것이 없습니다.
///
/// W3-05/06 디자인(제목·별 5개·다시 선택하기)을 이어받고, 별점 아래 코멘트 입력과
/// 취소·확인 버튼을 더했습니다.
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.title = '영화는 어떠셨나요?',
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });

  final String title;

  /// 0이면 아직 별을 고르지 않은 상태 — 확인 버튼이 꺼져 있습니다.
  final int initialScore;
  final String? initialComment;

  /// 빈 코멘트는 null로 바꿔 전달합니다.
  final Future<void> Function(int score, String? comment) onSubmit;

  static const int maxCommentLength = 500;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  String? _errorText;

  /// 다시 선택하기를 누를 때마다 바뀌어 별점 입력을 처음 상태(0점)로 새로 만듭니다.
  /// RatingBar는 처음 받은 값만 그리기 때문에 key를 바꿔야 화면이 초기화됩니다.
  int _resetCount = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _score = 0;
      _resetCount++;
    });
  }

  Future<void> _onConfirm() async {
    final trimmed = _commentController.text.trim();
    if (trimmed.length > RatingDialog.maxCommentLength) {
      setState(() => _errorText = '코멘트는 500자 이하로 입력해 주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await widget.onSubmit(_score, trimmed.isEmpty ? null : trimmed);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = error is WriteFailure
            ? error.message
            : '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PopScope(
      // 저장 중에는 시스템 뒤로가기·스와이프로 닫히지 않게 합니다.
      canPop: !_isSubmitting,
      // 컨테이너 — 너비 342 (좌우 24 여백), padding 24, 배경 #FAF9F5
      child: Dialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        // 모서리 반경은 Figma 수치가 없어 M3 Dialog 기본값(28)을 사용합니다.
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SizedBox(
          width: double.infinity,
          // 키보드가 올라와도 코멘트 칸이 가려지지 않도록 스크롤 가능하게 합니다.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 제목 — 박스 높이 27, Manrope 700 / 20, #25232A
                SizedBox(
                  height: 27,
                  child: Center(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppTheme.dialogTitle,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Center(
                  child: MovieRatingInput(
                    key: ValueKey(_resetCount),
                    rating: _score.toDouble(),
                    enabled: !_isSubmitting,
                    // 1점 단위 입력이지만 서버로 보내기 전 정수인지 한 번 더 확인합니다.
                    onChanged: (value) =>
                        setState(() => _score = validateServerScore(value)),
                  ),
                ),
                const SizedBox(height: 16),
                // 다시 선택하기 (W3-06) — 별점을 골랐을 때만 표시
                SizedBox(
                  height: 19,
                  child: _score > 0
                      ? Center(
                          child: InkWell(
                            onTap: _isSubmitting ? null : _reset,
                            borderRadius: BorderRadius.circular(4),
                            // Manrope 700 / 14, #6750A4
                            child: Text(
                              '다시 선택하기',
                              style: AppTheme.dialogTextAction.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                // 코멘트 — 선택 입력, 최대 500자
                TextField(
                  controller: _commentController,
                  enabled: !_isSubmitting,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: RatingDialog.maxCommentLength,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: '코멘트를 남겨보세요 (선택)',
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _errorText!,
                    style: TextStyle(color: colors.error, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: MovieLogButton(
                        label: '취소',
                        width: double.infinity,
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MovieLogButton(
                        label: '확인',
                        width: double.infinity,
                        isLoading: _isSubmitting,
                        // 별을 고르기 전(0점)에는 코멘트가 있어도 확인할 수 없습니다.
                        onPressed: _score > 0 && !_isSubmitting
                            ? _onConfirm
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
