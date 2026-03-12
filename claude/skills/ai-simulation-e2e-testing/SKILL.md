---
name: ai-simulation-e2e-testing
description: |
  Build E2E tests for AI-powered conversational simulations (training simulators,
  roleplay tools, chatbot testing). Use when: (1) pre-scripted test conversations
  fail because the AI generates unexpected follow-up questions, (2) an AI evaluator
  grades competent test conversations poorly, (3) building automated quality
  validation for AI chat flows. Covers adaptive agent generation, scenario-aware
  coaching prompts, and evaluator calibration patterns.
author: Claude Code
version: 1.0.0
date: 2026-03-10
---

# AI Simulation E2E Testing

## Problem
When testing AI-powered conversational simulations (e.g., a training simulator where
AI plays a customer and a human/test-agent plays support), pre-scripted test
conversations fail because:

1. The AI character asks dynamic follow-up questions that scripted responses ignore
2. The evaluator rightfully docks points for unanswered questions
3. Scripted responses can't adapt to what the AI actually says
4. The test agent may give factually wrong information (e.g., wrong refund policy
   window) because it doesn't know the scenario's specific resolution criteria

## Context / Trigger Conditions
- Building automated tests for AI chat/roleplay simulations
- Pre-scripted test conversations consistently grade lower than expected
- AI evaluator feedback says "the agent didn't answer the customer's question"
- Test conversations end with unanswered follow-ups from the AI character

## Solution

### 1. Use Adaptive (AI-Generated) Agent Responses for Quality Testing

Instead of pre-scripted messages, use an AI to generate the test agent's responses
based on the full conversation history. This ensures the agent responds to what
the AI character actually says.

```
For each turn:
  1. Read conversation history
  2. Generate agent response using coaching prompt
  3. Send agent response through chat handler (AI character responds)
  4. Log both sides
```

### 2. Pass Scenario-Specific Knowledge into the Coaching Prompt

The AI test agent needs to know the correct answers. Pass the scenario's resolution
criteria and key actions into the coaching prompt so it gives accurate information.

```
Base coaching prompt (how to behave):
  "You are a skilled, empathetic support agent..."

+ Scenario-specific knowledge (what to say):
  "Resolution Criteria: Refund window is 14 days..."
  "Key Actions: Verify forwarding setup, check MX records..."
```

Without scenario context, the AI agent will hallucinate policies and procedures.

### 3. Keep Pre-Scripted Conversations for Intentionally Flawed Quality Levels

- **Good quality**: AI-generated adaptive responses (tests the happy path)
- **Mediocre quality**: Pre-scripted with intentional gaps (tests mid-tier grading)
- **Bad quality**: Pre-scripted with poor responses (tests low-tier grading)

Pre-scripted responses work fine for mediocre/bad quality because the flaws are
intentional — it doesn't matter if the AI asks follow-ups that go unanswered.

### 4. Add Turn Awareness for Natural Conversations

Tell the AI agent where it is in the conversation so it wraps up naturally:

```
if last turn:
  "This is your FINAL response. Wrap up warmly."
elif near end:
  "Start moving toward resolution."
```

Without this, conversations either end abruptly or go in circles.

### 5. Calibrate the Evaluator Independently

If the evaluator grades competent conversations poorly, the problem may be in the
tier definitions, not the test conversations. Common calibration issues:

- "Excellent" requiring superhuman/above-and-beyond performance
- No concrete examples of what each tier looks like
- Missing "when in doubt" guidance for borderline cases

Add a Calibration Guidance section to the evaluation prompt with concrete examples
and the instruction: "When in doubt between two tiers, ask: 'Would a reasonable
customer rate this interaction positively?'"

## Verification
1. Run good-quality tests — expect the highest tier 80%+ of the time
2. Run bad-quality tests — expect the lowest tier consistently
3. Check evaluator feedback for specificity (not generic boilerplate)
4. Verify the AI test agent addresses customer questions (no unanswered follow-ups)

## Notes
- AI-generated tests are non-deterministic — expect ~80% pass rate, not 100%
- The email-forwarding-type scenarios where the AI agent "gets lucky" and skips
  diagnostics will occasionally grade lower; this is valid evaluator behavior
- Pre-scripted mediocre conversations may need 4+ turns to avoid grading as
  Needs Improvement — too-short scripts look worse than intended
- See also: `ai-roleplay-drift-prevention` for preventing the AI character from
  breaking character during these test conversations
