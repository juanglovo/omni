# OMNI DSL: The Semantic Distillation Guide

OMNI DSL (Declarative Semantic Language) allows you to transform chaotic tool output into high-density intelligence without writing a single line of Zig code.

---

## Quick Start: Starter Template
The easiest way to start is to generate a template using the CLI:
```bash
omni generate config > omni_config.json
```

---

## Root Configuration Structure
Your `omni_config.json` is organized into two primary sections:

| Field | Type | Description |
| :--- | :--- | :--- |
| **`rules`** | `Array<Rule>` | Fast, exact-match filters (Global). Good for simple masking or removals. |
| **`dsl_filters`** | `Array<DslFilter>` | Advanced semantic distillation blocks for multi-line context. |

---

## Practical Examples: Deep Dive

### 1. Docker Build Log Distillation
**Purpose**: Docker builds generate hundreds of lines of "Removing intermediate container" or step metadata. OMNI collapses this into a single progress line.

```json
{
  "name": "docker-optimizer",
  "trigger": "Successfully built",
  "rules": [
    { "capture": "Step {curr}/{total}", "action": "keep" },
    { "capture": "Removing intermediate container {id}", "action": "count", "as": "cleans" }
  ],
  "output": "Docker: {curr}/{total} steps complete | {cleans} layers garbage-collected"
}
```
- **Logic**: It waits for the build completion message. Then it looks back to find how many steps there were and how many temporary layers it cleaned up.
- **Result**: `100 lines` -> `Docker: 12/12 steps complete | 8 layers garbage-collected`.

### 2. Kubernetes Pod Status Monitor
**Purpose**: `kubectl get pods` displays a wide table. OMNI can distill it into a health-check signature.

```json
{
  "name": "k8s-pod-check",
  "trigger": "NAME",
  "rules": [
    { "capture": "{pod_name} {ready} {status} {restarts}", "action": "keep" }
  ],
  "output": "K8s health: {pod_name} is {status} (Restarts: {restarts})"
}
```
- **Logic**: Triggered by the header `NAME`. It captures the essential status columns into a human-ready (and agent-readable) format.
- **Result**: `Wide table` -> `K8s health: api-server-v2 is Running (Restarts: 0)`.

### 3. NPM/Yarn Security Audit Summary
**Purpose**: Security audits are verbose. OMNI focuses only on the vulnerability counts.

```json
{
  "name": "npm-audit-distill",
  "trigger": "vulnerabilities",
  "rules": [
    { "capture": "{high} high", "action": "keep" },
    { "capture": "{crit} critical", "action": "keep" }
  ],
  "output": "Security: {high} High, {crit} Critical vulns found."
}
```
- **Logic**: Scans for the summary line containing "vulnerabilities" and extracts only the severity counts.
- **Result**: `Full report` -> `Security: 2 High, 0 Critical vulns found.`

### 4. Test Runner (Jest/Vitest) Optimizer
**Purpose**: Large test suites produce thousands of lines. Use OMNI to surface only the final result count.

```json
{
  "name": "test-results",
  "trigger": "Test Suites:",
  "rules": [
    { "capture": "{passed} passed", "action": "keep" },
    { "capture": "{failed} failed", "action": "keep" }
  ],
  "output": "Tests: {passed} PASSED | {failed} FAILED"
}
```
- **Logic**: Triggered by the "Test Suites:" summary line. Captures counts across all test files.
- **Result**: `Massive log` -> `Tests: 142 PASSED | 0 FAILED`.

---

## Advanced Features

### 1. Variables & Captures
Use curly braces: `{variable_name}` to extract text.
- OMNI is greedy: it captures everything until the next literal in your pattern.
- Patterns match line-by-line within the context window after a trigger.

### 2. The `count` Action
Increments a virtual counter for every match. Perfect for repetitive patterns (like log entries or deleted files).
```json
{ "capture": "modified: {file}", "action": "count", "as": "mod_count" }
```

### 3. Action Types
- **`keep`**: Captures a string. If matched multiple times, the last one wins.
- **`count`**: Increments an accumulator.

---

## Troubleshooting

- **Trigger doesn't fire**: Check for hidden whitespace or special characters (colors/ANSI) in the raw output.
- **Variables are empty**: Ensure there is a unique literal string before or after your `{variable}` so OMNI knows where it starts and ends.
- **Too much output**: Use the global `rules` to `remove` lines before they hit the DSL engine.

---
*Powered by Zig. Distilled for Intelligence.*
