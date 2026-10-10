Project state and working protocol: .project-brain/ is the source of truth — read config.yaml, current.md, target.md, constraints.md, then tasks/. Follow the project-brain protocol (boot sequence + task loop) of the installed project-brain skill; keep .project-brain/.cache/ reconstructable only (gitignored).

<!-- project-brain -->
## Project Brain
This project keeps its state in `.project-brain/` (current architecture, target, open tasks).
Before any work, load the `project-brain` skill and run its boot step; follow it for all work here.
