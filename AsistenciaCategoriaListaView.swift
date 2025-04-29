//
//  AsistenciaCategoriaListaView.swift
//  ApprendiendoSalsa
//
//  Created by Christian Cruz on 21/4/25.
//

import SwiftUI
import SwiftData

struct AsistenciaCategoriaListaView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categorias: [ClaseCategoria]
    @Query private var alumnos: [Alumno]
    @Query private var pagos: [PagoLocal] // ✅ Para AsistenciaCategoriaView

    @State private var nuevaCategoria = ""
    @State private var mostrarAlertaEdicion = false
    @State private var categoriaSeleccionada: ClaseCategoria?
    @State private var nombreEditado = ""
    @State private var mostrarAlertaEliminacion = false
    @State private var categoriaAEliminar: ClaseCategoria?

    var body: some View {
        NavigationStack {
            List {
                // ➕ Crear nueva categoría
                Section(header: Text("Crear nueva categoría")) {
                    HStack {
                        TextField("Nombre de la categoría", text: $nuevaCategoria)
                            .textInputAutocapitalization(.words)

                        Button(action: crearCategoria) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(nuevaCategoria.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                // 📋 Lista de categorías
                Section(header: Text("Categorías existentes")) {
                    Group {
                        if categorias.isEmpty {
                            Group {
                                Text("No hay categorías todavía.")
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Group {
                                ForEach(categorias) { categoria in
                                    CategoriaRowView(categoria)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Asistencias")
            .alert("Editar nombre", isPresented: $mostrarAlertaEdicion) {
                TextField("Nuevo nombre", text: $nombreEditado)
                Button("Guardar", action: guardarEdicion)
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Introduce un nuevo nombre para la categoría.")
            }
            .alert("¿Eliminar categoría?", isPresented: $mostrarAlertaEliminacion) {
                Button("Eliminar", role: .destructive) {
                    if let categoria = categoriaAEliminar {
                        eliminarCategoria(categoria)
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("¿Estás seguro de que quieres eliminar esta categoría? Esta acción no se puede deshacer.")
            }
        }
    }

    // ✅ Crear categoría
    private func crearCategoria() {
        let nombre = nuevaCategoria.trimmingCharacters(in: .whitespaces)
        guard !nombre.isEmpty else { return }
        let nueva = ClaseCategoria(nombre: nombre, icono: "calendar")
        modelContext.insert(nueva)
        try? modelContext.save()
        nuevaCategoria = ""
    }

    // ✅ Eliminar categoría
    private func eliminarCategoria(_ categoria: ClaseCategoria) {
        modelContext.delete(categoria)
        try? modelContext.save()
    }

    // ✅ Guardar edición
    private func guardarEdicion() {
        guard let categoria = categoriaSeleccionada else { return }
        categoria.nombre = nombreEditado.trimmingCharacters(in: .whitespaces)
        try? modelContext.save()
    }

    // ✅ Subvista: Fila de categoría
    private func CategoriaRowView(_ categoria: ClaseCategoria) -> some View {
        let icono = categoria.icono ?? "calendar"
        let destino = AsistenciaCategoriaView(categoria: categoria, pagos: pagos)

        return NavigationLink(destination: destino) {
            Label(categoria.nombre, systemImage: icono)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                categoriaSeleccionada = categoria
                nombreEditado = categoria.nombre
                mostrarAlertaEdicion = true
            } label: {
                Label("Editar nombre", systemImage: "pencil")
            }

            Button {
                // ⚠️ Aquí irá la navegación a estadísticas
            } label: {
                Label("Estadísticas", systemImage: "chart.bar")
            }

            Button {
                // ⚠️ Aquí irá la lógica para cambiar el icono
            } label: {
                Label("Cambiar icono", systemImage: "paintbrush")
            }

            Button(role: .destructive) {
                categoriaAEliminar = categoria
                mostrarAlertaEliminacion = true
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}

#Preview {
    AsistenciaCategoriaListaView()
        .modelContainer(for: [ClaseCategoria.self, Alumno.self, PagoLocal.self], inMemory: true)
}
