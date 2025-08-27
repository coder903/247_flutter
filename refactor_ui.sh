#!/bin/bash

# UI-Only Property to System Refactor
# This only changes visible text, not code structure

echo "=== UI-Only Property to System Label Changes ==="
echo "This will only change user-visible text, keeping code intact"
echo ""

# Check if we're in the right directory
if [ ! -d "lib" ]; then
    echo "Error: 'lib' directory not found. Run this from your Flutter project root."
    exit 1
fi

# Create backup
echo "Creating backup..."
cp -r lib lib_backup_ui_$(date +%Y%m%d_%H%M%S)
echo "Backup created."

# Function to update UI strings only
update_ui_strings() {
    echo ""
    echo "Updating UI strings..."
    
    find lib -name "*.dart" -type f | while read -r file; do
        temp_file="${file}.tmp"
        
        # Only replace user-visible strings
        sed -E \
            -e 's/"Properties"/"Fire Alarm Systems"/g' \
            -e 's/"Property"/"System"/g' \
            -e 's/"property"/"system"/g' \
            -e 's/"Select Property"/"Select Fire Alarm System"/g' \
            -e 's/"Add Property"/"Add System"/g' \
            -e 's/"Edit Property"/"Edit System"/g' \
            -e 's/"New Property"/"New System"/g' \
            -e 's/"Update Property"/"Update System"/g' \
            -e 's/"Create Property"/"Create System"/g' \
            -e 's/"Property Management"/"System Management"/g' \
            -e 's/"Property Name"/"System Name"/g' \
            -e 's/"Property Details"/"System Details"/g' \
            -e 's/"Property created"/"System created"/g' \
            -e 's/"Property updated"/"System updated"/g' \
            -e 's/"No properties found"/"No systems found"/g' \
            -e 's/"properties found"/"systems found"/g' \
            -e 's/"Tap the \+ button to add your first property"/"Tap the + button to add your first system"/g' \
            -e 's/Property #/System #/g' \
            -e "s/'Property'/'System'/g" \
            -e 's/`Property`/`System`/g' \
            -e 's/label: "Properties"/label: "Systems"/g' \
            -e 's/title: "Properties"/title: "Systems"/g' \
            -e 's/title: const Text\("Properties"\)/title: const Text("Fire Alarm Systems")/g' \
            -e 's/Text\("Properties"\)/Text("Fire Alarm Systems")/g' \
            -e 's/: "Properties",/: "Fire Alarm Systems",/g' \
            "$file" > "$temp_file"
        
        if ! cmp -s "$file" "$temp_file"; then
            mv "$temp_file" "$file"
            echo "Updated UI strings in: $file"
        else
            rm "$temp_file"
        fi
    done
}

# Main execution
echo ""
echo "This will change:"
echo "- 'Properties' → 'Fire Alarm Systems'"
echo "- 'Property' → 'System' (in UI text only)"
echo "- 'Select Property' → 'Select Fire Alarm System'"
echo "- etc."
echo ""
echo "But will NOT change:"
echo "- Variable names (property, propertyId, etc.)"
echo "- Class names (Property, PropertyRepository, etc.)"
echo "- Database tables or columns"
echo "- File names"
echo ""

read -p "Continue with UI-only changes? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "Cancelled."
    exit 0
fi

update_ui_strings

echo ""
echo "=== UI Label Update Complete ==="
echo ""
echo "Only user-visible text has been changed."
echo "The code structure remains intact."
echo ""
echo "To revert: rm -rf lib && mv lib_backup_ui_* lib"
echo ""