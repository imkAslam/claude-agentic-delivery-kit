---
name: coding-foundations
description: "Foundation layer for writing code the same way across the team: object-oriented design, SOLID, class design, domain modeling and a catalog of design patterns with when to use and avoid each, form and input validation across stacks (React Hook Form or Formik with zod or yup, and the equivalents elsewhere), plus stack guides with best practices and review checklists for TypeScript, Node.js, NestJS, React, Next.js (App Router, route groups), React Native, Python (FastAPI, Django), Go, Java/Kotlin (Spring) and .NET, and cross-stack guides for performance, realtime channels and workers."
when_to_use: "Use before implementing or reviewing code in a stack for the first time in a session, when choosing a design pattern or structuring classes and modules, when the architect pins the coding conventions for a stack, and when a reviewer needs the stack checklist."
user-invocable: false
---

# Coding foundations

The rules say *what* good code must satisfy (`.claude/rules/engineering-principles.md`, `coding-standards.md`, `database-standards.md`, `secure-coding.md`, `testing.md`). These guides say *how* to do it in each stack, so every engineer and reviewer works from the same playbook. Code templates (the shapes of a component, an endpoint, a screen) stay in the `create-component`, `create-endpoint` and `create-screen` skills.

## Which guides apply
The solution-architect lists them per role in `.claude/project.json → roles.<role>.guides` and in `PROJECT.md` ("Coding guides"). Every build and review brief carries them in its `GUIDES:` line.

| Guide | Read it for |
|---|---|
| [OOP_AND_PATTERNS.md](references/OOP_AND_PATTERNS.md) | **Every role that writes code.** SOLID, class design, domain modeling, design patterns, anti-patterns |
| [FORMS_AND_VALIDATION.md](references/FORMS_AND_VALIDATION.md) | **Every role that builds forms or validates input** (frontend, mobile, backend): one schema per rule shared by client and server, the library per stack (React Hook Form or Formik with zod or yup, VeeValidate, Angular Reactive Forms, Superforms, Pydantic, class-validator, Bean Validation, FluentValidation…), field rules, accessible errors, server-error mapping, tests |
| [TYPESCRIPT.md](references/TYPESCRIPT.md) | Any TypeScript code (frontend, backend, mobile) |
| [NODE.md](references/NODE.md) | Node.js services and scripts (Express, Fastify, Hono, workers) |
| [NESTJS.md](references/NESTJS.md) | NestJS services (read with NODE and TYPESCRIPT) |
| [REACT.md](references/REACT.md) | React web apps: components, the UI-library-first rule, component layers, state, hooks |
| [NEXTJS.md](references/NEXTJS.md) | Next.js App Router apps (read with REACT): route groups, server and client components, server actions, caching, error layers |
| [PERFORMANCE.md](references/PERFORMANCE.md) | **Every role that writes code, and the performance-specialist.** Budgets, measure-first method, frontend, backend and heavy-data practices, bottleneck table, checklists |
| [REALTIME.md](references/REALTIME.md) | Only when the architecture has a realtime channel: SSE vs WebSockets vs WebRTC, event contracts, auth, reconnect and resync, scaling out |
| [WORKERS.md](references/WORKERS.md) | CPU-heavy or long-running work: web workers, worker-thread pools, when a durable job queue is the right tool |
| [REACT_NATIVE.md](references/REACT_NATIVE.md) | React Native and Expo apps (read with REACT) |
| [PYTHON.md](references/PYTHON.md) | Python services: FastAPI, Django/DRF, SQLAlchemy, workers |
| [GO.md](references/GO.md) | Go services |
| [JAVA_KOTLIN_SPRING.md](references/JAVA_KOTLIN_SPRING.md) | Java or Kotlin with Spring Boot |
| [DOTNET.md](references/DOTNET.md) | C# / ASP.NET Core |

A stack not listed: the architect writes a short guide in the same format into `PROJECT.md` ("Coding guides"), covering structure, types, errors, async, data access, testing and a review checklist.

## How to use
- **Engineers:** before the first ticket of a session, read OOP_AND_PATTERNS (once) and the guides in your brief's `GUIDES:` line, only the sections your ticket touches. Before returning, run the guide's **Review checklist** against your diff.
- **Reviewers:** apply the guide's Review checklist on top of `review-checklists`. A violated **must** is a P2 finding (P1 when it affects correctness, security or data); a **prefer** is a P3 suggestion.
- **Architect:** pick the guides at `boundaries`, pin the tools they name (formatter, linter, type checker) in `project.json → commands`, and record any deliberate deviation from a guide in an ADR and in PROJECT.md.
- **Conflicts:** the project's ADRs and PROJECT.md win over a guide; a guide wins over personal preference.
