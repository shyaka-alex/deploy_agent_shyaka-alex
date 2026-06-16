# Attendance Tracker - Project Bootstrapper

## How to Run
1. Make the script executable: chmod +x setup_project.sh
2. Run it: ./setup_project.sh
3. Enter a project name when prompted
4. Choose whether to update attendance thresholds (validated 0-100)
5. Script verifies python3 is installed and all files are in place

## How to Trigger the Archive Feature
Press Ctrl+C at any point after entering the project name.
The trap will bundle the current project directory into attendance_tracker_{name}_archive.tar.gz, delete the incomplete directory, and exit cleanly.

## Running the Application
cd attendance_tracker_{name}
python3 attendance_checker.py
