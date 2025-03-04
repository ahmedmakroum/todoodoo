# ToDoodoo

A comprehensive personal productivity and wellness tracking app built with Flutter. ToDoodoo helps you manage tasks, track workouts, monitor calories, and maintain focus sessions while providing daily statistics to keep you motivated.

## Features

### Task Management
- Create and manage daily tasks
- Organize tasks with labels and projects
- Support for repeating tasks
- Board view for kanban-style task management
- Calendar integration for scheduling

### Focus Timer
- Pomodoro-style focus timer
- Track daily focus minutes
- Session history and statistics

### Workout Planner
- Create custom workout plans
- Schedule workouts by day of the week
- Track sets, reps, and weights
- Mark workouts as completed

### Calorie Counter
- Log food intake with serving sizes
- Track calories by meal type
- Daily calorie goal tracking
- Meal history

### Daily Statistics
- Comprehensive daily activity tracking
- Stats for tasks completed
- Focus time monitoring
- Workout completion tracking
- Calorie intake summary
- Automatic midnight reset
- Daily achievement notifications

## Installation

1. Ensure you have Flutter installed on your machine
2. Clone this repository:
   ```bash
   git clone https://github.com/ahmedmakroum/todoodoo.git
   ```
3. Navigate to the project directory:
   ```bash
   cd todoodoo
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

- flutter_riverpod: State management
- sqflite: Local database storage
- flutter_local_notifications: Push notifications
- intl: Date formatting
- path: File path handling

## Usage

### Task Management
1. Click the '+' button to add a new task
2. Set task details including name, due date, and labels
3. View tasks in list, board, or calendar view
4. Swipe to complete or delete tasks

### Focus Timer
1. Navigate to the Timer tab
2. Set your desired focus duration
3. Start the timer and stay focused
4. Session will be automatically logged

### Workout Tracking
1. Go to the Workout tab
2. Create a new workout plan
3. Add exercises with sets, reps, and weights
4. Assign to specific days of the week

### Calorie Tracking
1. Access the Calories tab
2. Add food items with serving sizes
3. Select meal type (breakfast, lunch, dinner, snack)
4. Monitor daily calorie intake

### Daily Stats
1. View the Stats tab for daily achievements
2. See your progress over the last 7 days
3. Check notifications for daily summaries

## Auto-Reset Feature

The app automatically resets certain data at midnight:
- Completed non-repeating tasks are archived
- Repeating tasks are reset to pending
- Calorie entries are cleared
- Daily stats are saved before reset

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
