---
name: autoresearch
description: >
  Autonomous skill optimization through iterative experimentation. Inspired by Karpathy's autoresearch — systematically improves knight skills by modifying instructions, testing via dispatch, scoring results, and keeping only improvements.
---

# Autoresearch — Autonomous Skill Optimization

Iteratively improve a target knight's skills through systematic experimentation.
Each experiment: hypothesize → modify → test → score → keep/revert.

## Quick Start

When you receive a task, it should specify:
- **target_knight**: Which knight to optimize (e.g., `galahad`)
- **target_skill**: Which skill file to optimize (e.g., `security/threat-briefing/SKILL.md`)
- **eval_prompt**: The fixed evaluation prompt to test against
- **max_generations**: How many experiments to run (default: 50)

If not specified, defaults to optimizing Galahad's `threat-briefing` skill.

## The Loop

### Step 1: Setup
```bash
# Create working directory
mkdir -p /data/autoresearch/snapshots /data/autoresearch/experiments

# Clone the arsenal repo for skill editing
cd /data && git clone https://github.com/dapperdivers/roundtable-arsenal.git arsenal-work 2>/dev/null || (cd /data/arsenal-work && git pull)

# Save the baseline skill
cp /data/arsenal-work/<target_skill> /data/autoresearch/snapshots/gen-000-baseline.md
cp /data/arsenal-work/<target_skill> /data/autoresearch/snapshots/current-best.md
```

### Step 2: Run Baseline (Generation 0)
Dispatch the eval prompt to the target knight and score the result.
This establishes the baseline score to beat.

### Step 3: Experiment Loop

For each generation N (1 to max_generations):

#### 3a. Hypothesize
Based on the scoring rubric feedback and experiment history, form a specific
hypothesis about what ONE change to the SKILL.md will improve the score.

**Good hypotheses** (specific, testable):
- "Adding explicit MITRE ATT&CK mapping instructions will improve the depth score"
- "Reordering data source priority to check CISA KEV before OpenCTI will improve relevance"
- "Adding a 'Detection Opportunities' section requirement will improve detection_engineering score"
- "Removing the weekly summary template reference will reduce confusion and improve signal_to_noise"

**Bad hypotheses** (vague, multi-variable):
- "Make the skill better" (not testable)
- "Rewrite the entire workflow" (too many changes at once)

#### 3b. Modify
Edit ONLY the target SKILL.md file. Save a snapshot:
```bash
cp /data/arsenal-work/<target_skill> /data/autoresearch/snapshots/gen-<N>-pre.md
# ... make your edit ...
cp /data/arsenal-work/<target_skill> /data/autoresearch/snapshots/gen-<N>-post.md
```

**IMPORTANT**: The target knight reads skills from its arsenal git-sync mount.
You cannot modify the knight's live skill directly. Instead, you must:

1. Edit the skill locally in your workspace
2. Include the modified skill content IN the eval task prompt, like:
   ```
   For this task, use the following skill instructions instead of your default:
   
   <skill>
   [modified SKILL.md content]
   </skill>
   
   Now execute this task:
   [eval prompt]
   ```

This lets you test modifications without pushing to git on every experiment.

#### 3c. Dispatch & Collect
```bash
# Dispatch eval task to target knight
TASK_ID="autoresearch-gen$(printf '%03d' $N)-$(date +%s)"
NATS=/home/node/.local/bin/nats
SERVER=nats://nats.database.svc:4222

# Build payload with modified skill embedded in task
$NATS pub "fleet-a.tasks.<domain>.<knight>" \
  "$(node -e "console.log(JSON.stringify({
    task_id: '$TASK_ID',
    task: process.argv[1],
    timeout: 300
  }))" "$TASK_WITH_EMBEDDED_SKILL")" \
  --server="$SERVER"

# Wait for result
RESULT=$($NATS sub "fleet-a.results.$TASK_ID" \
  --server="$SERVER" --count=1 --timeout=300s 2>/dev/null | tail -n +2)
```

#### 3d. Score
Use the LLM-as-judge scoring rubric. Call the Anthropic API directly:
```bash
curl -sS https://api.anthropic.com/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: ${ANTHROPIC_API_KEY}" \
  -H "anthropic-version: 2023-06-01" \
  -d "$(node -e "console.log(JSON.stringify({
    model: 'claude-3-haiku-20240307',
    max_tokens: 500,
    temperature: 0,
    messages: [{role:'user', content: process.argv[1]}]
  }))" "$RUBRIC_AND_OUTPUT")"
```

#### 3e. Decide
```
IF score.total > best_score:
  best_score = score.total
  cp current skill → snapshots/current-best.md
  consecutive_failures = 0
  LOG: "✅ Generation N: score improved to X (was Y)"
ELSE:
  REVERT skill to snapshots/current-best.md
  consecutive_failures += 1
  LOG: "❌ Generation N: score X did not beat Y, reverting"

IF consecutive_failures >= 3:
  LOG: "🛑 Diminishing returns — stopping after 3 consecutive non-improvements"
  STOP
```

#### 3f. Log
Append to `/data/autoresearch/experiments/experiments.jsonl`:
```json
{"generation": N, "timestamp": "...", "hypothesis": "...", "total": X, "actionability": X, "relevance": X, "depth": X, "signal_to_noise": X, "detection_engineering": X, "kept": true/false, "justification": "...", "improvement_hint": "..."}
```

### Step 4: Final Report

When the loop completes (max_generations reached OR diminishing returns), produce:

1. **Summary**: How many experiments, how many kept, final score vs baseline
2. **Top improvements**: List of changes that improved the score, ranked by impact
3. **Final SKILL.md**: The optimized skill file (from `snapshots/current-best.md`)
4. **Experiment log**: Full `experiments.jsonl` contents formatted as a table
5. **Recommendation**: Should these changes be committed to the arsenal repo?

Save the report to `/data/autoresearch/final-report.md`.

## Scoring Rubric

Use this rubric for ALL scoring. Score each dimension 0-20, total 0-100.

### Dimensions

| Dimension | Weight | Measures |
|-----------|--------|----------|
| **Actionability** | 20 | Does the briefing drive specific actions with clear next steps? |
| **Relevance** | 20 | Filtered for the consumer's stack (enterprise M365/AWS/EDR + homelab K8s/Ceph)? |
| **Depth** | 20 | Goes beyond surface CVE listings? ATT&CK mapping, exploit context, attribution? |
| **Signal-to-Noise** | 20 | Every word earns its place? Reads in ≤5 minutes? |
| **Detection Engineering** | 20 | Bridges to detection (Sigma rules, log sources, query concepts)? |

### Scoring Scale (per dimension)
- 18-20: Exceptional
- 14-17: Good
- 10-13: Average
- 5-9: Below average
- 0-4: Poor

### Judge Output Format
```json
{
  "actionability": <0-20>,
  "relevance": <0-20>,
  "depth": <0-20>,
  "signal_to_noise": <0-20>,
  "detection_engineering": <0-20>,
  "total": <0-100>,
  "justification": "<2-3 sentences>",
  "improvement_hint": "<1 sentence>"
}
```

## Default Eval Prompt (Galahad Threat Briefing)

```
Generate a daily threat briefing for today's date. This briefing is consumed by a senior security professional who manages:

ENTERPRISE ENVIRONMENT:
- Cloud-hosted SaaS platform (AWS/Azure)
- Microsoft 365 tenant
- SentinelOne EDR fleet
- Cisco/Palo Alto network infrastructure
- Active threat intelligence program feeding detection engineering

HOMELAB/PERSONAL:
- Kubernetes cluster (Talos Linux, Cilium CNI, Flux GitOps)
- Ceph storage, NGINX ingress, cert-manager
- Self-hosted services: Paperless-ngx, Home Assistant, Vaultwarden, Gitea
- NATS messaging infrastructure

REQUIREMENTS:
1. Lead with what demands ACTION today — not background noise
2. For each CVE: Is it actively exploited? Does it affect MY stack? What's the patch status?
3. Include at least one "emerging threat" that hasn't hit mainstream yet
4. Cross-reference threats with MITRE ATT&CK techniques where relevant
5. End with specific detection opportunities (log sources, query ideas, Sigma rule concepts)
6. Keep it concise — this gets read in 5 minutes over morning coffee
```

## Modification Strategy

Prioritize changes in this order:

### Round 1 (Gen 1-15): Structure & Prioritization
- Data source ordering and priority
- Section structure and requirements
- What to include vs exclude
- Output format changes

### Round 2 (Gen 16-30): Depth & Specificity
- Analysis depth instructions
- Cross-referencing requirements (CVE ↔ ATT&CK ↔ stack)
- "So What?" / actionability requirements
- Detection engineering hooks

### Round 3 (Gen 31-45): Efficiency & Polish
- Reduce unnecessary verbosity in instructions
- Streamline workflow steps
- Optimize prompt length (shorter prompts that produce same quality)

### Round 4 (Gen 46+): Diminishing Returns
- Fine-grained tweaks
- If 3 consecutive non-improvements → STOP
