import 'package:flutter/material.dart';

class NotebookPageSpread extends StatelessWidget {
  final String title;
  final String content;
  final int pageNumber;
  final Widget? leftChild;
  final bool wrapLongLines;

  const NotebookPageSpread({
    super.key,
    required this.title,
    required this.content,
    required this.pageNumber,
    this.leftChild,
    this.wrapLongLines = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final pagePadding = isMobile ? 6.0 : 16.0;
        final fontSize = isMobile ? 9.0 : 12.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          margin: EdgeInsets.all(isMobile ? 2 : 8),
          padding: EdgeInsets.all(pagePadding),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEFA),
            border: Border.all(color: const Color(0xFFC5B99F), width: 1.2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: isMobile ? 8.5 : 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 65),
                    child: Text(
                      'Page $pageNumber',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: isMobile ? 8.5 : 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF777777),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 8, thickness: 1),
              const SizedBox(height: 2),
              Expanded(
                child:
                    leftChild ??
                    LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        final text = Text(
                          content,
                          softWrap: wrapLongLines,
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: fontSize,
                            height: 1.35,
                            color: const Color(0xFF2C2C2C),
                          ),
                        );

                        if (wrapLongLines) {
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: SizedBox(
                              width: bodyConstraints.maxWidth,
                              child: text,
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          physics: const ClampingScrollPhysics(),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: bodyConstraints.maxWidth,
                              ),
                              child: text,
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
