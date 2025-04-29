//
//  PagosCategoriaView.swift
//  AprendiendoSalsa
//
//  Created by Christian Cruz on 21/4/25.
//

import SwiftUI

struct PagosCategoriaView: View {
    var categoria: ClaseCategoria
    var alumnos: [Alumno]

    var body: some View {
        List {
            Section(header: Text("Alumnos de \(categoria.nombre)")) {
                let alumnosDeEstaCategoria = alumnos.filter { $0.categoria == categoria.nombre && $0.activo }

                ForEach(alumnosDeEstaCategoria) { alumno in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alumno.nombre)
                            .font(.headline)

                        Text(alumno.email)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("💳 Aquí irá info de pago individual")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Pagos por categoría")
    }
}
