# Testing checklist

Run the relevant part before every merge to `main` and the whole thing at the end of every milestone.

## Automated (Claude runs these, CI repeats them)

- [ ] Headless import and parse check passes (no script errors)
- [ ] All gdUnit4 tests pass
- [ ] Debug APK builds in CI
- [ ] (from M3) Balance simulator report within targets

## On PC (5 minutes)

- [ ] Game starts from the boot scene without errors in the Output panel
- [ ] The feature you changed works as described in its acceptance criteria
- [ ] No new warnings in the Output panel

## On the phone (10-20 minutes)

- [ ] Install the APK, cold start time is acceptable
- [ ] Touch: tap, pinch zoom, buttons reachable with thumbs in landscape
- [ ] The changed feature works on the phone
- [ ] Rotate, lock the screen, switch apps and come back: no crash, no lost state
- [ ] (from M4) Kill the app from recent apps, reopen, continue from save
- [ ] (from M4) Switch language EN/PL: no missing keys, no text overflow
- [ ] Readable in daylight at default zoom
- [ ] No visible stutter while walking and in combat

## Milestone-end extras

- [ ] Full play session of the milestone's content without guidance
- [ ] (from M5) Low-end phone: 30+ fps in the busiest scene, 2-hour session without a crash
- [ ] (from M3.5) Two devices: connect, play, disconnect, reconnect
- [ ] Update `RISKS.md` known bugs and `BACKLOG.md`
