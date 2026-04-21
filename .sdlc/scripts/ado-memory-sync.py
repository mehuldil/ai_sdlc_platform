#!/usr/bin/env python3
"""
ADO Auto-Linking for Distributed Memory Merges

Posts automatic comments to ADO work items when memory is merged:
- Which branches merged
- How many ADRs combined
- Who approved each decision
- Link to DECISION_LOG.json in git

Usage:
    python ado-memory-sync.py --story-id AB#2001 --merged-branch feature/oauth-core
"""

import os
import sys
import json
import argparse
import subprocess
import hashlib
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple

class ADOMemorySync:
    """Posts memory merge summaries to ADO work items and syncs state bidirectionally."""

    def __init__(self, story_id: str, merged_branch: str = "", repo_root: str = "."):
        self.story_id = story_id
        self.merged_branch = merged_branch
        self.repo_root = Path(repo_root)
        self.memory_dir = self.repo_root / ".sdlc" / "memory"
        self.ado_org = os.getenv("ADO_ORG", "")
        self.ado_project = os.getenv("ADO_PROJECT", "")
        self.ado_pat = os.getenv("ADO_PAT", "")

    def run(self) -> bool:
        """Execute ADO sync."""
        try:
            print(f"AI-SDLC: ADO sync for {self.story_id}")

            # Step 1: Validate ADO credentials
            if not self._validate_credentials():
                print("⚠ ADO credentials not configured, skipping ADO sync")
                return True  # Don't fail the merge, just skip ADO sync

            # Step 2: Load merge data
            merge_data = self._load_merge_data()
            if not merge_data:
                print("ℹ No merge data found, skipping ADO sync")
                return True

            # Step 3: Extract decision summary
            decision_summary = self._extract_decision_summary(merge_data)

            # Step 4: Format ADO comment
            ado_comment = self._format_ado_comment(decision_summary)

            # Step 5: Post to ADO
            if self._post_to_ado(ado_comment):
                print(f"✓ Posted memory merge summary to {self.story_id}")
                return True
            else:
                print("⚠ Failed to post to ADO (continuing anyway)")
                return True  # Don't fail the merge

        except Exception as e:
            print(f"⚠ Error during ADO sync: {str(e)}")
            return True  # Don't fail the merge

    def _validate_credentials(self) -> bool:
        """Check if ADO credentials are available."""
        return bool(self.ado_org and self.ado_pat)

    def _load_merge_data(self) -> Dict:
        """Load merge log and decision log."""
        data = {
            "merge_log": {},
            "decision_log": {},
            "branch_metadata": {},
            "story_metadata": {}
        }

        # Load MERGE_LOG.md
        merge_log_file = self.memory_dir / "MERGE_LOG.md"
        if merge_log_file.exists():
            with open(merge_log_file, 'r') as f:
                data["merge_log"] = f.read()

        # Load DECISION_LOG.json
        decision_log_file = self.memory_dir / "decisions" / "DECISION_LOG.json"
        if decision_log_file.exists():
            with open(decision_log_file, 'r') as f:
                data["decision_log"] = json.load(f)

        # Load BRANCH_METADATA.json
        branch_meta_file = self.memory_dir / "BRANCH_METADATA.json"
        if branch_meta_file.exists():
            with open(branch_meta_file, 'r') as f:
                data["branch_metadata"] = json.load(f)

        # Load STORY_METADATA.json
        story_meta_file = self.memory_dir / "STORY_METADATA.json"
        if story_meta_file.exists():
            with open(story_meta_file, 'r') as f:
                data["story_metadata"] = json.load(f)

        return data

    def _extract_decision_summary(self, merge_data: Dict) -> Dict:
        """Extract key information from merge data."""
        summary = {
            "merged_branch": self.merged_branch,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "decisions": [],
            "related_branches": [],
            "engineers": set()
        }

        # Extract decisions from DECISION_LOG.json
        decision_log = merge_data.get("decision_log", {})
        for adr_id, adr_data in decision_log.items():
            summary["decisions"].append({
                "id": adr_id,
                "file": adr_data.get("file", "unknown"),
                "branch": adr_data.get("branch", "unknown"),
                "status": adr_data.get("status", "unknown"),
                "timestamp": adr_data.get("timestamp", "")
            })

        # Extract related branches
        story_meta = merge_data.get("story_metadata", {})
        for branch_info in story_meta.get("branches", []):
            if branch_info.get("branch") != self.merged_branch:
                summary["related_branches"].append({
                    "branch": branch_info.get("branch"),
                    "engineer": branch_info.get("engineer"),
                    "repo": branch_info.get("repo")
                })
                summary["engineers"].add(branch_info.get("engineer", "unknown"))

        # Add current branch engineer
        branch_meta = merge_data.get("branch_metadata", {})
        if "owner" in branch_meta:
            summary["engineers"].add(branch_meta["owner"])

        summary["engineers"] = list(summary["engineers"])  # Convert set to list
        return summary

    def _format_ado_comment(self, summary: Dict) -> str:
        """Format merge summary as ADO comment."""
        comment = f"""## AI-SDLC: Memory Merged 🔀

**Branch Merged**: `{summary['merged_branch']}`
**Story**: {self.story_id}
**Timestamp**: {summary['timestamp']}

### Decisions Combined

"""

        if summary["decisions"]:
            for decision in summary["decisions"]:
                status_icon = "✓" if decision["status"] == "approved" else "⏳"
                comment += f"- {status_icon} **{decision['id']}** ({decision['branch']}) - {decision['status']}\n"
        else:
            comment += "- No decisions merged\n"

        # Related branches
        if summary["related_branches"]:
            comment += f"""

### Related Branches

Total branches on this story: {len(summary['related_branches']) + 1}

"""
            for branch in summary["related_branches"]:
                comment += f"- `{branch['branch']}` ({branch['repo']}) - Engineer: {branch['engineer']}\n"

        # Decision authority
        comment += f"""

### Team

Engineers involved: {', '.join(summary['engineers'])}

### Next Steps

1. Review merged decisions above
2. All ADRs in: `.sdlc/memory/{self.story_id}/decisions/DECISION_LOG.json`
3. Merge audit trail: `.sdlc/memory/{self.story_id}/MERGE_LOG.md`
4. Continue to next stage when ready

---
*Automatically posted by AI-SDLC Distributed Memory System*
"""

        return comment

    def _comment_exists(self, wi_id: str, content_hash: str) -> bool:
        """Check if a comment with the same content hash already exists (idempotency).

        Args:
            wi_id: Work item ID (e.g., "2001")
            content_hash: SHA256 hash of comment content

        Returns:
            True if comment with same hash exists, False otherwise
        """
        try:
            import base64
            import urllib.request
            import json as json_lib

            api_url = f"https://dev.azure.com/{self.ado_org}/{self.ado_project}/_apis/wit/workitems/{wi_id}/comments?api-version=7.0"

            auth_string = base64.b64encode(f":{self.ado_pat}".encode()).decode()
            headers = {
                "Authorization": f"Basic {auth_string}",
                "Content-Type": "application/json"
            }

            req = urllib.request.Request(api_url, headers=headers, method="GET")

            try:
                with urllib.request.urlopen(req) as response:
                    if response.status in [200, 201]:
                        data = json_lib.loads(response.read().decode())
                        comments = data.get("comments", [])

                        # Check each existing comment for content hash match
                        for comment in comments:
                            comment_text = comment.get("text", "")
                            # Look for hash marker in comment footer
                            if f"[hash:{content_hash}]" in comment_text:
                                print(f"ℹ Comment already exists (hash: {content_hash})")
                                return True

                        return False
                    else:
                        print(f"⚠ ADO API returned status {response.status}")
                        return False
            except Exception as e:
                print(f"⚠ Failed to fetch existing comments: {str(e)}")
                return False

        except Exception as e:
            print(f"⚠ Error checking comment existence: {str(e)}")
            return False

    def _post_to_ado(self, comment: str) -> bool:
        """Post comment to ADO work item with idempotency check.

        Checks if a comment with the same content already exists before posting
        to prevent duplicate comments on retries.
        """
        try:
            # Extract story number from story_id (e.g., "2001" from "AB#2001")
            story_num = self.story_id.split("#")[-1]

            # Calculate content hash for idempotency
            content_hash = hashlib.sha256(comment.encode()).hexdigest()[:8]

            # Check if comment already exists
            if self._comment_exists(story_num, content_hash):
                print(f"✓ Skipped duplicate comment (hash: {content_hash})")
                return True

            # Construct ADO API URL
            api_url = f"https://dev.azure.com/{self.ado_org}/{self.ado_project}/_apis/wit/workitems/{story_num}/comments"

            # Prepare headers
            import base64
            auth_string = base64.b64encode(f":{self.ado_pat}".encode()).decode()
            headers = {
                "Authorization": f"Basic {auth_string}",
                "Content-Type": "application/json"
            }

            # Add hash marker to comment for deduplication tracking
            comment_with_hash = comment + f"\n\n---\n*[hash:{content_hash}]*"

            # Prepare payload
            payload = {
                "text": comment_with_hash
            }

            # Post comment
            import urllib.request
            import json as json_lib

            req = urllib.request.Request(
                api_url,
                data=json_lib.dumps(payload).encode(),
                headers=headers,
                method="POST"
            )

            try:
                with urllib.request.urlopen(req) as response:
                    if response.status in [200, 201]:
                        print(f"✓ Posted comment (hash: {content_hash})")
                        return True
                    else:
                        print(f"⚠ ADO API returned status {response.status}")
                        return False
            except Exception as e:
                print(f"⚠ Failed to post to ADO: {str(e)}")
                return False

        except Exception as e:
            print(f"⚠ Error posting to ADO: {str(e)}")
            return False

    def sync_from_ado(self) -> bool:
        """Fetch work item state from ADO and update local memory files."""
        try:
            print(f"AI-SDLC: Syncing {self.story_id} from ADO...")

            # Step 1: Validate ADO credentials
            if not self._validate_credentials():
                print("⚠ ADO credentials not configured, skipping ADO sync")
                return True

            # Step 2: Extract story number from story_id (e.g., "2001" from "AB#2001")
            story_num = self.story_id.split("#")[-1]

            # Step 3: Fetch work item from ADO
            work_item = self._fetch_work_item(story_num)
            if not work_item:
                print(f"⚠ Could not fetch work item {self.story_id} from ADO")
                return False

            # Step 4: Extract and save state
            state_data = self._extract_state_from_work_item(work_item)
            self._save_state_to_memory(state_data)

            # Step 5: Log the sync operation
            self._log_sync_operation(story_num, "from_ado", state_data)

            print(f"✓ Synced {self.story_id} from ADO to local memory")
            return True

        except Exception as e:
            print(f"⚠ Error during ADO sync: {str(e)}")
            return False

    def _fetch_work_item(self, work_item_id: str) -> Optional[Dict]:
        """Fetch work item details from ADO REST API."""
        try:
            import base64
            import urllib.request

            api_url = f"https://dev.azure.com/{self.ado_org}/{self.ado_project}/_apis/wit/workitems/{work_item_id}?api-version=7.0"

            auth_string = base64.b64encode(f":{self.ado_pat}".encode()).decode()
            headers = {
                "Authorization": f"Basic {auth_string}",
                "Content-Type": "application/json"
            }

            req = urllib.request.Request(api_url, headers=headers, method="GET")

            try:
                with urllib.request.urlopen(req) as response:
                    if response.status in [200, 201]:
                        import json as json_lib
                        return json_lib.loads(response.read().decode())
                    else:
                        print(f"⚠ ADO API returned status {response.status}")
                        return None
            except Exception as e:
                print(f"⚠ Failed to fetch work item: {str(e)}")
                return None

        except Exception as e:
            print(f"⚠ Error fetching work item: {str(e)}")
            return None

    def _extract_state_from_work_item(self, work_item: Dict) -> Dict:
        """Extract state, assigned_to, iteration_path, tags from ADO work item."""
        fields = work_item.get("fields", {})
        return {
            "id": work_item.get("id", ""),
            "title": fields.get("System.Title", ""),
            "state": fields.get("System.State", ""),
            "assigned_to": fields.get("System.AssignedTo", ""),
            "iteration_path": fields.get("System.IterationPath", ""),
            "tags": fields.get("System.Tags", ""),
            "area_path": fields.get("System.AreaPath", ""),
            "created_date": fields.get("System.CreatedDate", ""),
            "changed_date": fields.get("System.ChangedDate", "")
        }

    def _save_state_to_memory(self, state_data: Dict) -> None:
        """Save state data to local memory file."""
        story_id = self.story_id
        state_file = self.memory_dir / f"ado-state-{story_id}.md"

        # Create memory directory if it doesn't exist
        self.memory_dir.mkdir(parents=True, exist_ok=True)

        content = f"""# ADO Work Item: {story_id}

**Last Synced:** {datetime.utcnow().isoformat()}Z

## ADO State

- **Title:** {state_data.get('title', 'N/A')}
- **State:** {state_data.get('state', 'N/A')}
- **Assigned To:** {state_data.get('assigned_to', 'N/A')}
- **Iteration Path:** {state_data.get('iteration_path', 'N/A')}
- **Tags:** {state_data.get('tags', 'N/A')}
- **Area Path:** {state_data.get('area_path', 'N/A')}
- **Created:** {state_data.get('created_date', 'N/A')}
- **Changed:** {state_data.get('changed_date', 'N/A')}

## Local Changes

*(Will be updated when local state differs from ADO)*
"""

        try:
            with open(state_file, 'w') as f:
                f.write(content)
            print(f"✓ State saved to {state_file}")
        except Exception as e:
            print(f"⚠ Failed to save state: {str(e)}")

    def _log_sync_operation(self, story_num: str, direction: str, state_data: Dict) -> None:
        """Log sync operation to sync log."""
        sync_log = self.memory_dir / "ado-sync-log.md"

        # Initialize log file if it doesn't exist
        if not sync_log.exists():
            self.memory_dir.mkdir(parents=True, exist_ok=True)
            with open(sync_log, 'w') as f:
                f.write("# ADO Sync Log\n\n")
                f.write("Log of all ADO sync operations (both directions)\n\n")

        # Append sync entry
        sync_entry = f"""## Sync {datetime.utcnow().isoformat()}Z

**Direction:** {'ADO → Local' if direction == 'from_ado' else 'Local → ADO'}
**Work Item:** {story_num}
**State:** {state_data.get('state', 'N/A')}

"""

        try:
            with open(sync_log, 'a') as f:
                f.write(sync_entry)
        except Exception as e:
            print(f"⚠ Failed to log sync: {str(e)}")


def main():
    parser = argparse.ArgumentParser(
        description="Sync work item state with ADO (post merge summaries or fetch state)"
    )
    parser.add_argument("--story-id", required=True, help="Story ID (e.g., AB#2001)")
    parser.add_argument("--merged-branch", default="", help="Branch being merged (for merge sync)")
    parser.add_argument("--sync-from", action="store_true", help="Fetch state from ADO instead of posting merge summary")
    parser.add_argument("--repo-root", default=".", help="Git repository root")

    args = parser.parse_args()

    sync = ADOMemorySync(
        story_id=args.story_id,
        merged_branch=args.merged_branch,
        repo_root=args.repo_root
    )

    if args.sync_from:
        success = sync.sync_from_ado()
    else:
        success = sync.run()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
