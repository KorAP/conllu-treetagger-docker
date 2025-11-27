# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 3.2.5-5

### Fixed

- Use proper -prob flag for making tree-tagger output different interpretations with probabilities

### Added
- **threshold option**: Added `-t` option to set probability threshold (default: 0.1)
- **Probability-based Sorting**: Annotations now sorted in descending order by probability value
- **Smart Lemma Handling**: 
  - Lemmas are paired with their corresponding POS tags and sorted together
  - Automatic deduplication when all lemmas are identical (e.g., `die|die|die` → `die`)
  - Preserves all lemmas when different to show tag-lemma relationships
- **CI/CD Improvements**:
  - GitHub Actions workflow for automated testing
  - GitLab CI pipeline with test, build, and deploy stages
  - Automated tests for sorting and lemma deduplication
  - Docker Hub deployment workflow

### Changed
- **Docker Configuration**: 
  - Updated to use `docker:latest` with DNS configuration for GitLab runners
  - Added `FF_NETWORK_PER_BUILD` variable for network isolation
- **Docker Login**: Updated to use `--password-stdin` for secure authentication

## [3.2.5-4] - 2025-11-25

### Added
- **Rust Implementation**: Replaced Perl post-processing scripts with optimized Rust implementation
  - `korap-treetagger-processor` binary with three subcommands: `preprocess`, `postprocess`, `filter-german`
  - Significant performance improvements through buffered I/O
  - Identical output to original Perl scripts
- **Model Management**: 
  - Docker volume support for persistent model storage at `/local/models`
  - Automatic model download and caching
  - Graceful fallback to ephemeral storage if volume is not writable
- **Probability Output**: Added `-p` flag to output probability values in MISC column

### Changed
- **Docker Image Name**: Renamed from `korap/conllu2treetagger` to `korap/conllu-treetagger`
- **Build System**: Updated to use `make build-docker` command
- **Logging**: All informational messages redirected to stderr to keep stdout clean for data processing
- **Model Installation**: Patched `install-tagger.sh` to suppress "File exists" warnings

### Removed
- Pre-bundled language models from Docker image (for copyright compliance and reduced image size)
- Perl dependencies for post-processing (replaced with Rust)

### Fixed
- Filter-german pass-through issues for comments and empty lines
- Language installation warnings during Docker build
- Mutable borrow errors in Rust implementation

### Performance
- Reduced system time through buffered I/O operations
- Faster processing through compiled Rust code vs. interpreted Perl

## [3.2.5-3] - Previous Version

### Initial KorAP Fork
- Forked from [sfischer13/docker-treetagger](https://github.com/sfischer13/docker-treetagger)
- Added CoNLL-U format support
- Integrated with KorAP pipeline

---

## Credits

- **Original Author**: [Stefan Fischer](https://github.com/sfischer13) - docker-treetagger
- **TreeTagger**: [Helmut Schmid](http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/)
- **KorAP Enhancements**: Marc Kupietz and contributors
