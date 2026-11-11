import 'package:flutter/material.dart';

/// 장르를 선택하는 BottomSheet
/// 드래그로 높이를 조절할 수 있고, 목록만 스크롤되며 확인 버튼은 하단에 고정됨
class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({super.key, this.selected = const {}});

  /// 처음 열렸을 때 체크되어 있을 장르
  final Set<String> selected;

  static const genres = ['드라마', '액션', '코미디'];

  /// BottomSheet를 띄우고, 확인을 누르면 선택한 장르를 반환
  static Future<Set<String>?> show(
    BuildContext context, {
    Set<String> selected = const {},
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      // DraggableScrollableSheet로 높이를 조절하려면 true
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => GenreFilterSheet(selected: selected),
    );
  }

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<String> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 목록만 남은 공간에서 스크롤되도록 Expanded로 감쌈
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: GenreFilterSheet.genres.length,
                itemBuilder: (context, index) {
                  final genre = GenreFilterSheet.genres[index];
                  return CheckboxListTile(
                    title: Text(genre),
                    value: _selected.contains(genre),
                    onChanged: (checked) {
                      setState(() {
                        if (checked ?? false) {
                          _selected.add(genre);
                        } else {
                          _selected.remove(genre);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: const Text('확인'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
