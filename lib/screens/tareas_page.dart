import 'package:flutter/material.dart';

import '../data/tareas_repository.dart';
import '../models/tarea.dart';

enum _Filtro { todas, pendientes, completadas }

class TareasPage extends StatefulWidget {
  const TareasPage({super.key, required this.repositorio});

  final TareasRepository repositorio;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  // El stream se crea una sola vez: build() nunca consulta la base.
  late final Stream<List<Tarea>> _tareas = widget.repositorio.observar();
  _Filtro _filtro = _Filtro.todas;

  /// Ejecuta una operación de almacenamiento y muestra un mensaje claro si falla.
  Future<bool> _ejecutar(Future<void> Function() accion) async {
    try {
      await accion();
      return true;
    } on TituloInvalidoException catch (e) {
      _mensaje(e.mensaje);
    } catch (_) {
      _mensaje('No se pudo guardar en la base de datos. Intenta de nuevo.');
    }
    return false;
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _agregarTarea() async {
    final ok = await _ejecutar(
      () => widget.repositorio.agregar(_tituloController.text),
    );
    if (ok) _tituloController.clear();
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) => _ejecutar(
        () => widget.repositorio.marcarCompletada(tarea.id, completada),
      );

  Future<void> _editarTarea(Tarea tarea) async {
    final controller = TextEditingController(text: tarea.titulo);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar título'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: TareasRepository.largoMaximo,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nuevo == null) return;
    await _ejecutar(() => widget.repositorio.editarTitulo(tarea.id, nuevo));
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final ok = await _ejecutar(() => widget.repositorio.eliminar(tarea.id));
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Tarea eliminada: ${tarea.titulo}'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () =>
                _ejecutar(() => widget.repositorio.restaurar(tarea)),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas'), centerTitle: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: StreamBuilder<List<Tarea>>(
              stream: _tareas,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _Vacio(
                    icono: Icons.error_outline,
                    texto: 'No se pudo leer la base de datos',
                  );
                }
                final todas = snapshot.data ?? const <Tarea>[];
                final visibles = switch (_filtro) {
                  _Filtro.todas => todas,
                  _Filtro.pendientes =>
                    todas.where((t) => !t.completada).toList(),
                  _Filtro.completadas =>
                    todas.where((t) => t.completada).toList(),
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Progreso(tareas: todas),
                    const SizedBox(height: 16),
                    _formulario(),
                    const SizedBox(height: 16),
                    SegmentedButton<_Filtro>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                            value: _Filtro.todas, label: Text('Todas')),
                        ButtonSegment(
                            value: _Filtro.pendientes,
                            label: Text('Pendientes')),
                        ButtonSegment(
                            value: _Filtro.completadas, label: Text('Hechas')),
                      ],
                      selected: {_filtro},
                      onSelectionChanged: (s) =>
                          setState(() => _filtro = s.first),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _lista(snapshot, todas, visibles)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _tituloController,
            textInputAction: TextInputAction.done,
            maxLength: TareasRepository.largoMaximo,
            onSubmitted: (_) => _agregarTarea(),
            decoration: const InputDecoration(
              labelText: 'Nueva tarea',
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: FilledButton.icon(
            onPressed: _agregarTarea,
            icon: const Icon(Icons.add),
            label: const Text('Agregar tarea'),
          ),
        ),
      ],
    );
  }

  Widget _lista(
    AsyncSnapshot<List<Tarea>> snapshot,
    List<Tarea> todas,
    List<Tarea> visibles,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (todas.isEmpty) {
      return const _Vacio(
        icono: Icons.checklist_rounded,
        texto: 'Todavía no hay tareas guardadas',
      );
    }
    if (visibles.isEmpty) {
      return const _Vacio(
        icono: Icons.filter_list_off,
        texto: 'No hay tareas en este filtro',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: visibles.length,
      itemBuilder: (context, index) {
        final tarea = visibles[index];
        return _TareaTile(
          key: ValueKey(tarea.id),
          tarea: tarea,
          onToggle: (v) => _alternarCompletada(tarea, v),
          onEditar: () => _editarTarea(tarea),
          onEliminar: () => _eliminarTarea(tarea),
        );
      },
    );
  }
}

/// Tarjeta superior con el avance general.
class _Progreso extends StatelessWidget {
  const _Progreso({required this.tareas});

  final List<Tarea> tareas;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hechas = tareas.where((t) => t.completada).length;
    final total = tareas.length;
    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              total == 0
                  ? 'Sin tareas por ahora'
                  : '$hechas de $total completadas',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : hechas / total,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TareaTile extends StatelessWidget {
  const _TareaTile({
    super.key,
    required this.tarea,
    required this.onToggle,
    required this.onEditar,
    required this.onEliminar,
  });

  final Tarea tarea;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('dismiss-${tarea.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onEliminar(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Checkbox(
            value: tarea.completada,
            onChanged: (v) {
              if (v != null) onToggle(v);
            },
          ),
          title: Text(
            tarea.titulo,
            style: tarea.completada
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: scheme.onSurfaceVariant,
                  )
                : null,
          ),
          subtitle: Text('ID: ${tarea.id}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEditar,
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
                onPressed: onEliminar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 56, color: color),
          const SizedBox(height: 12),
          Text(texto, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
