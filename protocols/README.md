# Protocols

Protocols are **natural language workflow instructions** that knight agents follow step by step. They are the "runbooks" of the Round Table — describing *when* to execute, *what tools to use*, *what decisions to make*, and *what output to produce*.

## How Protocols Work

A protocol is a markdown file that a knight reads and executes. The knight (an LLM agent) interprets the instructions, invokes the referenced skills/scripts, makes judgments about the data, and produces output (usually via a template).

## Structure

Each protocol includes:
- **When to use** — triggers and scheduling
- **Prerequisites** — required skills and access
- **Steps** — ordered instructions the knight follows
- **Expected output** — what gets produced
- **Error handling** — what to do when things go wrong

## Organization

```
protocols/
├── security/     # Threat monitoring and security workflows
├── comms/        # Communication triage and digests
└── intel/        # Intelligence gathering and reporting
```

## Writing Protocols

Write protocols as if instructing a capable but literal assistant. Be specific about:
- Which scripts to run and with what arguments
- How to interpret results (what counts as "critical"?)
- What format the output should take
- When to escalate vs. handle autonomously
