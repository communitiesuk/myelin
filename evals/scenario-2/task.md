# Config File Parser Utility

## Problem/Feature Description

A backend team at a growing SaaS company has multiple microservices that each read settings from INI-format configuration files. Today the config-reading logic is duplicated across services — each one calls `configparser` directly, with inconsistent behavior when files are missing or have formatting errors. During a recent outage, a service silently fell back to defaults because a missing config file was not caught early enough.

The tech lead wants a shared `config_utils` module that all services can import. It should expose a single function, `parse_config(filepath)`, that:

- Accepts a string or `pathlib.Path` argument pointing to an INI configuration file
- Returns a nested dictionary mapping section names to a dictionary of key-value pairs within that section
- Raises `FileNotFoundError` (with a descriptive message) if the target file does not exist at the given path
- Raises an appropriate error (with a descriptive message) if the file exists but cannot be parsed as a valid INI file

The team writes tests with `pytest` and values clean, auditable commit histories.

## Output Specification

Produce the following files in the current directory:

- `config_utils.py` — the module containing the `parse_config(filepath)` function
- `test_config_utils.py` — the pytest test suite for `parse_config`
- `WORKFLOW.md` — a document describing the development steps you followed, any commands you ran (including test runs and any linting), and the output of `git log --oneline` showing the full commit sequence

Initialize a git repository in the working directory if one does not already exist, and commit your work as you proceed.
