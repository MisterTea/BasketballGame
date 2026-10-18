# Arcade research and implementation log

Target: the original 1993 NBA Jam arcade cabinet. Tournament Edition, console ports and later games are separate references. This project retains original fictional teams, 3D graphics and locally generated HY-Motion animation.

## Sources reviewed — 2026-10-18

- [Midway arcade operations manual](https://www.arcade-museum.com/manuals-videogames/N/NBAJam.pdf), PDF page 2, actual scanned instructions inspected. Confirms the three action buttons, turbo combinations, and that pressing Pass or Shoot orders a CPU teammate with possession to perform that action. This is the primary source for teammate commands. A research copy remains in ignored `.runtime/research/`; copyrighted scans are not shipped.
- [Museum of the Game arcade entry](https://www.arcade-museum.com/Videogame/nba-jam), gameplay and introduction read. Describes four three-minute quarters, individual three-basket fire, enhanced accuracy, unlimited personal turbo and immunity to goaltending. Opposing baskets end fire. Its unspecified computer-controlled fire timeout is not implemented without a reproducible trigger.
- [Fast Eddie's original-game FAQ](https://gamefaqs.gamespot.com/arcade/583605-nba-jam/faqs/748), indexed excerpts only; full-page access was restricted. Supports individual fire surviving misses and ending on an opponent's basket. The FAQ also covers ports, so platform-specific secrets are not assumed to apply to the cabinet.
- [Operation Sports retrospective](https://www.operationsports.com/throwback-thursday-nba-jam/), Elliott Jenkins, November 17, 2016, read. Useful qualitative evidence for the fast 2-on-2 feel, dunks, shoves, blocks and comeback assistance. It discusses several versions; its descriptions alone do not establish original-cabinet edge rules.
- [TKunka's Tournament Edition FAQ](https://gamefaqs.gamespot.com/arcade/583606-nba-jam-tournament-edition/faqs/749) and [Brian Sulpher's Tournament Edition FAQ](https://gamefaqs.gamespot.com/arcade/583606-nba-jam-tournament-edition/faqs/19427), indexed excerpts only. Corroborate goaltending/fire interactions for TE. They are explicitly weaker evidence for the original release.

## Implemented from this review

- Default quarters now last 3:00, with shorter house-rule options retained.
- Heat belongs to the individual scorer. Two consecutive baskets show Heating Up; three ignite Fire. Alternating teammate scores cannot combine into ignition. Only that athlete gets the accuracy boost, unlimited turbo, player flames and a flaming shot trail.
- Established fire survives misses and teammate baskets. An opponent's natural basket ends it. A miss resets a cold athlete's heating streak.
- Reachable ascending-shot contact is a block. Reachable descending contact close to the basket awards the shot's two or three points as goaltending, even if the simulated shot would miss. The defender gets the inbound; goaltends have their own GT statistic. The burning defender can legally reject such a shot.
- Off-ball Pass orders a CPU ball carrier to return the ball. Hold/release Shoot orders that teammate to shoot using the existing timing. A pass order cancels a CPU shot windup. Another human's input is never overridden.
- CPU defenders now recognize shots after ball ownership clears, attempt reachable legal blocks and avoid deliberately goaltending while cold. All new state travels in host snapshots.

## Fidelity limits and unresolved questions

These are implemented rules, not a claim of complete original-cabinet parity. In particular, goaltending points leaving both sides' heat unchanged and not counting toward ignition are provisional original-game choices supported by TE descriptions. Exact original revision behavior needs footage or direct cabinet verification. The teammate-score handling before ignition also needs that check.

Contact uses the game's existing distance/height checks at the start of a block. It does not yet model hand-to-ball collisions throughout the jump. A blocked ball follows the existing flight/rebound path instead of a physical deflection. The side camera currently frames the whole court rather than tracking possession like the cabinet.

No video has been watched. Opening [the candidate arcade longplay](https://www.youtube.com/watch?v=jzQmf1edPkY) was denied by the browser access gate because origin access was declined. No download or alternate access was attempted. Video comparison remains pending until access changes or an authorized local video is available.

Next fidelity work: observe actual cabinet possession/camera and shot timings; verify fire edge rules and backboard-destruction triggers; implement the backboard spectacle, tip-off and period transitions; improve ball-contact/rebounds and shot fakes; expand persistent arcade progression and attract/replay presentation. Original roster/secret-character completeness, cabinet credits/service settings, audio/commentary and production internet networking remain outside the current prototype's verified coverage.

## Verification

`tests/arcade_rules.gd` checks 31 rule and input scenarios, including CPU blocks, fire/goaltending, teammate release timing and snapshot restoration. The four-process network test additionally verifies individual fire and GT statistics on all three clients. Arena tests verify individual flame ownership and shot trails without mutating simulation state. GPU captures cover the help page, individual fire/dunk, results columns and animated crowd. See [validation](VALIDATION.md) for outcomes.

![Verified goaltending award and individual fire HUD](arcade_goaltending.png)
