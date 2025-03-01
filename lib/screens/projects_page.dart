import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/database_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({Key? key}) : super(key: key);

  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _projectController = TextEditingController();
  List<ProjectModel> projects = [];
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final loadedProjects = await _databaseService.getProjects();
    setState(() {
      projects = loadedProjects;
    });
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _addProject() async {
    if (_projectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }

    final project = ProjectModel(
      name: _projectController.text,
      color: _selectedColor.value.toRadixString(16),
    );

    await _databaseService.insertProject(project);
    _projectController.clear();
    await _loadProjects();
  }

  Future<void> _deleteProject(ProjectModel project) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('Are you sure you want to delete "${project.name}"? This will remove it from all tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _databaseService.deleteProject(project.id!);
      await _loadProjects();
    }
  }

  Future<void> _editProject(ProjectModel project) async {
    _projectController.text = project.name;
    _selectedColor = Color(int.parse(project.color ?? 'FF2196F3', radix: 16));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _projectController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _showColorPicker,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_projectController.text.isNotEmpty) {
                final updatedProject = ProjectModel(
                  id: project.id,
                  name: _projectController.text,
                  color: _selectedColor.value.toRadixString(16),
                );
                await _databaseService.updateProject(updatedProject);
                _projectController.clear();
                Navigator.pop(context);
                await _loadProjects();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _projectController,
                    decoration: const InputDecoration(
                      labelText: 'New Project',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addProject,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                final projectColor = Color(int.parse(project.color ?? 'FF2196F3', radix: 16));
                return ListTile(
                  leading: Icon(Icons.folder, color: projectColor),
                  title: Text(project.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editProject(project),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteProject(project),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _projectController.dispose();
    super.dispose();
  }
} 