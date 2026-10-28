# Assignment 3 — CI/CD with GitHub Actions

A Bash diagnostic application with linting, automated tests, a Docker image and a GitHub Actions CI pipeline that runs **validate → test → docker** on every push and pull request. There is no cloud deployment.

## Project structure

```
assignment-3/
├── README.md
├── app/
│   └── app.sh                 # The application
├── scripts/
│   ├── lint.sh                # Required files, bash -n, ShellCheck
│   └── build.sh               # Docker build + smoke tests
├── tests/
│   └── test.sh                # 13 automated tests for app.sh
├── .github/
│   └── workflows/
│       └── ci.yml             # CI pipeline
├── Dockerfile
├── compose.yaml
├── .dockerignore
└── grade.sh                   # Instructor grading script
```

## Requirements

- Linux (tested on Ubuntu 26.04 under WSL2)
- Bash 4+
- Docker with the Compose plugin
- Optional: ShellCheck (`sudo apt install -y shellcheck`)

## Setup

```bash
git clone https://github.com/Wonderfullymade01/assignment-3.git
cd assignment-3
chmod +x grade.sh app/*.sh scripts/*.sh tests/*.sh
```

## Usage

```bash
./app/app.sh system-info
./app/app.sh check-host <host>
./app/app.sh check-port <host> <port>
./app/app.sh help
```

| Command | Description |
|---|---|
| `system-info` | Show hostname, user, date/time, OS, kernel, uptime, CPU and memory |
| `check-host <host>` | Validate and resolve a hostname or IP address |
| `check-port <host> <port>` | Validate the port (1–65535) and check TCP connectivity |
| `help` | Show usage |

### Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Operational/runtime failure (host cannot be resolved, port closed) |
| 2 | Invalid command or input (unknown command, missing host/port, bad port) |

### With Docker

```bash
docker build -t devops-tool .
docker run --rm devops-tool help
docker run --rm devops-tool system-info
docker run --rm devops-tool check-host localhost
```

### With Docker Compose

```bash
docker compose run --rm devops-tool system-info
```

## Scripts

| Script | What it does |
|---|---|
| `scripts/lint.sh` | Checks all required files exist, runs `bash -n` on every script, checks scripts are executable, and runs ShellCheck (errors only) if installed |
| `tests/test.sh` | 13 tests covering help, system-info, invalid/missing commands, missing host, valid host, invalid host, missing port, non-numeric port and out-of-range ports |
| `scripts/build.sh` | Builds the `devops-tool` image and runs 6 smoke tests in containers, including an invalid-command test |

Run them locally:

```bash
./scripts/lint.sh
./tests/test.sh
./scripts/build.sh
```

## Docker image

- **Base image:** `alpine:3.20`
- **Packages:** only `bash`; `getent`, `timeout`, `awk` and `nproc` come with Alpine
- **Non-root:** runs as `appuser`
- **Entrypoint:** `/app/app.sh`, default command `help`
- **Health check:** runs `app.sh help`
- **.dockerignore:** excludes `.git`, `.github`, tests, scripts, logs and other files not needed at runtime

## CI pipeline

Defined in `.github/workflows/ci.yml`. It runs on every `push` and `pull_request`.

```
validate  →  test  →  docker
```

| Job | Runs | Depends on |
|---|---|---|
| `validate` | `scripts/lint.sh` | — |
| `test` | `tests/test.sh` | `needs: validate` |
| `docker` | `scripts/build.sh` | `needs: test` |

Each job checks out the code on a fresh `ubuntu-latest` runner. Because of `needs:`, a failure stops the pipeline: later jobs are skipped.

## CI failure demonstration

1. Created the branch `demo/ci-failure` from `main`.
2. Introduced a syntax error in `app/app.sh` (changed `esac` to `esc`) and pushed it.
3. Opened [pull request #1](https://github.com/Wonderfullymade01/assignment-3/pull/1). CI **failed**: the `validate` job's lint step reported a Bash syntax error, and the `test` and `docker` jobs were skipped. [Failed run](https://github.com/Wonderfullymade01/assignment-3/actions/runs/40706580612)
4. Fixed the syntax error and pushed again. CI **passed**: all three jobs succeeded. [Passing run](https://github.com/Wonderfullymade01/assignment-3/actions/runs/40707053316)
5. Merged the pull request into `main`.

## Testing

```bash
./grade.sh
```

## Assumptions

- Tests use `localhost` only, so they don't depend on internet access in CI.
- `check-host` only resolves the host and does not ping it, because ping (ICMP) is often blocked on CI runners.
- `check-port` uses Bash's built-in `/dev/tcp` with a 3-second timeout, so it does not need `nc` to be installed.
- Containers use UTC time.

## Git workflow

- `feature/ci-pipeline`: application, tests, scripts, Docker and CI, merged into `main`
- `demo/ci-failure`: CI failure demonstration, merged into `main` through pull request #1
