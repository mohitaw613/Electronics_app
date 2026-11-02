import 'package:flutter/material.dart';

/// Automatically splits notebook text into finer chunks based on a tight 
/// line limit for small screens, increasing total pages so text never crams or clips.
List<String> paginateNotebookContent(String fullContent, {int maxLinesPerPage = 7}) {
  final List<String> rawBlocks = fullContent.split(RegExp(r'\n\s*\n'));
  final List<String> pages = [];
  
  StringBuffer currentPage = StringBuffer();
  int currentLines = 0;

  for (String block in rawBlocks) {
    final List<String> blockLines = block.split('\n');
    
    // If a single block is massive, break it down line by line
    if (blockLines.length >= maxLinesPerPage) {
      if (currentPage.isNotEmpty) {
        pages.add(currentPage.toString().trim());
        currentPage.clear();
        currentLines = 0;
      }
      
      for (int i = 0; i < blockLines.length; i += maxLinesPerPage) {
        final int end = (i + maxLinesPerPage < blockLines.length) ? i + maxLinesPerPage : blockLines.length;
        pages.add(blockLines.sublist(i, end).join('\n'));
      }
      continue;
    }

    if (currentLines + blockLines.length > maxLinesPerPage && currentLines > 0) {
      pages.add(currentPage.toString().trim());
      currentPage.clear();
      currentLines = 0;
    }

    if (currentPage.isNotEmpty) {
      currentPage.writeln('\n');
    }
    currentPage.write(block);
    currentLines += blockLines.length;
  }

  if (currentPage.isNotEmpty) {
    pages.add(currentPage.toString().trim());
  }

  if (pages.isEmpty) {
    pages.add(fullContent);
  }

  return pages;
}
