# Report Skill

Create structured reports for technical findings, test results, and analysis.

## Usage

```
/report <topic>
```

## Report Format

All reports follow this structure:

1. **Discord Summary** (at the top, marked with HTML comments)
2. **Full Report** (detailed analysis below)

### File Naming

Reports are saved to `reports/YYMMDD_SLUG.md` where:
- `YYMMDD` is the current date (e.g., 260130 for 2026-01-30)
- `SLUG` is a brief descriptive name in SCREAMING_SNAKE_CASE

Example: `reports/260130_CREATE2_COLLISION_FAILURES.md`

---

## Discord Summary Rules

The Discord summary appears at the top of every report, wrapped in HTML comment markers for easy identification. It must follow these rules:

### Character Limit
- **Maximum 1900 characters** (buffer under Discord's 2000 limit)
- Check with `wc -c` before finalizing

### Formatting Rules
1. **NO TABLES** - Discord doesn't render markdown tables
2. Use code blocks for tabular data instead:
   ```
   Item A (count) - description
   Item B (count) - description
   ```
3. Use `**bold**` for emphasis (Discord supports this)
4. Use `### Headings` for sections (Discord supports h3)
5. Use numbered lists for action items
6. Wrap URLs in angle brackets: `<https://example.com>` to prevent embeds

### Required Sections
1. **Title** - `## Short Descriptive Title`
2. **Metadata** - Client, suite, counts on one line with `|` separators
3. **Summary** - 1-2 sentences explaining the finding
4. **Data** - Key findings in code block format
5. **Analysis** - Root cause in 2-3 sentences
6. **Impact** - Severity assessment in 1-2 sentences
7. **Next Steps** - Numbered list of actions
8. **Link** - Full report URL

### Template

```markdown
<!-- DISCORD SUMMARY (paste everything between the markers) -->
## [Title]: [Key Metric]

**[Context]:** [value] | **[Context2]:** [value2]
**[Metric]:** [numbers]

[1-2 sentence summary of what was found]

### [Section Name]

```
[Data in code block - NOT a table]
```

### Analysis

**Root cause:** [Brief explanation]

**[Relevant spec/standard]** [How it relates to the finding]

### Impact

**[Severity] for [context]** - [Why and what it means practically]

### Next Steps
1. [Action item]
2. [Action item]
3. [Action item]

**Full report:** <[URL]>
<!-- END DISCORD SUMMARY -->
```

---

## Full Report Sections

After the Discord summary, include a horizontal rule (`---`) and the full report:

### Required Sections

1. **Title** (`# Full Report`)
2. **Metadata** - Date, test suite, client version
3. **Summary** - Executive summary paragraph
4. **Context** - Why this report exists, what was being tested
5. **Detailed Findings** - All data with tables, logs, specifics
6. **Root Cause Analysis** - Technical deep-dive
7. **Impact Assessment** - Severity, relevance, real-world implications
8. **Recommendations** - Short-term, medium-term, long-term actions
9. **References** - Links to specs, repos, related docs
10. **Appendix** - Log locations, raw data references

### Formatting

- Use tables freely in the full report (GitHub renders them)
- Include code blocks for log excerpts
- Link to specific files with `file:line` notation
- Reference external specs with full URLs

---

## When Invoked

1. Gather all relevant data (logs, test results, metrics)
2. Analyze root cause and impact
3. Draft Discord summary first (ensures conciseness)
4. Verify Discord summary is under 1900 characters
5. Write full report with complete details
6. Save to `reports/YYMMDD_SLUG.md`
7. Output the Discord summary for easy copy-paste
