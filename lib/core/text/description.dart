/// The Description of an *Other* Expense (glossary: Description), as it is
/// saved and displayed: outer whitespace removed.
String normalizeDescription(String raw) => raw.trim();

/// Whether [raw] is empty once normalized (FR-11: "נדרש תיאור או בחירת
/// קטגוריה").
bool isBlankDescription(String raw) => normalizeDescription(raw).isEmpty;
