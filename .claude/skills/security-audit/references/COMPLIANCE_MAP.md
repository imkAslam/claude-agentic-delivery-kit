# Compliance mapping (readiness guidance, not legal advice)

This map shows which kit controls and artifacts provide evidence for each framework. Formal compliance requires the client's legal or compliance counsel and, where it applies, an accredited auditor.

| Framework | Applies when | Key requirements | Kit evidence |
|---|---|---|---|
| **GDPR / UK GDPR** (and similar privacy laws) | Personal data of people in the EU/UK | Lawful basis, data minimization, retention limits, data-subject rights (access, deletion, portability), breach notification within 72h, DPIA for high risk, processor agreements | DATA-MODEL classification + retention, deletion paths (C-PRIV-1/2), THREAT-MODEL, audit log, incident playbook |
| **HIPAA** | US protected health information | Access controls, audit controls, integrity, transmission security, BAAs with vendors, breach notification | RLS + authz tests, audit_events, encryption at rest/in transit, OPERATIONS-HANDOFF incident steps |
| **PCI DSS v4.0** | Storing, processing or transmitting cardholder data | Minimize scope (use hosted payment pages/tokens), network segmentation, vulnerability management, logging, MFA for admin | No card data stored (DATA-MODEL), DevSecOps scans, logging, admin MFA (C-AUTH-3) |
| **SOC 2** (Security, Availability, Confidentiality…) | B2B SaaS customers ask for it | Access management, change management, monitoring, incident response, vendor management, backups | Gate log (change approvals), CI evidence, reviews, DEVOPS-PLAN backups/DR, OPERATIONS-HANDOFF |
| **ISO/IEC 27001:2022** | An organization-wide ISMS | Risk assessment, Annex A controls (access, crypto, ops, supply chain, secure development) | THREAT-MODEL risks, controls catalog, secure-coding rules, DevSecOps pipeline |
| **NIST CSF 2.0** | A general security program | Govern, Identify, Protect, Detect, Respond, Recover | Govern: gates/ADRs · Identify: threat model/classification · Protect: controls · Detect: monitoring · Respond/Recover: runbooks, backups |

## In the audit report
For each framework in scope, list: the requirement → the kit control or artifact → the status (met / partial / gap) → the remediation owner.
