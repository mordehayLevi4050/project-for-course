# Addendum: GrouPay Product Brief

This addendum holds depth that supports the brief but belongs in downstream docs (PRD, design) or doesn't fit the 1–2 page brief.

## Competitive landscape (web research, 2026-10-26)

**Takeaways:**

- "No signup / offline" alone is **not** a differentiator, because Splid already does it for free.
- Gaps that look real: speed as the core design; free categories; Hebrew/RTL plus a settle-up hand-off to Bit/PayBox; Hebrew voice or natural-language entry.
- Risk: a one-device v1 is close to Splid's offline mode.

**Caveat:** Splitwise doesn't publish its free-tier cap. Complaints come from Trustpilot, review blogs and competitors' marketing, not Reddit.

| App | Current state | Sources |
|---|---|---|
| Splitwise | Free tier capped at ~3–4 expenses/day since Dec 2023; one 2026 source reports a ~10s ad before each entry. Pro (~$4.99/mo) removes both and adds receipt scanning. | [Trustpilot](https://au.trustpilot.com/review/splitwise.com), [getfinny](https://getfinny.app/blog/best-splitwise-alternatives-2026) |
| Tricount (bunq) | Premium retired; free for everyone, but it lost export, custom categories and custom FX rates. Now funnels users toward bunq banking. Account optional. Complaints: sync bugs, lost expenses. | [tricount.com](https://tricount.com/en/what-happened-with-premium) |
| Settle Up | Free tier has ads. Categories, receipt photos and recurring expenses are Premium (~$3.49/mo or a trip pass). | [saashub](https://www.saashub.com/compare-splitwise-vs-settle-up) |
| Splid | Free, no signup, offline, groups shared by code, 150+ currencies. Export and unlimited groups are paid. | [App Store](https://apps.apple.com/gb/app/splid-split-group-bills/id991473495) |
| Spliit | Open source, web, no account, AI receipt scanning, self-hostable. | [openalternative](https://openalternative.co/alternatives/splitwise) |
| Israeli market | No Hebrew-first splitting app found. LAYA combines splitting with payments. Bit has group money collection but no expense tracking. | [financa](https://financa.co.il/אפליקציות-לחלוקת-הוצאות-בטיול-בין-חבר/) |

**AI features:** receipt scanning (Splitwise Pro, Spliit); natural-language and photo entry claimed by new apps (SaySplit, SplitFlash); Hebrew voice entry has not shipped anywhere.

## Future feature notes

- **Bit integration (settle-up):** the goal is closing debts fast from the summary screen. Open question: Bit has no confirmed public API for third parties, so this may come down to deep links or sharing a payment request. Validate before planning.
- **Hebrew voice entry:** record an expense by speaking, for example "300 שקל דלק, יוסי שילם". This serves the speed goal directly. Needs Hebrew speech-to-text plus parsing of amount, category and payer.
- **Multi-user phase:** each member records from their own device. Joining a group must be close to frictionless, because signup friction is where competitors lose users. Needs a server, auth, invites and sync conflict handling.
- **Payer default in the multi-user phase:** the logged-in user, unless they say otherwise.
