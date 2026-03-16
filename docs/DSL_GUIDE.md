# OMNI DSL: The Semantic Distillation Guide

OMNI DSL (Declarative Semantic Language) allows you to transform chaotic tool output into high-density intelligence without writing a single line of Zig code.

## Core Concepts

OMNI DSL works by scanning input for a **trigger** and then applying a set of **capture rules** to extract meaningful data which is then formatted into a final **output**.

### 1. The Trigger
The `trigger` is a unique string that tells OMNI, "Hey, this line (and the block it belongs to) is something I know how to distill."
- **Good Trigger**: `"On branch"`, `"Step 1/"`, `"npm notice"`
- **Bad Trigger**: `"a"`, `" "` (too common, hurts performance)

### 2. Capture Rules (`rules`)
Rules define how to extract variables from the noisy text.

| Action | Description | Result |
| :--- | :--- | :--- |
| **`keep`** | Captures a substring into a variable. | `{branch} -> "main"` |
| **`count`** | Increments a counter every time a pattern matches. | `{mod} -> 5` |

### 3. Output Formatting
The `output` string is your final distilled result. You can use `{variable_names}` anywhere in this string.

---

## Practical Examples

### Example A: Git Status (Built-in Reference)
Turns 20 lines of `git status` into a 1-line summary.

```json
{
  "name": "git-status-decl",
  "trigger": "On branch",
  "rules": [
    { "capture": "On branch {branch}", "action": "keep" },
    { "capture": "modified: {file}", "action": "count", "as": "mod" },
    { "capture": "deleted: {file}", "action": "count", "as": "del" }
  ],
  "output": "git({branch}) | {mod} mod, {del} del"
}
```

### Example B: Build Log Optimizer
Focus on what matters in a long build log.

```json
{
  "name": "build-summ",
  "trigger": "Successfully built",
  "rules": [
    { "capture": "Step {curr}/{total}", "action": "keep" },
    { "capture": "Removing intermediate container {id}", "action": "count", "as": "cleaned" }
  ],
  "output": "Build Complete: {curr}/{total} steps | {cleaned} layers cleaned"
}
```

### Example C: AWS EC2 List Optimizer
Turns heavy AWS CLI JSON/Table output into a lean status line.

```json
{
  "name": "aws-ec2-optimizer",
  "trigger": "INSTANCE",
  "rules": [
    { "capture": "INSTANCE {id} {type} {state}", "action": "keep" }
  ],
  "output": "EC2:{id} ({type}) -> {state}"
}
```

### Example D: Python Tracer
Distills deep Python tracebacks into just the root cause and location.

```json
{
  "name": "python-error-distill",
  "trigger": "Traceback",
  "rules": [
    { "capture": "File \"{file}\", line {line}, in {func}", "action": "keep" },
    { "capture": "Error: {msg}", "action": "keep" }
  ],
  "output": "PyError in {func} ({file}:{line}) | {msg}"
}
```

---

## Performance Tips

OMNI is optimized for sub-millisecond latency. To keep it that way:
1.  **Be Specific**: The more specific your `trigger`, the faster OMNI can skip irrelevant noise.
2.  **Order Matters**: Place your most frequent patterns at the top of the `rules` list.
3.  **No Overlap**: Avoid creating multiple filters with the same `trigger`.

## Testing Your Filter
Once you've added your filter to `core/omni_config.json`, simply run:
```bash
your_command | omni distill
```
OMNI will automatically reload the configuration and apply your new DSL rules.

---
*Powered by Zig. Optimized for Agents. Distilled for Intelligence.*
