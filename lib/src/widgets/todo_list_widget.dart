import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TodoItem {
  final String id;
  String text;
  bool isCompleted;
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    required this.createdAt,
  });

  TodoItem copyWith({String? text, bool? isCompleted}) {
    return TodoItem(
      id: id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}

class TodoListWidget extends StatefulWidget {
  final List<TodoItem> todos;
  final Function(List<TodoItem>) onTodosChanged;
  final String? title;
  final Function(String)? onTitleChanged;
  final VoidCallback? onDelete;

  const TodoListWidget({
    super.key,
    required this.todos,
    required this.onTodosChanged,
    this.title,
    this.onTitleChanged,
    this.onDelete,
  });

  @override
  State<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends State<TodoListWidget> {
  late List<TodoItem> _todos;
  late String _title;
  String? _editingTodoId;
  String? _titleEditingId;
  TextEditingController? _titleController;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _todos = List.from(widget.todos);
    _title = widget.title ?? 'Yapılacaklar Listesi';
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _titleController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TodoListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.todos != oldWidget.todos) {
      _todos = List.from(widget.todos);
      // If a new empty todo was added externally, focus it for inline edit
      final emptyNew = _todos.where((t) => (t.text.trim().isEmpty)).toList();
      if (emptyNew.isNotEmpty) {
        emptyNew.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final newestEmpty = emptyNew.first;
        _editingTodoId = newestEmpty.id;
        _controllers[newestEmpty.id] = TextEditingController(
          text: newestEmpty.text,
        );
      }
    }
    if (widget.title != oldWidget.title && widget.title != null) {
      _title = widget.title!;
    }
  }

  void _addTodo() {
    final hasEmpty = _todos.any((todo) => todo.text.trim().isEmpty);
    if (hasEmpty) {
      return;
    }
    final newTodo = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '',
      createdAt: DateTime.now(),
    );
    setState(() {
      _todos.insert(0, newTodo);
      _editingTodoId = newTodo.id;
      _controllers[newTodo.id] = TextEditingController(text: '');
    });
    widget.onTodosChanged(_todos);
  }

  void _toggleTodo(String id) {
    setState(() {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todos[index] = _todos[index].copyWith(
          isCompleted: !_todos[index].isCompleted,
        );
      }
    });
    widget.onTodosChanged(_todos);
  }

  void _updateTodoText(String id, String newText) {
    setState(() {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todos[index] = _todos[index].copyWith(text: newText);
      }
    });
    widget.onTodosChanged(_todos);
  }

  void _deleteTodo(String id) {
    setState(() {
      if (_editingTodoId == id) {
        _editingTodoId = null;
      }
      final controller = _controllers.remove(id);
      controller?.dispose();
      _todos.removeWhere((todo) => todo.id == id);
    });
    widget.onTodosChanged(_todos);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.checkmark_alt,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _titleEditingId == 'title'
                    ? CupertinoTextField.borderless(
                        controller: _titleController ??= TextEditingController(
                          text: _title,
                        ),
                        autofocus: true,
                        style: headlineStyle,
                        cursorColor: theme.colorScheme.primary,
                        placeholder: 'Yapılacaklar',
                        onSubmitted: (_) => _saveTitleEdit(),
                      )
                    : GestureDetector(
                        onTap: _startTitleEdit,
                        child: Text(_title, style: headlineStyle),
                      ),
              ),
              const SizedBox(width: 8),
              if (_titleEditingId == 'title')
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 28,
                      onPressed: _saveTitleEdit,
                      child: Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              if (_titleEditingId != 'title')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      onPressed: _addTodo,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          CupertinoIcons.add_circled_solid,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      onPressed: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('Yapılacaklar Listesini Sil'),
                            content: const Text(
                              'Bu yapılacaklar listesini silmek istediğinizden emin misiniz?',
                            ),
                            actions: [
                              CupertinoDialogAction(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('İptal'),
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onDelete?.call();
                                },
                                child: const Text('Sil'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          CupertinoIcons.delete_solid,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Henüz görev eklenmemiş',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _todos.length,
              itemBuilder: (context, index) => _buildTodoItem(_todos[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(TodoItem todo) {
    final isEditing = _editingTodoId == todo.id;

    if (isEditing) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 32,
              onPressed: () => _toggleTodo(todo.id),
              child: Icon(
                todo.isCompleted
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                size: 22,
                color: todo.isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoTextField.borderless(
                controller: _controllers[todo.id] ??= TextEditingController(
                  text: todo.text,
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: todo.isCompleted
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.onSurface,
                  decoration: todo.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
                autofocus: true,
                cursorColor: Theme.of(context).colorScheme.primary,
                placeholder: 'Görev detayını yaz',
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 28,
              onPressed: () => _saveEdit(todo.id),
              child: Icon(
                CupertinoIcons.check_mark,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Dismissible(
      key: ValueKey('todo-${todo.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteTodo(todo.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          CupertinoIcons.delete_solid,
          color: CupertinoColors.white,
          size: 22,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 32,
              onPressed: () => _toggleTodo(todo.id),
              child: Icon(
                todo.isCompleted
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                size: 22,
                color: todo.isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _startEdit(todo),
                child: Text(
                  todo.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startEdit(TodoItem todo) {
    setState(() {
      _editingTodoId = todo.id;
      _controllers[todo.id] ??= TextEditingController(text: todo.text);
    });
  }

  void _saveEdit(String id) {
    final controller = _controllers[id];
    if (controller == null) {
      return;
    }
    final trimmed = controller.text.trim();
    if (trimmed.isEmpty) {
      _deleteTodo(id);
      return;
    }
    _updateTodoText(id, trimmed);
    setState(() {
      _editingTodoId = null;
    });
  }

  void _startTitleEdit() {
    setState(() {
      _titleEditingId = 'title';
      _titleController ??= TextEditingController(text: _title);
    });
  }

  void _saveTitleEdit() {
    if (_titleController != null && _titleController!.text.trim().isNotEmpty) {
      setState(() {
        _title = _titleController!.text.trim();
        _titleEditingId = null;
      });
      widget.onTitleChanged?.call(_title);
    }
  }
}
