# VS Code Installation

## Install VS Code with Snap

Install the stable VS Code package with:

```bash
sudo snap install code --classic
```

Verify the installation:

```bash
snap list code
code --version
```

The repository also provides an installer:

```bash
./install-vscode-snap.sh
```

## VS Code Insiders

If the Insiders build is required, install it separately:

```bash
sudo snap install code-insiders --classic
```

Verify it with:

```bash
snap list code-insiders
code-insiders --version
```

Install Insiders with the same script:

```bash
./install-vscode-snap.sh --insiders
```

## Project Launcher

`vscode-with-podman.sh` currently launches `code-insiders`. Use the Insiders package
when using that script, or change the launcher to call `code` for the stable build.

## Recommended Extensions

Workspace extension recommendations are stored in `.vscode/extensions.json`. VS Code
will offer to install them when the workspace is opened.
