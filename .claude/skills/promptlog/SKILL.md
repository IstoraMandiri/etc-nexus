# Promptlog Skill

Generate a chronological log of user prompts and AI responses from Claude CLI sessions for this project.

## Purpose

Creates `PROMPTLOG.md` containing all substantive prompts from this project's sessions, organized by session with summaries and response context. Useful for:
- Documenting what work was done
- Understanding the evolution of a project
- Session handoffs between agents

## Usage

```
/promptlog
```

## Process

### Step 1: Extract session data

Run the extraction script to gather prompts and responses:

```bash
node << 'SCRIPT'
const fs = require('fs');
const path = require('path');
const os = require('os');

const cwd = process.cwd();
const encoded = cwd.replace(/\//g, '-');
const sessionsDir = path.join(os.homedir(), '.claude/projects', encoded);
const outputFile = path.join(os.tmpdir(), 'promptlog-data.json');

if (!fs.existsSync(sessionsDir)) {
  console.log('No sessions found for this project.');
  process.exit(0);
}

function redactSensitive(text) {
  return text
    .replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, '[UUID]')
    .replace(/\/dev\/[a-z]+[0-9]*/gi, '[DEVICE]')
    .replace(/\/(snap|home|boot|mnt|media|var|tmp|etc)\/[^\s,)]+/gi, '[PATH]')
    .replace(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/g, '[IP]')
    .replace(/([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}/g, '[MAC]')
    .replace(/\b(i|ami|vol|snap|sg|vpc|subnet|eni|igw|rtb|acl|nat)-[0-9a-f]{8,17}\b/gi, '[AWS-ID]')
    .replace(/\b(sk_live_|sk_test_|ghp_|gho_|ghu_|ghs_|ghr_|xox[baprs]-)[A-Za-z0-9_-]+/g, '[TOKEN]')
    .replace(/\b[0-9a-f]{16,}\b/gi, '[HEX]')
    .replace(/\b\d+(\.\d+)?[KMGTP]i?B?\b/gi, '[SIZE]')
    .replace(/\b\d{6,}\b/g, '[NUM]')
    .replace(/\bloop\d+\b/gi, '[LOOP]')
    .replace(/\b[vs]d[a-z]\d*\b/gi, '[PART]')
    .replace(/\b\d+:\d+\b/g, '[DEV-ID]');
}

function collapseIfHeavilyRedacted(original, redacted) {
  const count = (redacted.match(/\[[A-Z-]+\]/g) || []).length;
  if (count > 5) {
    if (original.includes('MAJ:MIN') || original.includes('MOUNTPOINTS')) return '[system: lsblk output]';
    if (original.includes('resize2fs')) return '[system: resize2fs output]';
    if (original.includes('Filesystem') && original.includes('Size')) return '[system: df output]';
    return '[system: command output]';
  }
  return redacted;
}

function getTextContent(content) {
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) {
    return content.filter(c => c.type === 'text').map(c => c.text).join(' ');
  }
  return '';
}

const files = fs.readdirSync(sessionsDir).filter(f => f.endsWith('.jsonl') && !f.startsWith('agent-'));
const sessions = new Map();

for (const file of files) {
  const lines = fs.readFileSync(path.join(sessionsDir, file), 'utf8').trim().split('\n');
  for (const line of lines) {
    try {
      const obj = JSON.parse(line);
      if (!obj.sessionId || !obj.timestamp) continue;

      const sid = obj.sessionId;
      if (!sessions.has(sid)) sessions.set(sid, { messages: [] });

      if (obj.type === 'user' && !obj.isMeta) {
        const text = getTextContent(obj.message?.content);
        if (!text || text.startsWith('<command-name>') || text.startsWith('<local-command-') || text.includes('tool_result')) continue;
        if (!text.trim()) continue;
        const redacted = redactSensitive(text.replace(/\n+/g, ' ').replace(/\s+/g, ' ').trim());
        const cleaned = collapseIfHeavilyRedacted(text, redacted);
        sessions.get(sid).messages.push({ type: 'user', ts: obj.timestamp, content: cleaned });
      }

      if (obj.type === 'assistant') {
        const text = getTextContent(obj.message?.content);
        if (!text.trim()) continue;
        const redacted = redactSensitive(text.replace(/\n+/g, ' ').replace(/\s+/g, ' ').trim()).slice(0, 1000);
        const cleaned = collapseIfHeavilyRedacted(text, redacted);
        sessions.get(sid).messages.push({ type: 'assistant', ts: obj.timestamp, content: cleaned });
      }
    } catch {}
  }
}

const sorted = [...sessions.entries()]
  .map(([sid, data]) => {
    data.messages.sort((a, b) => a.ts.localeCompare(b.ts));
    return { id: sid, messages: data.messages };
  })
  .filter(s => s.messages.some(m => m.type === 'user'))
  .sort((a, b) => a.messages[0]?.ts.localeCompare(b.messages[0]?.ts));

fs.writeFileSync(outputFile, JSON.stringify(sorted, null, 2));
console.log('Extracted ' + sorted.length + ' sessions to ' + outputFile);
SCRIPT
```

### Step 2: Read extracted data

Read the JSON file at `$TMPDIR/promptlog-data.json`.

### Step 3: Generate PROMPTLOG.md

Create the markdown file with these guidelines:

**Session filtering**: Skip minor/meta sessions such as:
- Sessions where the only prompt is running promptlog itself
- Sessions titled or focused on "Promptlog Update" or "Promptlog Generation"
- Sessions with only 1-2 trivial prompts (e.g., just "go ahead" or similar)

**Redaction**: Apply additional redaction when writing prompts to PROMPTLOG.md:
- Replace sensitive values (IPs, paths, tokens, hashes, UUIDs) with `[redacted: description]`
- For a single redaction: `[redacted: IP address]`, `[redacted: file path]`, `[redacted: token]`
- For multiple similar redactions, collapse into one: `[redacted: 5 IP addresses]`, `[redacted: log output]`
- For heavily redacted content (system output, logs, etc.): `[redacted: command output]` or `[redacted: system info]`
- Keep the prompt readable and understandable after redaction

**For each included session**:

1. **Heading**: `## Session N: [Descriptive Title]`
   - Title should be max 10 words summarizing the main work done

2. **Description**: One paragraph explaining what was accomplished and the outcome

3. **Messages**: Show conversation flow:
   - **User prompts**: `> **YYYY-MM-DD HH:MM** — [prompt text]`
   - **AI responses** (including the final one): `*[One-line summary of what the AI did]*`

**AI response summaries should**:
- Be italicized (`*...*`)
- Be concise (one line)
- Describe the action taken or answer given
- Always include the final response in each session (this shows the outcome)

**Always include the full prompt text** - never truncate user prompts (but do apply redaction).

### Step 4: Report completion

Tell the user:
- How many sessions were processed
- How many were included vs filtered
- Brief summary of what was redacted (e.g., "Redacted 3 IP addresses, 2 file paths, and some system output")
- That PROMPTLOG.md has been updated

## Output Format Example

```markdown
# Prompt Log

A chronological record of user prompts from Claude CLI sessions.

---

## Session 1: Set up project plan for feature X

Discussed requirements and created implementation plan. Decided on approach A over B due to performance considerations.

> **2025-12-27 06:33** — Create a plan.md file that outlines the project

*Created plan.md with project overview, tech stack decisions, and three implementation phases.*

> **2025-12-27 06:35** — What about using approach B instead?

*Explained trade-offs: approach A has better performance but more complexity; approach B is simpler but slower for large datasets.*

> **2025-12-27 06:36** — Let's go with A, update the plan

*Updated plan.md to use approach A, added performance benchmarks section.*

---
```

## Redaction Example

Original prompt:
> Check the server at 192.168.1.50 and look at /home/user/secrets/config.json, the token is ghp_abc123xyz and commit abcdef1234567890

Redacted:
> Check the server at [redacted: IP address] and look at [redacted: file path], the token is [redacted: token] and commit [redacted: hash]

For heavily redacted content:
> Here's my lsblk output: [redacted: system info]

Multiple similar items:
> These IPs are failing: [redacted: 5 IP addresses]
