# Machine Profile Schema (v1)

Wawona stores machine profiles in a JSON array under `wawona.machineProfiles.v1`
with the active profile tracked in `wawona.activeMachineId.v1`.

Each profile uses this normalized shape:

- `id`, `name`, `type`
- `sshEnabled`, `sshHost`, `sshUser`, `sshPassword`
- `sshBinary`, `sshAuthMethod`, `sshKeyPath`, `sshKeyPassphrase`
- `remoteCommand`, `customScript`
- `vmSubtype`, `containerSubtype`
- `waypipeCompress`, `waypipeThreads`, `waypipeVideo`
- `waypipeDebug`, `waypipeOneshot`, `waypipeDisableGpu`, `waypipeLoginShell`
- `waypipeTitlePrefix`, `waypipeSecCtx`
- `favorite`, `createdAtMs`, `updatedAtMs`

Machine `type` values:

- `native` (local host compositor)
- `ssh_waypipe`
- `ssh_terminal`
- `virtual_machine`
- `container`

Transient (non-persisted) UI/runtime status values used by machine grid cards:

- `disconnected`
- `connecting`
- `connected`
- `degraded`
- `error`

Notes:

- Apple and Android both migrate from legacy flat `waypipe*` preferences
  into one initial machine profile when no profile list exists.
- Runtime launch remains backward-compatible by applying the selected machine
  back into legacy runtime preference keys before connect/run.
