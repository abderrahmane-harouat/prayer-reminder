# TODO

Planned features and follow-ups. Nothing here is implemented yet.

## Planned

- [ ] **Silence the phone during prayer (Do Not Disturb)**

  When a prayer time arrives, turn on Do Not Disturb for a few minutes, then turn it back off automatically.

  Ideas for the behaviour:
  - A switch per prayer (like reminders), plus a duration: 10, 15, 20 or 30 minutes.
  - Starts at the prayer time itself (not at the earlier reminder), using the same exact scheduling as reminders.
  - Ends on its own; if the user changes Do Not Disturb manually in between, leave their choice alone.
  - Optional: let the prayer reminder itself still be heard (priority exception).

  Technical notes:
  - Needs Do Not Disturb access (`ACCESS_NOTIFICATION_POLICY`). Android grants it **only from a system Settings screen**, never from an in-app dialog, so the app has to open "Do Not Disturb access" once, with a short explanation first. This is the one case where sending the user to Settings can't be avoided.
  - Prefer `AutomaticZenRule` (a named "Prayer time" mode the user can see and edit in system settings, and Android 15's Modes) over flipping `setInterruptionFilter` directly, so it's clear which app silenced the phone.
  - Schedule a "start" and an "end" alarm per prayer, re-planned nightly and after reboot like reminders; if the end alarm is missed (phone off), clear the rule on the next launch.
  - Test on Samsung One UI as well as stock Android: Do Not Disturb behaves differently there.
