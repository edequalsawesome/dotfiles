---
name: ai-roleplay-drift-prevention
description: |
  Fix AI role drift in chat simulations where an AI playing a character (customer, patient,
  student, etc.) starts acting as the opposite role (support agent, doctor, teacher). Use when:
  (1) AI character starts asking diagnostic/help questions instead of answering them,
  (2) AI breaks character and says things like "let me get back into character",
  (3) AI acknowledges it's a simulation or playing a role,
  (4) building any AI-powered roleplay, training simulator, or conversational practice tool.
  Covers system prompt architecture for role-anchoring in OpenAI and Anthropic APIs.
author: Claude Code
version: 1.0.0
date: 2026-03-10
---

# AI Roleplay Drift Prevention

## Problem
When an AI plays a character in a conversational simulation (e.g., a customer contacting
support), it can drift out of its assigned role over extended conversations. Even with
detailed per-character persona prompts, the AI may:
- Start acting as the opposite role (asking diagnostic questions instead of answering them)
- Break character and acknowledge it's playing a role ("let me get back into character!")
- Flip the conversation dynamic entirely

## Context / Trigger Conditions
- Building an AI-powered training simulator, roleplay tool, or practice conversation
- AI is assigned a specific role (customer, patient, caller, etc.) via system prompt
- The person interacting is playing the complementary role (agent, doctor, operator, etc.)
- Detailed persona prompts exist but the AI still drifts after several turns
- The AI responds to correction by breaking the fourth wall

## Root Cause
Per-character persona prompts (even very detailed ones) tell the AI *who* to be but don't
explicitly anchor *which side of the conversation* it's on. After many turns, especially if
the human's messages are ambiguous, the AI loses track of the conversational dynamic and
defaults to its natural "helpful assistant" behavior -- which looks like the support agent role.

## Solution

### 1. Add a Role-Anchoring Preamble
Prepend a universal preamble to every scenario's system prompt. This goes BEFORE the
per-character persona instructions:

```
CRITICAL CONTEXT: You are the CUSTOMER in this conversation.
The person sending you messages is a support agent in training.
You have a problem and you are contacting them for help.
NEVER ask diagnostic questions, offer troubleshooting steps, or act like a support agent.
NEVER break character or acknowledge that you are an AI, a simulation, or playing a role.
If you catch yourself slipping out of character, simply continue as the customer without commenting on it.
```

### 2. Apply It Architecturally, Not Per-Scenario
Don't edit each scenario's prompt. Instead, prepend the preamble in the system prompt
builder function so it applies universally:

```php
private function build_system_prompt( array $scenario ) {
    $preamble = "CRITICAL CONTEXT: You are the CUSTOMER...";

    if ( ! empty( $scenario['ai_instructions'] ) ) {
        return $preamble . $scenario['ai_instructions'];
    }

    // Fallback synthesized prompt also gets the preamble
    $prompt = $preamble;
    $prompt .= "You are {$name}, a customer contacting support.\n\n";
    // ... rest of prompt
    return $prompt;
}
```

### 3. Key Principles
- **Explicit role statement**: "You are the CUSTOMER" not "You are playing the role of..."
  (the latter implies acting, which invites breaking character)
- **Explicit opposite-role prohibition**: Name the behaviors to avoid (diagnostic questions,
  troubleshooting steps) -- don't just say "stay in character"
- **Graceful recovery instruction**: "Continue as the customer without commenting on it"
  prevents the AI from saying "oops, let me get back into character"
- **Fourth-wall prohibition**: "NEVER acknowledge you are an AI, simulation, or playing a role"

## Verification
1. Start a new session (existing sessions have old conversation history that may confuse things)
2. Chat for 5+ turns to test sustained role adherence
3. Try deliberately confusing the AI about roles -- it should maintain character
4. Try being a terrible agent -- the AI should escalate (ask for supervisor) rather than
   start helping you troubleshoot

## Notes
- This applies to both OpenAI-format APIs (system message) and Anthropic APIs (system field)
- The preamble works with both pre-authored detailed persona prompts AND fallback synthesized prompts
- Existing sessions won't benefit from the fix since conversation history is already established
  with the old dynamic -- start fresh sessions to test
- The "playing the role of" phrasing in prompts is a common anti-pattern that subtly invites
  character breaks; use direct identity statements instead ("You ARE X" not "You are playing X")
