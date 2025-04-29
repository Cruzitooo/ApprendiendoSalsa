//
//  PagoAlumnoView.swift
//  ApprendiendoSalsa
//

import SwiftUI
import SwiftData

struct PagoAlumnoView: View {
    let alumnoNombre: String
    let alumno: Alumno

    @Environment(\.modelContext) var modelContext

    @State private var conceptoSeleccionado: String = ""
    @State private var nuevoConcepto: String = ""
    @State private var enlaceGenerado: String? = nil
    @State private var importe: String = ""
    @State private var historialPagos: [PagoLocal] = []
    @State private var filtroEstado: String = "Todos"
    @ObservedObject private var gestor = ConceptosManager()

    let estados = ["Todos", "Pendiente", "Pagado"]

    var pagosFiltrados: [PagoLocal] {
        if filtroEstado == "Todos" {
            return historialPagos
        } else {
            return historialPagos.filter { $0.estado == filtroEstado }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Alumno")) {
                    Text(alumnoNombre)
                }

                Section(header: Text("Concepto")) {
                    Picker("Selecciona concepto", selection: $conceptoSeleccionado) {
                        ForEach(gestor.conceptos, id: \.self) { concepto in
                            Text(concepto).tag(concepto)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("Nuevo concepto", text: $nuevoConcepto)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Button("Añadir") {
                            gestor.añadir(nuevoConcepto)
                            conceptoSeleccionado = nuevoConcepto
                            nuevoConcepto = ""
                        }
                        .disabled(nuevoConcepto.trimmingCharacters(in: .whitespaces).isEmpty)

                        Button("Eliminar seleccionado") {
                            gestor.eliminar(conceptoSeleccionado)
                            conceptoSeleccionado = gestor.conceptos.first ?? ""
                        }
                        .disabled(conceptoSeleccionado.isEmpty)
                    }
                }

                Section(header: Text("Importe (€)")) {
                    TextField("Introduce el importe", text: $importe)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Enlace de pago")) {
                    Button("Generar enlace") {
                        generarEnlacePagoReal(nombre: alumnoNombre, concepto: conceptoSeleccionado, importe: importe) { enlace in
                            if let enlace = enlace {
                                enlaceGenerado = enlace

                                // Crear nuevo PagoAppStripe
                                let nuevoPagoStripe = PagoAppStripe(
                                    alumnoNombre: alumnoNombre,
                                    concepto: conceptoSeleccionado,
                                    importe: Double(importe) ?? 0,
                                    estado: "pendiente",
                                    metodoPago: "stripe",
                                    stripeId: nil
                                )
                                modelContext.insert(nuevoPagoStripe)

                                // Crear nuevo PagoLocal también
                                let nuevoPagoLocal = PagoLocal(
                                    concepto: conceptoSeleccionado,
                                    importe: Double(importe) ?? 0,
                                    fecha: Date(),
                                    estado: "Pendiente",
                                    alumnoID: alumno.id
                                )
                                modelContext.insert(nuevoPagoLocal)

                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Error al guardar el pago: \(error)")
                                }

                                historialPagos.insert(nuevoPagoLocal, at: 0)
                            } else {
                                enlaceGenerado = "Error al generar el enlace"
                            }
                        }
                    }
                    .disabled(conceptoSeleccionado.isEmpty || importe.trimmingCharacters(in: .whitespaces).isEmpty)

                    if let enlace = enlaceGenerado {
                        VStack(alignment: .leading) {
                            Text("Enlace generado:")
                                .font(.caption)
                            Text(enlace)
                                .font(.footnote)
                                .foregroundColor(.blue)
                                .contextMenu {
                                    Button(action: {
                                        UIPasteboard.general.string = enlace
                                    }) {
                                        Label("Copiar enlace", systemImage: "doc.on.doc")
                                    }
                                }
                        }
                    }
                }

                Section(header: Text("Filtro por estado")) {
                    Picker("Estado", selection: $filtroEstado) {
                        ForEach(estados, id: \.self) { estado in
                            Text(estado).tag(estado)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Historial de pagos")) {
                    if pagosFiltrados.isEmpty {
                        Text("Sin pagos registrados")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(pagosFiltrados) { pago in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(pago.concepto) - \(pago.importe, specifier: "%.2f")€")
                                    .font(.headline)
                                Text(pago.fecha.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Estado: \(pago.estado)")
                                    .font(.caption2)
                                    .foregroundColor(pago.estado == "Pagado" ? .green : .orange)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Pago Individual")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }

    func generarEnlacePagoReal(nombre: String, concepto: String, importe: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://stripe-backend-apprendiendo.onrender.com/crear-enlace") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "alumno": nombre,
            "concepto": concepto,
            "importe": importe
        ]

        guard let jsonData = try? JSONEncoder().encode(body) else {
            completion(nil)
            return
        }

        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let decoded = try? JSONDecoder().decode([String: String].self, from: data),
               let url = decoded["url"] {
                DispatchQueue.main.async {
                    completion(url)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}
