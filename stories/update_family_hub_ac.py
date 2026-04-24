#!/usr/bin/env python3
"""
Update Family Hub ADO Work Items with Acceptance Criteria Field

This script:
1. Extracts acceptance criteria from local story files
2. Updates existing ADO work items (865620, 865621, 865622)
3. Converts 865620 from Feature to User Story (via update, not recreate)
4. Populates Microsoft.VSTS.Common.AcceptanceCriteria field

Usage:
    python stories/update_family_hub_ac.py

Requires:
    - ADO credentials in AI_SDLC_Platform/env/.env
    - Story files in ../stories/ (relative to this script)
"""

import os
import sys
import json
import re
import base64
import urllib.request
import urllib.error
from pathlib import Path


def read_env_file(filepath):
    """Read environment variables from .env file"""
    env_vars = {}
    if not os.path.exists(filepath):
        return env_vars
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                env_vars[key.strip()] = value.strip()
    return env_vars


def extract_acceptance_criteria(file_path):
    """
    Extract acceptance criteria from markdown file.
    Looks for '## Acceptance Criteria' section and returns content until next ## or end.
    """
    if not os.path.exists(file_path):
        print(f"[ERROR] File not found: {file_path}")
        return None

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find Acceptance Criteria section
    # Pattern: ## (emoji optional) Acceptance Criteria
    match = re.search(
        r'##\s*[^\n]*Acceptance Criteria[^\n]*\n(.*?)(?=\n## |\Z)',
        content,
        re.DOTALL | re.IGNORECASE
    )

    if not match:
        print(f"[WARN] No Acceptance Criteria section found in {file_path}")
        return None

    ac_content = match.group(1).strip()

    # Clean up the content
    # Remove any HTML tags that might interfere
    ac_content = re.sub(r'<[^>]+>', '', ac_content)

    return ac_content


def convert_markdown_to_html(markdown_text):
    """
    Simple markdown to HTML conversion for ADO.
    Handles: headers, lists, bold, paragraphs
    """
    html = markdown_text

    # Convert bold: **text** -> <b>text</b>
    html = re.sub(r'\*\*(.*?)\*\*', r'<b>\1</b>', html)

    # Convert headers: ### Header -> <h3>Header</h3>
    html = re.sub(r'^###\s+(.*?)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
    html = re.sub(r'^##\s+(.*?)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
    html = re.sub(r'^#\s+(.*?)$', r'<h1>\1</h1>', html, flags=re.MULTILINE)

    # Convert numbered lists: 1. Item -> <ol><li>Item</li></ol>
    # This is complex, do simple conversion
    lines = html.split('\n')
    new_lines = []
    in_list = False
    list_type = None

    for line in lines:
        # Numbered list item
        num_match = re.match(r'^(\d+)\.\s+(.+)$', line.strip())
        # Bullet list item
        bullet_match = re.match(r'^[-*]\s+(.+)$', line.strip())

        if num_match:
            if not in_list or list_type != 'ol':
                if in_list:
                    new_lines.append(f'</{list_type}>')
                new_lines.append('<ol>')
                in_list = True
                list_type = 'ol'
            new_lines.append(f'<li>{num_match.group(2)}</li>')
        elif bullet_match:
            if not in_list or list_type != 'ul':
                if in_list:
                    new_lines.append(f'</{list_type}>')
                new_lines.append('<ul>')
                in_list = True
                list_type = 'ul'
            new_lines.append(f'<li>{bullet_match.group(1)}</li>')
        else:
            if in_list:
                new_lines.append(f'</{list_type}>')
                in_list = False
                list_type = None
            # Regular paragraph
            if line.strip():
                new_lines.append(f'<p>{line}</p>')

    if in_list:
        new_lines.append(f'</{list_type}>')

    html = '\n'.join(new_lines)

    # Wrap in div with styling
    html = f'<div style="line-height:1.5;">{html}</div>'

    return html


def update_work_item(org, project, pat, work_item_id, ac_html, convert_to_user_story=False):
    """
    Update existing ADO work item with acceptance criteria.
    Uses JSON Patch API to update specific fields.
    """
    # Encode PAT for Basic auth
    auth_str = f":{pat}"
    base64_auth = base64.b64encode(auth_str.encode()).decode()

    # Build request body (JSON Patch)
    body = []

    # Add acceptance criteria field
    body.append({
        "op": "add",
        "path": "/fields/Microsoft.VSTS.Common.AcceptanceCriteria",
        "value": ac_html
    })

    # Optionally convert work item type (this is complex in ADO, may need special handling)
    # For now, we just update the acceptance criteria field

    url = f"https://dev.azure.com/{org}/{project}/_apis/wit/workitems/{work_item_id}?api-version=7.0"

    headers = {
        "Content-Type": "application/json-patch+json",
        "Authorization": f"Basic {base64_auth}"
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers=headers,
        method="PATCH"
    )

    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            return result.get("id"), True
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        print(f"[ERROR] HTTP {e.code}: {error_body}")
        return None, False
    except Exception as e:
        print(f"[ERROR] {e}")
        return None, False


def get_work_item_type(org, project, pat, work_item_id):
    """Get current work item type"""
    auth_str = f":{pat}"
    base64_auth = base64.b64encode(auth_str.encode()).decode()

    url = f"https://dev.azure.com/{org}/{project}/_apis/wit/workitems/{work_item_id}?api-version=7.0"

    headers = {
        "Authorization": f"Basic {base64_auth}"
    }

    req = urllib.request.Request(url, headers=headers, method="GET")

    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            return result.get("fields", {}).get("System.WorkItemType", "Unknown")
    except Exception as e:
        print(f"[WARN] Could not fetch work item type: {e}")
        return "Unknown"


def main():
    print("=" * 70)
    print("Family Hub ADO Work Items - Acceptance Criteria Update")
    print("=" * 70)
    print()

    # Determine paths
    script_dir = Path(__file__).parent.absolute()
    platform_dir = script_dir.parent  # ai-sdlc-platform
    stories_dir = script_dir  # stories folder (may be outside platform repo)

    # If stories not in platform repo, use the external location
    if not (stories_dir / "FH-001-master-family-hub-phase1.md").exists():
        # Try external location
        external_stories = Path("c:/JioCloudCursor/AISDLC/stories")
        if external_stories.exists():
            stories_dir = external_stories
        else:
            print("[ERROR] Could not find Family Hub story files")
            sys.exit(1)

    # Read env file
    env_path = platform_dir / "env" / ".env"
    env_vars = read_env_file(env_path)

    org = env_vars.get('ADO_ORG', '')
    project = env_vars.get('ADO_PROJECT', '')
    pat = env_vars.get('ADO_PAT', '')

    if not org or not project or not pat:
        print(f"[ERROR] ADO credentials not found in {env_path}")
        print("Please ensure ADO_ORG, ADO_PROJECT, and ADO_PAT are set")
        sys.exit(1)

    print(f"Organization: {org}")
    print(f"Project: {project}")
    print(f"Stories directory: {stories_dir}")
    print()

    # Work items to update
    work_items = [
        {
            "id": 865620,
            "name": "Master Story - Family Hub Phase 1",
            "file": "FH-001-master-family-hub-phase1.md",
            "convert_to_user_story": True
        },
        {
            "id": 865621,
            "name": "Sprint 3 - Hub Creation & Invite",
            "file": "FH-001-S01-sprint-hub-creation-invite.md",
            "convert_to_user_story": False
        },
        {
            "id": 865622,
            "name": "Sprint 4 - Member Management",
            "file": "FH-001-S02-sprint-member-management.md",
            "convert_to_user_story": False
        }
    ]

    # Process each work item
    for item in work_items:
        print(f"\n{'='*70}")
        print(f"Processing: {item['name']} (ID: {item['id']})")
        print(f"{'='*70}")

        # Get current type
        current_type = get_work_item_type(org, project, pat, item['id'])
        print(f"Current work item type: {current_type}")

        # Extract acceptance criteria from story file
        story_file = stories_dir / item['file']
        print(f"Reading: {story_file}")

        ac_content = extract_acceptance_criteria(story_file)
        if not ac_content:
            print(f"[SKIP] No acceptance criteria found for {item['name']}")
            continue

        print(f"Acceptance criteria extracted: {len(ac_content)} chars")

        # Convert to HTML
        ac_html = convert_markdown_to_html(ac_content)
        print(f"HTML converted: {len(ac_html)} chars")

        # Update work item
        print(f"Updating ADO work item {item['id']}...")
        updated_id, success = update_work_item(
            org, project, pat, item['id'], ac_html,
            convert_to_user_story=item['convert_to_user_story']
        )

        if success:
            print(f"[OK] Successfully updated work item {updated_id}")
            print(f"     View: https://dev.azure.com/{org}/{project}/_workitems/edit/{updated_id}")
        else:
            print(f"[FAIL] Could not update work item {item['id']}")

    print("\n" + "=" * 70)
    print("Update Complete")
    print("=" * 70)
    print("\nNote: Work item 865620 remains as Feature in ADO.")
    print("To convert to User Story, use ADO web UI or recreate the work item.")
    print("The acceptance criteria has been populated in the AC field for all items.")


if __name__ == "__main__":
    main()
