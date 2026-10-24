---
name: device-class-review
description: Use when reviewing an SNMP::Info pull request or branch that adds or changes a device class, detection in device_type(), or a shared role such as Bridge, LLDP or Entity, including a self-review before opening the pull request.
---

# Reviewing SNMP::Info device class changes

Compare the branch with its merge base. Read the PR description, the linked
issues, `AGENTS.md`, and `.claude/skills/device-class-authoring/SKILL.md`;
the authoring skill is the standard the change is held to.

## Mechanical checks

Run the CI command from `AGENTS.md` and report each failing test by name.
Then check the `AGENTS.md` pull request checklist item by item: test class,
SUBCLASSES POD entry, MANIFEST, Changes placement and form, generated files
and `$VERSION` untouched, no committed walks or assets, MIBs available in a
netdisco-mibs release.

## Behavior checks

- **Run it.** A claim about what a method returns is verified by running
  the class against a walk: the mocked test session, or the walk served by
  an SNMP simulator on a private port. Reading the code is not evidence.
  Resolve every leaf to its numeric OID before searching a walk; vendor
  subtrees look alike.
- **Detection.** Every sample routes to the new class, neighboring products
  still reach their own classes, and the change adds no GET for devices
  outside the target branch. Count the GETs a plain device of the same
  enterprise now receives.
  Check the vendor's MIBs for other product lines under the matched
  branch; a whole-enterprise match needs a reason.
- **Merge order.** For each hash a class merges, the parents appear in
  reverse `@ISA` order, and the class's own entries come last. List the
  keys two parents both define and say which value wins.
- **Identity.** Search the vendor's MIBs in netdisco-mibs for model,
  serial and firmware objects the class leaves unread.
- **Behavior carried over.** Compare each method on master and on the
  branch for the devices that move class. A loss (an ignored interface, a
  better uptime source, a serial) needs a reason.
- **Calling application.** Check each method against what the calling
  application reads (authoring skill, "What the calling application
  reads"). Data only in vendor-named methods is not stored.
- **Walk integrity.** Before trusting an odd value, check index shapes,
  decoded strings and values the MIB calls impossible. Third-party captures
  can be hand-built. A walk of a TimeFilter table whose index keeps
  increasing is the agent looping, not data.

## Keep the author's approach

The author had devices the reviewer does not.

- A vendor table missing from the available walks is not dead code. Keep it
  as the fallback behind the standard.
- Change existing code only when it contradicts its own comment, calls
  something that does not exist, or gives a wrong result on a walk. A
  redesign is not a fix.
- When the defect sits in shared code and the walk shape is standard,
  consider the shared fix, and say why a class fix was chosen if it was.

| Rationalization | Reality |
|---|---|
| "No walk has this table, so remove it" | Walks hold only what the capturing tool polled. Keep it behind the standard. |
| "The new source covers every walk" | Every walk available. The fallback serves devices not in hand. |
| "Simpler without the fallback" | Fewer lines, lost devices. |

## Findings

- Give the file and symbol, the input, what happens and what should, and
  the effect on the calling application.
- Report only issues the change introduces or exposes. Separate missing
  evidence from a proven failure, and say which checks could not be run.
- Order: CI failures, then behavior regressions, then design, then small
  items.
- Ask for a walk (`AGENTS.md`, "Device data") when a question needs
  device data.
- Do not push, merge or post during a review unless asked.
