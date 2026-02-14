---
name: interview-prep
description: Structured interview preparation framework — research, behavioral prep, technical review, and follow-up
---

# Interview Preparation

Systematic framework for preparing for technical and behavioral interviews, with a security/engineering angle.

## Phase 1: Company Research

Before any interview, gather intel on these dimensions:

### Technical Profile
- **Tech stack** — Check job posting, StackShare, GitHub repos, engineering blog
- **Infrastructure** — Cloud provider (AWS/GCP/Azure), container orchestration, CI/CD
- **Scale** — User count, request volume, team size (LinkedIn headcount)
- **Open source** — Do they contribute? What projects?

### Business Profile
- **Product** — What do they sell? Who are the customers?
- **Revenue model** — SaaS, enterprise, freemium, marketplace?
- **Funding/stage** — Crunchbase for startups; annual reports for public companies
- **Recent news** — Last 6 months of press releases, blog posts, acquisitions
- **Competitors** — Who else plays in this space?

### Culture Profile
- **Glassdoor/Blind** — Team reviews, interview process reports
- **Engineering blog** — Writing quality signals culture quality
- **Leadership** — CTO/VP Eng background, public talks
- **Remote/hybrid policy** — Check careers page and recent postings

### Research Template
```
Company: [Name]
Role: [Title]
Interview Date: [Date]

Tech Stack: 
Cloud/Infra: 
Team Size: 
Product: 
Revenue Model: 
Recent News (3 items):
  1. 
  2. 
  3. 
Why This Company: 
Questions to Ask (3+):
  1. 
  2. 
  3. 
```

## Phase 2: Behavioral Prep (STAR Method)

Structure every behavioral answer as **Situation → Task → Action → Result**.

### Core Stories to Prepare (8-10)

Have polished stories for each theme:

1. **Leadership / Influence** — Led a project or convinced stakeholders
2. **Conflict Resolution** — Disagreed with a teammate, resolved it
3. **Failure / Learning** — Something went wrong, what you learned
4. **Technical Challenge** — Hard engineering problem you solved
5. **Security Incident** — Responded to or prevented a security issue
6. **Under Pressure** — Tight deadline, production outage, crisis
7. **Cross-team Collaboration** — Worked across org boundaries
8. **Mentorship** — Helped someone grow
9. **Process Improvement** — Made something more efficient
10. **Customer Impact** — Directly improved user experience

### STAR Template
```
Story Name: [Short label]
Theme: [Which theme(s) it covers]

Situation: [2-3 sentences — context, when, where]
Task: [What was your specific responsibility?]
Action: [What did YOU do? Be specific. Use "I" not "we"]
Result: [Quantifiable outcome. Metrics if possible]
Security Angle: [How does this relate to security/engineering excellence?]
```

### Security/Engineering Angles
- Emphasize **threat modeling** in design discussions
- Mention **shift-left security** practices
- Reference **incident response** experience
- Highlight **automation** of security controls
- Discuss **compliance** awareness (SOC2, HIPAA, PCI)

## Phase 3: Technical Prep

### System Design Checklist
- [ ] Requirements gathering (functional + non-functional)
- [ ] API design (REST/gRPC endpoints)
- [ ] Data model (schema, relationships)
- [ ] High-level architecture (services, data flow)
- [ ] Storage (SQL vs NoSQL, caching layer)
- [ ] Scaling strategy (horizontal, sharding, CDN)
- [ ] Security considerations (auth, encryption, rate limiting)
- [ ] Monitoring and observability
- [ ] Trade-offs discussion

### Coding Interview Checklist
- [ ] Clarify inputs/outputs and edge cases before coding
- [ ] State brute-force approach first, then optimize
- [ ] Think aloud — explain your reasoning
- [ ] Test with examples before declaring done
- [ ] Discuss time/space complexity

### Security-Specific Topics
- [ ] OWASP Top 10 — can explain and mitigate each
- [ ] Authentication patterns (OAuth2, OIDC, JWT pitfalls)
- [ ] Network security (TLS, mTLS, zero trust)
- [ ] Container security (image scanning, runtime policies)
- [ ] Cloud security (IAM, VPC, secrets management)
- [ ] Supply chain security (SBOMs, dependency scanning)

## Phase 4: Day-Of

### Pre-Interview Checklist
- [ ] Review company research notes
- [ ] Review your STAR stories
- [ ] Test audio/video setup (15 min before)
- [ ] Have water, notepad, pen ready
- [ ] Close distracting apps and notifications
- [ ] Pull up the job description for reference

### Questions to Ask Them
- "What does the first 90 days look like?"
- "What's the biggest technical challenge the team faces right now?"
- "How does the team handle on-call and incident response?"
- "What does the security review process look like for new features?"
- "How are technical decisions made? (RFC, ADR, design docs?)"

## Phase 5: Follow-Up

### Thank You Email (Send within 24 hours)
```
Subject: Thank you — [Role] Interview

Hi [Name],

Thank you for taking the time to speak with me about the [Role] position. I enjoyed learning about [specific topic discussed].

Our conversation about [specific technical/team topic] reinforced my excitement about the opportunity. I'm particularly drawn to [something specific about the team/mission].

[Optional: brief follow-up on something discussed — a resource, clarification, or additional thought]

Looking forward to the next steps.

Best,
[Your Name]
```

### Decision Framework
When evaluating an offer, score 1-5:
- Compensation (base, equity, benefits)
- Technical growth opportunity
- Team quality and culture
- Work-life balance
- Mission alignment
- Career trajectory (title, scope, visibility)

## Notes
- Preparation compounds — invest 4-6 hours minimum per company
- Record yourself answering behavioral questions; review for clarity
- Research your interviewers on LinkedIn before the call
