---
layout: post
title: From Primitives to Golden Paths in the Agentic Era
date: 2026-01-31 00:00:00
description: exploring the evolution from low-level primitives to high-level golden paths in the age of AI agents
tags: ai agents mcp a2a platform engineering development
categories: technology
published: false
---

# From Primitives to Golden Paths in the Agentic Era

Agents have been around for a while, and the technology is undeniably promising. Yet many teams struggle to move beyond proof-of-concepts or demos into production-ready systems. In a handful of mature organizations with robust practices, we’re seeing striking results — think Claude Code, Google’s SRE agent, and similar initiatives.

This raises a crucial question: how can we enable developer teams, data scientists, or even business users to achieve these outcomes without burdening them with the deep engineering expertise normally required?

Over the past six months, we’ve been building an agentic platform — an internal development platform designed specifically to run agentic workflows and manage MCP servers. From the beginning, we recognized the challenges of operating agents at scale. These systems violate many assumptions of traditional IDPs and established software engineering principles, including RESTful design, loose coupling, and decoupling of state and execution.

Agents stress every layer of a platform simultaneously: execution, identity, observability, cost governance, and lifecycle management. Traditional platforms assume stateless services, short-lived requests, and clear ownership boundaries — assumptions that agentic systems routinely break.

To make this problem tractable, we had to rethink the core primitives of our platform and the way we expose them to teams. Here’s how we’ve approached it…

Note: I won't focus on specific tooling here. There's a myriad of tools that aim to address various gaps in this space, a lot of them overlap but the key ideas and principles remain the same.

---

### A Unified Model Interface

One of the earliest decisions we made was to treat *all* model interaction as a platform concern.

From the agent’s point of view, we don’t care about modality. Text, image, video, audio, fully multimodal — they all expose the same interface. An agent doesn’t “call OpenAI” or “use an embeddings model” or “switch to a self-hosted endpoint”. It interacts with **a single, unified model interface**.

That abstraction turns out to be foundational.

Because models sit behind a common contract, we can plug in **any provider** — commercial APIs, regional deployments, self-hosted models, or internal fine-tuned systems — without forcing developers to change code. Switching models becomes configuration, not a refactor. The same agent logic can run unchanged across environments, regions, and providers. Model deprecations and updates become a single config change (though this creates other problems, to which we'll come around in a second)

This also removes an enormous amount of operational burden from teams. Developers don’t have to think about provisioning access, managing API keys, setting up networking, securing endpoints, or defining budgets in infrastructure code. Those concerns live entirely at the platform layer.

Once all traffic flows through a single interface, it becomes possible to add the controls that production systems actually need. We secure model access with **prompt-injection prevention**, input and output compliance checks, and safeguards against supply-chain risks — for example when embedding models ingest external documents or untrusted data. These protections are invisible to agent authors but critical at scale.

From the platform side, this layer looks much more familiar. We can apply the same patterns we’ve used for years in distributed systems: regional versus global routing, load balancing, failover strategies, retries, and graceful degradation. If a provider or region misbehaves, agents don’t need to know — the platform adapts.

Cost governance and observability also naturally belong here. Because every call passes through a single choke point, we get consistent cost attribution, usage tracking, and policy enforcement without imposing brittle session-level limits. The goal isn’t to arbitrarily cut agents off, but to **contain blast radius** and prevent runaway cascades when things go wrong.

This unified interface is not about LLMs specifically. It’s about restoring **loose coupling** between agent logic and the underlying AI infrastructure — a principle we’ve relied on for decades in software, and one that becomes even more important in agentic systems.

---

### Agents Are Stateful — But the Platform Treats Them as Stateless

Agents are, by their nature, stateful.

They accumulate context, reason over prior steps, maintain memory across interactions, and coordinate with other agents over time. Pretending otherwise is naïve — and many early systems paid the price for that assumption.

At the same time, every instinct we have as platform and software engineers pushes us in the opposite direction. Stateless systems are easier to scale, easier to reason about, easier to recover, and far more resilient under failure. Long-running, stateful processes tied to in-memory context are brittle, opaque, and notoriously hard to operate.

We learned this the hard way.

Early on, we experimented with long-lived agent sessions: open HTTP connections, extended SSE streams, agents “thinking” for tens of minutes at a time. It worked — until it didn’t. Sessions dropped. State drifted. Partial failures became impossible to recover from. Debugging turned into archaeology.

The conclusion wasn’t that agents should be stateless. It was that **the platform must treat them as if they are**.

We do this by externalising state entirely. Agent execution becomes a sequence of short, bounded steps. Context, memory, and intermediate state are explicitly checkpointed and persisted outside the runtime. If an agent fails, times out, or needs to be rescheduled, it can resume from a known, durable point rather than starting from scratch or — worse — silently continuing in a corrupted state.

Durable execution frameworks play a critical role here. They give us retries, backoff, and recovery semantics that are well understood in distributed systems, but rarely applied in agentic workflows. Instead of a single, fragile “conversation”, we get a traceable execution history that can pause, resume, rewind, or fork as needed.

This approach also forces discipline around **decoupling memory from execution**. Agent memory can be loaded when required, unloaded when idle, and scoped to the task at hand. Long-term memory, ephemeral session context, and tool outputs are all treated as separate concerns rather than an ever-growing prompt blob.

The net effect is subtle but powerful: agents remain expressive and stateful in behaviour, while the platform regains the operational characteristics of stateless systems. Failures are survivable. Scaling is predictable. And long-running workflows stop being a source of anxiety.

In other words, we stop fighting decades of platform engineering lessons — and start applying them to agents.


---

### Coordination at Scale: Observability and Authorisation Don’t Compose Automatically

Once agents start delegating work — to other agents, to MCP tools, and back again — the system stops behaving like a simple request/response pipeline.

Nothing here is conceptually new. Logs, spans, and traces still work. The problem is **volume and structure**, not tooling. A single agent interaction can produce an overwhelming number of events, many of them asynchronous and only loosely ordered. An agent may delegate work, continue executing in parallel, and only later reconcile partial results as they arrive.

Chronological traces quickly become misleading.

What we found missing is the ability to **replay an agent session as it actually unfolded**, following the reasoning flow rather than strict timestamps. Session replay becomes the unit of understanding: which decisions were made, what was delegated, which paths were taken, and which results were incorporated or ignored. Without this, debugging multi-agent behaviour turns into scrolling through logs and hoping the ordering happens to line up.

Observability, in this sense, isn’t about more telemetry. It’s about **reconstructing intent and flow** in a system where execution is inherently non-linear.

---

### Authorization in Agentic Systems: Bounding Delegation, Not Identity

Authorization becomes fundamentally harder once you introduce **A2A and MCP-based delegation**. The challenge isn’t identifying *who* is making the request — that’s trivial in an internal system — it’s deciding **whether a call should be allowed to exist at all** given where it originated and how it propagates.

In an agentic workflow, a single user action can fan out across multiple agents, each invoking other agents or MCP tools asynchronously. This raises uncomfortable questions traditional platforms rarely have to answer:

* Is the user authorized to perform this action *via this agent*?
* Is this agent allowed to invoke that MCP tool, regardless of the user?
* What happens when permissions diverge along the call chain?
* Which policy wins when user, agent, tool, and workspace constraints conflict?

This is no longer a simple request-level check. Conceptually, it starts to resemble **Zanzibar-style relationship evaluation**, but at a much finer granularity and with far more dynamic execution paths.

To make this tractable, we separate **user authorization** from **agent and tool constraints**.

User permissions determine *what is allowed in principle*. Agent and MCP constraints determine *which execution paths are legal*. Even if a user is authorized, an agent may still be forbidden from invoking a specific MCP tool — or from delegating further — by platform policy.

This is where a gateway layer such as **kgateway** becomes useful. Not as an identity system or a global policy engine, but as an **enforcement point for agent-to-agent and agent-to-tool boundaries**. It allows us to make invocation graphs explicit, constrain delegation paths, propagate context, and reject invalid calls early — before they turn into accidental privilege escalation.

We are very much still learning here. Policy authoring, ownership, validation, and explainability remain open problems, and no one in the industry has a fully satisfying answer yet. But bounding delegation — rather than relying on identity alone — has proven to be a necessary foundation for operating agentic systems safely at scale.

---

### Knowledge Management & RAG Integration

Agents are powerful because they can reason, plan, and act — but without access to structured knowledge, they’re limited to what fits in their working context. That’s where **knowledge management** becomes critical.

We treat data sources, embeddings, and knowledge graphs as **external primitives**. They are decoupled from runtime, allowing agents to load and query information on demand. A RAG (retrieval-augmented generation) pipeline brings external knowledge into the agent’s decision-making flow without coupling it to ephemeral memory or session context. Long-term memory, external knowledge, and session state are all treated as independent concerns.

This decoupling is essential for resilience and reproducibility. Agents can fail, pause, or be rescheduled without losing access to critical knowledge. And because retrieval is a platform-managed operation, we can enforce governance, logging, and compliance checks on every query — preventing inadvertent data leaks or misuse.

The lesson here is simple but often overlooked: **knowledge is a first-class primitive** in agentic systems, just like execution, authorization, or observability.

---

### MCP & Tool Discovery at Scale

As agentic systems grow, managing tools and MCPs quickly becomes unwieldy. Hundreds of tools, multiple MCP servers, and dozens of agents interacting asynchronously create a combinatorial explosion of dependencies.

Manual registration or ad-hoc discovery doesn’t scale. Instead, every agent and MCP automatically registers itself with the platform upon deployment. This registry acts as the source of truth for **what is available, where, and under what conditions**.

Discovery is more than just listing endpoints. Agents need to know which tools they can actually invoke, and the platform must resolve conflicts, version mismatches, and availability constraints. In large deployments, we even envision **meta-discovery layers** that allow agents to find tools indirectly via MCPs or higher-level orchestration agents.

The takeaway: **tool discovery cannot be an afterthought**. At scale, it becomes a core platform concern, shaping reliability, authorization, and the very paths an agent can take to achieve its goals.

---

### Self-Serve & Workspace-Driven Entry Points

Not all agents are created by platform engineers. Verified users — developers, analysts, or even business users — often need to create agents themselves. This introduces a tension: how do we allow **self-serve agent creation** without undermining security, governance, or operational integrity?

We solve this with **workspace-driven sandboxes**. Each workspace defines boundaries: which agents, tools, or assets can be accessed, and what operations are allowed. Users can define system prompts, select curated agents or sub-agents, and bind them to specific tools and resources — but all actions are strictly **create-only**. Destructive or arbitrary operations are prohibited.

This approach lets platform teams enforce golden paths while giving users flexibility. Developers focus on **logic**, not protocols, infrastructure, or deployment pipelines. The platform handles the rest: state, memory, checkpointing, discovery, authorization, and observability.

---

### Security & Supply Chain Considerations

Agentic systems introduce unique attack surfaces. Prompt injections, malicious embeddings, or compromised models can propagate bad decisions throughout the system. Supply chain risks are real, especially when agents consume third-party models, pipelines, or document ingestion workflows.

We treat **security as a platform primitive**. All inputs and outputs are checked for compliance, prompts are sanitized, and embeddings are verified. Multi-modal models (text, image, audio, video) are handled under the same governance framework. Importantly, these protections are **transparent to the agent author** — they can write logic freely while the platform enforces safety.

We’re still learning here. Threats evolve faster than documentation. But centralizing security controls, decoupling knowledge and execution, and applying platform-level guardrails significantly reduces risk while maintaining flexibility.

---

### Governance, Cost & Traffic Management

Scaling agents is expensive. Model API calls, compute, and long-running workflows all create risk of runaway cost. To manage this, the platform provides centralized **cost governance and traffic management** without imposing rigid session limits.

LiteLLM acts as a unifying interface for all model calls, regardless of modality or provider. It allows routing, failovers, load balancing, and observability — and integrates cost tracking and budgeting at the platform level. We can prevent cascading failures without prematurely terminating agent sessions. The platform sees everything, giving teams insight and control, while developers focus on logic rather than infrastructure.

Traffic and cost governance are just one example of a broader principle: **platform primitives should encapsulate operational complexity**, so developers never have to think about them.

---

### Closing / Lessons Learned

Building an agentic platform is hard. Even with the primitives outlined above, the ecosystem is rapidly evolving. **Authorization, compliance, drift detection, evaluation, and long-term observability** remain active challenges.

The core insight from our journey is this: treat agentic systems as **platform workloads first, AI workloads second**. Provide unified primitives for model access, execution, knowledge, authorization, discovery, self-serve entry, and governance. Then, define **golden paths** that let teams focus on the work that matters — agent logic — without worrying about the brittle plumbing underneath.

Primitives give you control; golden paths give you leverage. And in a world where agents increasingly orchestrate each other, tools, and data pipelines, those two concepts are the difference between chaos and production-ready systems.

---
