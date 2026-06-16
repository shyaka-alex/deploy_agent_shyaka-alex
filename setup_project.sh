#!/bin/bash

read -rp "Enter a project name suffix: " INPUT

if [[ -z "$INPUT" ]]; then
    echo "Error: Project name cannot be empty."
    exit 1
fi

PROJECT_DIR="attendance_tracker_${INPUT}"
ARCHIVE_NAME="attendance_tracker_${INPUT}_archive"


cleanup() {
    echo ""
    echo "Interrupt detected! Bundling current state before exit..."

    if [[ -d "$PROJECT_DIR" ]]; then
        tar -czf "${ARCHIVE_NAME}.tar.gz" "$PROJECT_DIR" 2>/dev/null
        echo "Archive saved as: ${ARCHIVE_NAME}.tar.gz"

        rm -rf "$PROJECT_DIR"
        echo "Incomplete directory '${PROJECT_DIR}' deleted."
    else
        echo "Nothing to archive - directory was not yet created."
    fi

    echo "Exiting cleanly."
    exit 1
}

trap cleanup SIGINT

# -- 2. Directory Architecture --------------------------------
echo ""
echo "Creating project structure: ${PROJECT_DIR}/"

if [[ -d "$PROJECT_DIR" ]]; then
    echo "Warning: '${PROJECT_DIR}' already exists. Contents may be overwritten."
fi

mkdir -p "${PROJECT_DIR}/Helpers"
mkdir -p "${PROJECT_DIR}/reports"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "Error: Failed to create project directory. Check permissions."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "${SCRIPT_DIR}/attendance_checker.py" "${PROJECT_DIR}/attendance_checker.py"
cp "${SCRIPT_DIR}/Helpers/assets.csv"    "${PROJECT_DIR}/Helpers/assets.csv"
cp "${SCRIPT_DIR}/Helpers/config.json"   "${PROJECT_DIR}/Helpers/config.json"
cp "${SCRIPT_DIR}/reports/reports.log"   "${PROJECT_DIR}/reports/reports.log"

echo "Directory structure created successfully."

# -- 3. Dynamic Configuration (sed) --------------------------
echo ""
read -rp "Would you like to update attendance thresholds? (yes/no): " UPDATE_THRESHOLDS

if [[ "$UPDATE_THRESHOLDS" =~ ^[Yy][Ee][Ss]|[Yy]$ ]]; then

    while true; do
        read -rp "Enter new WARNING threshold (default 75, must be 0-100): " WARNING_VAL
        WARNING_VAL="${WARNING_VAL:-75}"
        if [[ "$WARNING_VAL" =~ ^[0-9]+$ ]] && (( WARNING_VAL >= 0 && WARNING_VAL <= 100 )); then
            break
        else
            echo "Invalid input. Please enter a whole number between 0 and 100."
        fi
    done

    while true; do
        read -rp "Enter new FAILURE threshold (default 50, must be 0-100): " FAILURE_VAL
        FAILURE_VAL="${FAILURE_VAL:-50}"
        if [[ "$FAILURE_VAL" =~ ^[0-9]+$ ]] && (( FAILURE_VAL >= 0 && FAILURE_VAL <= 100 )); then
            break
        else
            echo "Invalid input. Please enter a whole number between 0 and 100."
        fi
    done

    CONFIG_FILE="${PROJECT_DIR}/Helpers/config.json"

    sed -i '' "s/\"warning\": [0-9]*/\"warning\": ${WARNING_VAL}/" "$CONFIG_FILE"
    sed -i '' "s/\"failure\": [0-9]*/\"failure\": ${FAILURE_VAL}/" "$CONFIG_FILE"

    echo "config.json updated - warning: ${WARNING_VAL}%, failure: ${FAILURE_VAL}%"
else
    echo "Keeping default thresholds (warning: 75%, failure: 50%)."
fi

# -- 4. Environment Validation --------------------------------
echo ""
echo "Running environment health check..."

if python3 --version &>/dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo "Python3 is installed: ${PYTHON_VERSION}"
else
    echo "Warning: python3 not found. The application may not run without it."
fi

echo ""
echo "Verifying directory structure..."
STRUCTURE_OK=true

for REQUIRED_PATH in \
    "${PROJECT_DIR}/attendance_checker.py" \
    "${PROJECT_DIR}/Helpers/assets.csv" \
    "${PROJECT_DIR}/Helpers/config.json" \
    "${PROJECT_DIR}/reports/reports.log"; do
    if [[ -f "$REQUIRED_PATH" ]]; then
        echo "  Found: ${REQUIRED_PATH}"
    else
        echo "  Missing: ${REQUIRED_PATH}"
        STRUCTURE_OK=false
    fi
done

if $STRUCTURE_OK; then
    echo ""
    echo "Setup complete! Project '${PROJECT_DIR}' is ready."
    echo "Run the tracker with:"
    echo "  cd ${PROJECT_DIR} && python3 attendance_checker.py"
else
    echo ""
    echo "Setup finished with warnings. Some files may be missing."
fi