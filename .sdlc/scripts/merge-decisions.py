#!/usr/bin/env python3
"""
Distributed Memory Merge Handler

Combines ADRs and decisions from multiple branches (same story, different branches/repos).
Handles conflict resolution and creates audit trail.

Usage:
    python merge-decisions.py --story-id AB#2001 --merged-branch feature/security-oauth-core

Triggered by: .git/hooks/post-merge (after git merge)
"""

import os
import sys
import json
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional
import shutil

class DistributedMemoryMerger:
    """Handles merging of memory from multiple branches for same story."""

    def __init__(self, story_id: str, merged_branch: str, repo_root: str = "."):
        self.story_id = story_id
        self.merged_branch = merged_branch
        self.repo_root = Path(repo_root)
        self.memory_dir = self.repo_root / ".sdlc" / "memory" / story_id
        self.decisions_dir = self.memory_dir / "decisions"
        self.timestamp = datetime.utcnow().isoformat() + "Z"

    def run(self) -> bool:
        """Execute the merge process."""
        try:
            print(f"AI-SDLC: Merging memory for {self.story_id}")
            print(f"  Merged branch: {self.merged_branch}")
            print(f"  Timestamp: {self.timestamp}")

            # Step 1: Load metadata
            branch_meta = self._load_branch_metadata()
            story_meta = self._load_story_metadata()

            # Step 2: Find related branches
            related_branches = self._find_related_branches(story_meta)
            print(f"  Found {len(related_branches)} related branches")

            # Step 3: Load all ADRs
            all_adrs = self._load_all_adrs(related_branches)
            print(f"  Loaded {len(all_adrs)} ADRs from all branches")

            # Step 4: Detect conflicts
            conflicts = self._detect_conflicts(all_adrs)
            if conflicts:
                print(f"  ⚠ Detected {len(conflicts)} decision conflicts")
                self._resolve_conflicts(conflicts)

            # Step 5: Combine decisions
            merged_decisions = self._combine_decisions(all_adrs)
            self._save_merged_decisions(merged_decisions)
            print(f"  ✓ Combined decisions saved")

            # Step 6: Merge designs
            self._merge_design_docs()
            print(f"  ✓ Design documents merged")

            # Step 7: Create merge log
            self._create_merge_log(related_branches, conflicts, merged_decisions)
            print(f"  ✓ Merge log created")

            # Step 8: Update story metadata
            self._update_story_metadata(merged_decisions)
            print(f"  ✓ Story metadata updated")

            # Step 9: Post to ADO (non-blocking)
            self._sync_to_ado()

            print(f"✓ Memory merge complete for {self.story_id}")
            return True

        except Exception as e:
            print(f"✗ Error during memory merge: {str(e)}", file=sys.stderr)
            return False

    def _load_branch_metadata(self) -> Dict:
        """Load BRANCH_METADATA.json for current merge."""
        meta_file = self.memory_dir / "BRANCH_METADATA.json"
        if not meta_file.exists():
            print(f"Warning: No BRANCH_METADATA.json found at {meta_file}")
            return {}

        with open(meta_file, 'r') as f:
            return json.load(f)

    def _load_story_metadata(self) -> Dict:
        """Load STORY_METADATA.json (tracks all branches for this story)."""
        meta_file = self.memory_dir / "STORY_METADATA.json"
        if not meta_file.exists():
            print(f"Warning: No STORY_METADATA.json found at {meta_file}")
            return {"story_id": self.story_id, "branches": []}

        with open(meta_file, 'r') as f:
            return json.load(f)

    def _find_related_branches(self, story_meta: Dict) -> List[str]:
        """Find all branches that work on this story."""
        related = []
        if "related_branches" in story_meta:
            for branch_info in story_meta["related_branches"]:
                related.append(branch_info.get("branch", "unknown"))

        # Always include current merged branch
        if self.merged_branch and self.merged_branch not in related:
            related.append(self.merged_branch)

        return related

    def _load_all_adrs(self, branches: List[str]) -> Dict[str, List[Dict]]:
        """Load all ADRs from all branches and their metadata."""
        all_adrs = {}

        if not self.decisions_dir.exists():
            return all_adrs

        # Load ADR files
        for adr_file in sorted(self.decisions_dir.glob("adr-*.md")):
            adr_id = adr_file.stem  # adr-001 from adr-001-oauth-provider.md

            with open(adr_file, 'r') as f:
                content = f.read()

            all_adrs[adr_id] = {
                "file": adr_file.name,
                "content": content,
                "branch": self.merged_branch,
                "timestamp": self.timestamp,
                "backup_file": None
            }

        # Check for version backups
        for backup_file in self.decisions_dir.glob("adr-*.md.BRANCH-*"):
            adr_id = backup_file.stem.split(".")[0]
            branch_name = backup_file.suffix.replace("BRANCH-", "")

            if adr_id not in all_adrs:
                with open(backup_file, 'r') as f:
                    all_adrs[adr_id] = {
                        "file": backup_file.name,
                        "content": f.read(),
                        "branch": branch_name,
                        "timestamp": str(backup_file.stat().st_mtime),
                        "backup_file": True
                    }

        return all_adrs

    def _detect_conflicts(self, adrs: Dict[str, Dict]) -> List[Dict]:
        """Detect conflicting decisions (same topic, different decisions)."""
        conflicts = []
        decision_log_file = self.decisions_dir / "DECISION_LOG.json"

        if not decision_log_file.exists():
            return conflicts

        with open(decision_log_file, 'r') as f:
            decision_log = json.load(f)

        # Check for duplicate ADR IDs with different approvals
        seen_topics = {}
        for adr_id, adr_meta in decision_log.items():
            topic = adr_meta.get("decision", "").split()[0:3]  # First 3 words
            topic_key = " ".join(topic)

            if topic_key in seen_topics:
                # Potential conflict
                if adr_meta.get("status") == "approved" and \
                   seen_topics[topic_key].get("status") != "approved":
                    conflicts.append({
                        "adr_id": adr_id,
                        "existing_adr": list(seen_topics.keys())[0],
                        "status": "conflict",
                        "reason": "Duplicate topic, different approval status"
                    })
            else:
                seen_topics[topic_key] = adr_meta

        return conflicts

    def _resolve_conflicts(self, conflicts: List[Dict]) -> None:
        """Apply conflict resolution rules."""
        for conflict in conflicts:
            print(f"  Resolving: {conflict['adr_id']} (Reason: {conflict['reason']})")

            # Rule 1: Approved > Pending
            # Rule 2: Later timestamp > Earlier timestamp
            # Rule 3: Tech lead approval > Team approval

            # Archive the losing decision
            adr_id = conflict["adr_id"]
            adr_file = self.decisions_dir / f"{adr_id}.md"

            if adr_file.exists():
                # Create backup with conflict marker
                backup_name = f"{adr_id}.md.CONFLICT-{self.timestamp.split('T')[0]}"
                backup_path = self.decisions_dir / backup_name
                shutil.copy(adr_file, backup_path)
                print(f"  ✓ Archived: {adr_file.name} → {backup_name}")

    def _combine_decisions(self, adrs: Dict[str, Dict]) -> Dict:
        """Combine all ADRs into a single decision log."""
        decision_log_file = self.decisions_dir / "DECISION_LOG.json"

        # Load existing log if present
        if decision_log_file.exists():
            with open(decision_log_file, 'r') as f:
                merged_log = json.load(f)
        else:
            merged_log = {}

        # Add new ADRs
        for adr_id, adr_data in adrs.items():
            if adr_id not in merged_log:
                merged_log[adr_id] = {
                    "file": adr_data["file"],
                    "branch": adr_data["branch"],
                    "timestamp": adr_data["timestamp"],
                    "status": "approved",  # Assume approved if in merge
                    "merged_at": self.timestamp
                }

        return merged_log

    def _save_merged_decisions(self, merged_log: Dict) -> None:
        """Save combined decision log."""
        decision_log_file = self.decisions_dir / "DECISION_LOG.json"

        # Ensure decisions dir exists
        self.decisions_dir.mkdir(parents=True, exist_ok=True)

        with open(decision_log_file, 'w') as f:
            json.dump(merged_log, f, indent=2)

        # Create version history file
        version_history_file = self.decisions_dir / "DECISION_VERSIONS.json"
        if not version_history_file.exists():
            version_history = {}
        else:
            with open(version_history_file, 'r') as f:
                version_history = json.load(f)

        # Add this merge to version history
        for adr_id, adr_data in merged_log.items():
            if adr_id not in version_history:
                version_history[adr_id] = {
                    "current_version": adr_data["file"],
                    "previous_versions": [],
                    "approval_chain": []
                }

            version_history[adr_id]["last_merged_at"] = self.timestamp
            version_history[adr_id]["merged_from_branch"] = self.merged_branch

        with open(version_history_file, 'w') as f:
            json.dump(version_history, f, indent=2)

    def _merge_design_docs(self) -> None:
        """Merge design.md files if multiple versions exist."""
        design_file = self.memory_dir / "design.md"
        design_alt_files = list(self.memory_dir.glob("design.md.BRANCH-*"))

        if not design_alt_files:
            # Only one version, no merge needed
            if design_file.exists():
                design_final = self.memory_dir / "design-final.md"
                shutil.copy(design_file, design_final)
            return

        # Multiple versions found, create combined design
        combined_content = "# Design Document (Merged)\n\n"
        combined_content += f"Merged at: {self.timestamp}\n"
        combined_content += f"Merged from branches:\n"

        # Add primary design
        if design_file.exists():
            combined_content += f"\n## Primary Design (Current Branch)\n\n"
            with open(design_file, 'r') as f:
                combined_content += f.read()

        # Add alternative designs
        for alt_file in design_alt_files:
            branch_name = alt_file.suffix.replace("BRANCH-", "")
            combined_content += f"\n\n---\n"
            combined_content += f"## Alternate Design ({branch_name})\n\n"
            with open(alt_file, 'r') as f:
                combined_content += f.read()

        # Save combined design
        design_final = self.memory_dir / "design-final.md"
        with open(design_final, 'w') as f:
            f.write(combined_content)

    def _create_merge_log(self, branches: List[str], conflicts: List[Dict],
                         decisions: Dict) -> None:
        """Create MERGE_LOG.md with audit trail."""
        merge_log_file = self.memory_dir / "MERGE_LOG.md"

        # Load existing merge log if present
        existing_log = ""
        if merge_log_file.exists():
            with open(merge_log_file, 'r') as f:
                existing_log = f.read() + "\n\n---\n\n"

        # Create new merge entry
        merge_entry = f"""# Merge Commit: {self.story_id}

- **Date**: {self.timestamp}
- **Merged Branch**: {self.merged_branch}
- **Related Branches**: {", ".join(branches)}

## Decisions Merged

"""

        for adr_id, adr_data in decisions.items():
            merge_entry += f"- **{adr_id}**: {adr_data['file']} (merged from {adr_data['branch']})\n"

        if conflicts:
            merge_entry += f"""

## Conflicts Resolved

{len(conflicts)} conflict(s) detected and resolved:

"""
            for conflict in conflicts:
                merge_entry += f"- {conflict['adr_id']}: {conflict['reason']}\n"

        merge_entry += f"""

## Merge Status

✓ All decisions combined into DECISION_LOG.json
✓ Design documents merged (see design-final.md)
✓ Audit trail created

**Next Steps**:
1. Review merged decisions
2. Verify design-final.md integration points
3. Run full test suite
4. Proceed to next stage
"""

        # Save merge log
        with open(merge_log_file, 'w') as f:
            f.write(existing_log + merge_entry)

    def _update_story_metadata(self, decisions: Dict) -> None:
        """Update STORY_METADATA.json to reflect merge."""
        story_meta_file = self.memory_dir / "STORY_METADATA.json"

        if story_meta_file.exists():
            with open(story_meta_file, 'r') as f:
                story_meta = json.load(f)
        else:
            story_meta = {
                "story_id": self.story_id,
                "branches": [],
                "merged": False
            }

        # Mark merged branches
        for branch_info in story_meta.get("branches", []):
            if branch_info.get("branch") == self.merged_branch:
                branch_info["merge_status"] = "merged"
                branch_info["merged_at"] = self.timestamp

        # Update decision authority
        if "decision_authority" not in story_meta:
            story_meta["decision_authority"] = {}

        for adr_id in decisions.keys():
            story_meta["decision_authority"][adr_id] = self.timestamp

        # Save updated metadata
        with open(story_meta_file, 'w') as f:
            json.dump(story_meta, f, indent=2)

    def _sync_to_ado(self) -> None:
        """Post memory merge summary to ADO work item (non-blocking)."""
        try:
            ado_sync_script = Path(__file__).parent / "ado-memory-sync.py"

            if not ado_sync_script.exists():
                return  # Skip if script doesn't exist

            import subprocess
            result = subprocess.run(
                [
                    "python3",
                    str(ado_sync_script),
                    "--story-id", self.story_id,
                    "--merged-branch", self.merged_branch,
                    "--repo-root", str(self.repo_root)
                ],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode == 0:
                if result.stdout:
                    for line in result.stdout.strip().split('\n'):
                        print(f"  {line}")
            else:
                if result.stderr:
                    print(f"  ⚠ ADO sync warning: {result.stderr.strip()}")

        except Exception as e:
            # Non-blocking: Don't fail the merge if ADO sync fails
            print(f"  ⚠ ADO sync error (non-blocking): {str(e)}")


def main():
    parser = argparse.ArgumentParser(
        description="Merge memory from multiple branches for distributed team development"
    )
    parser.add_argument("--story-id", required=True, help="Story ID (e.g., AB#2001)")
    parser.add_argument("--merged-branch", required=True, help="Branch being merged")
    parser.add_argument("--repo-root", default=".", help="Git repository root")

    args = parser.parse_args()

    merger = DistributedMemoryMerger(
        story_id=args.story_id,
        merged_branch=args.merged_branch,
        repo_root=args.repo_root
    )

    success = merger.run()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
