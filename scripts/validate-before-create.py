#!/usr/bin/env python3
"""
Mandatory PRD Coverage Validation - Run BEFORE creating Master/Sprint/Tech Stories or Tasks
Prevents ADO-865620-type gaps by enforcing PRD checklist compliance
"""

import os
import sys
import re
import subprocess

class PRDValidationError(Exception):
    """Raised when PRD coverage validation fails"""
    pass

def validate_story_before_create(story_file, story_type):
    """
    MANDATORY validation before any story creation or push
    
    Args:
        story_file: Path to the story markdown file
        story_type: 'Master', 'Sprint', 'Tech', or 'Task'
    
    Returns:
        True if validation passes
    
    Raises:
        PRDValidationError if validation fails with details
    """
    print(f"\n{'='*70}")
    print(f"MANDATORY PRD COVERAGE VALIDATION: {story_type} Story")
    print(f"{'='*70}")
    print(f"File: {story_file}")
    
    if not os.path.exists(story_file):
        raise PRDValidationError(f"Story file not found: {story_file}")
    
    # Read content
    with open(story_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    errors = []
    warnings = []
    
    # Check 1: PRD Coverage Matrix Section
    print("\n[Check 1] PRD Coverage Matrix Section...")
    if 'PRD Coverage Matrix' not in content and 'Coverage %' not in content:
        errors.append("Missing PRD Coverage Matrix section - REQUIRED per PRD_COVERAGE_CHECKLIST.md")
    else:
        print("  ✓ PRD Coverage Matrix section present")
    
    # Check 2: PRD Artifact Coverage
    print("\n[Check 2] PRD Artifact Coverage (N/R/S/D/E)...")
    
    n_count = len(re.findall(r'N\d+', content))
    r_count = len(re.findall(r'R\d+', content))
    s_count = len(re.findall(r'S\d+', content))
    d_count = len(re.findall(r'D\d+', content))
    e_count = len(re.findall(r'E\d+', content))
    
    print(f"  Found: N#={n_count}, R#={r_count}, S#={s_count}, D#={d_count}, E#={e_count}")
    
    if story_type == 'Master':
        # Master stories should have comprehensive coverage
        if n_count < 5:
            warnings.append(f"Low notification coverage (N#={n_count}, expected 10+)")
        if r_count < 3:
            warnings.append(f"Low rule coverage (R#={r_count}, expected 5+)")
        if s_count < 3:
            warnings.append(f"Low scenario coverage (S#={s_count}, expected 5+)")
        if d_count < 1:
            warnings.append(f"Low dependency coverage (D#={d_count}, expected 3+)")
        if e_count < 5:
            warnings.append(f"Low error coverage (E#={e_count}, expected 10+)")
    
    # Check 3: Common ADO-865620 Gaps
    print("\n[Check 3] Common Gap Prevention (ADO-865620 Lessons)...")
    
    # N4/N5 - Decline/Expiry notifications
    if 'N4' not in content or 'N5' not in content:
        errors.append("Missing N4/N5 (Decline/Expiry notifications with NO push behavior)")
    else:
        print("  ✓ N4/N5 present")
    
    # N7/N8 timing
    if 'N7' in content and 'N8' in content:
        if '60' not in content or 'second' not in content.lower():
            errors.append("N7+N8 timing requirement missing (must be 'within 60 seconds')")
        else:
            print("  ✓ N7+N8 timing requirement present")
    
    # R3 - X out of 5 display
    if 'R3' not in content and 'out of 5' not in content:
        errors.append("Missing R3 (member count 'X out of 5' display)")
    else:
        print("  ✓ R3 member count display present")
    
    # R5 - Declined invites hidden
    if 'R5' not in content and 'Declined' not in content:
        errors.append("Missing R5 (Declined invites NOT shown)")
    else:
        print("  ✓ R5 declined invites hidden present")
    
    # R6 - Resend behavior
    if 'R6' not in content and 'resend' not in content.lower():
        errors.append("Missing R6 (Resend behavior: new code, invalidates old)")
    else:
        print("  ✓ R6 resend behavior present")
    
    # S7 - Over-quota leave
    if 'S7' not in content:
        warnings.append("S7 (Over-quota leave scenario) not explicitly referenced")
    
    # S8 - Storage consumption order
    if 'S8' not in content and 'consumption order' not in content.lower():
        warnings.append("S8 (Storage consumption order) not explicitly referenced")
    
    # Check 4: Contradiction Checks
    print("\n[Check 4] Contradiction Prevention...")
    
    # Flow contradiction
    if 'confirms creation' in content.lower() or 'create family hub' in content.lower():
        if 'auto' not in content.lower() or 'background' not in content.lower():
            errors.append("Possible flow contradiction: 'Create' step mentioned without 'auto-created in background'")
    
    # Count contradiction
    if 'including owner' in content.lower():
        errors.append("CRITICAL: Member cap says 'including owner' - should be 'excluding owner' per PRD R3")
    
    # Leave dialog contradiction
    if 'your personal library is unaffected' in content.lower():
        errors.append("CRITICAL: Leave dialog has extra text 'Your personal library is unaffected' - should be 'Leave Family Hub?' only per PRD")
    
    # Check 5: Run bash validator if available
    print("\n[Check 5] Running prd-coverage-validator.sh...")
    
    validator_path = os.path.join(
        os.path.dirname(__file__), '..', 'templates', 'story-templates', 
        'validators', 'prd-coverage-validator.sh'
    )
    
    if os.path.exists(validator_path):
        try:
            result = subprocess.run(
                ['bash', validator_path, story_file],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if "CRITICAL" in result.stdout:
                errors.append("prd-coverage-validator.sh found CRITICAL issues")
            elif "warning" in result.stdout.lower():
                warnings.append("prd-coverage-validator.sh found warnings")
            else:
                print("  ✓ Bash validator passed")
                
        except Exception as e:
            warnings.append(f"Could not run bash validator: {e}")
    else:
        warnings.append("prd-coverage-validator.sh not found - manual review required")
    
    # Report Results
    print(f"\n{'='*70}")
    print("VALIDATION RESULTS")
    print(f"{'='*70}")
    
    if errors:
        print(f"\n✗ ERRORS ({len(errors)}):")
        for i, error in enumerate(errors, 1):
            print(f"  {i}. {error}")
    
    if warnings:
        print(f"\n⚠ WARNINGS ({len(warnings)}):")
        for i, warning in enumerate(warnings, 1):
            print(f"  {i}. {warning}")
    
    if not errors and not warnings:
        print("\n✓ ALL CHECKS PASSED")
    
    print(f"{'='*70}")
    
    # Decision
    if errors:
        print("\n❌ VALIDATION FAILED - Cannot proceed")
        print("\nFix the errors above before:")
        print("  - Creating the story in ADO")
        print("  - Pushing to Azure DevOps")
        print("  - Marking as ready for development")
        print("\nReference: templates/story-templates/PRD_COVERAGE_CHECKLIST.md")
        raise PRDValidationError(f"Validation failed with {len(errors)} error(s)")
    
    if warnings:
        print("\n⚠ VALIDATION PASSED WITH WARNINGS")
        print("Review warnings before proceeding.")
        # Don't block on warnings, but make them visible
    else:
        print("\n✅ VALIDATION PASSED - Ready to proceed")
    
    return True

def main():
    """CLI entry point"""
    if len(sys.argv) < 2:
        print("Usage: python validate-before-create.py <story-file.md> [story-type]")
        print("\nExample:")
        print("  python validate-before-create.py stories/FH-001-master.md Master")
        print("  python validate-before-create.py stories/SS-001-sprint.md Sprint")
        print("  python validate-before-create.py stories/TS-001-tech.md Tech")
        print("  python validate-before-create.py stories/TASK-001.md Task")
        sys.exit(1)
    
    story_file = sys.argv[1]
    story_type = sys.argv[2] if len(sys.argv) > 2 else 'Master'
    
    try:
        validate_story_before_create(story_file, story_type)
        sys.exit(0)
    except PRDValidationError as e:
        print(f"\nError: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
