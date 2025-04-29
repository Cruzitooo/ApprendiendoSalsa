//
//  AsistenciasView.swift
//  AprendiendoSalsa
//
//  Created by Christian Cruz el 20/04/25.
//

import SwiftUI
import SwiftData

struct AsistenciasView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ClaseCategoria.orden) private var categorias: [ClaseCategoria]

    @State private var mostrarFormulario = false
    @State private var nuevaCategoria = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(categorias) { categoria in
                    NavigationLink(
                        destination: Text("Aquí iría la vista con los alumnos de \(categoria.nombre)")
                    ) {
                        Label("Clase \(categoria.nombre)", systemImage: "person.3.sequence")
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        context.delete(categorias[index])
                    }
                }
            }
            .navigationTitle("Asistencias")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrarFormulario = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $mostrarFormulario) {
                NavigationStack {
                    Form {
                        Section(header: Text("Nueva clase o intensivo")) {
                            TextField("Nombre de la clase", text: $nuevaCategoria)
                        }

                        Button("Guardar") {
                            let nueva = ClaseCategoria(nombre: nuevaCategoria, orden: categorias.count)
                            context.insert(nueva)
                            nuevaCategoria = ""
                            mostrarFormulario = false
                        }
                        .disabled(nuevaCategoria.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .navigationTitle("Nueva categoría")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") {
                                mostrarFormulario = false
                                nuevaCategoria = ""
                            }
                        }
                    }
                }
            }
        }
    }
}
