//
//  DetalleAsistenciaAlumnoView.swift
//  ApprendiendoSalsa
//

import SwiftUI
import SwiftData
import AudioToolbox

struct DetalleAsistenciaAlumnoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var alumno: Alumno
    var categoria: ClaseCategoria
    var fecha: Date
    var pagos: [PagoLocal]

    @State private var asistenciaActual: Asistencia?
    @State private var asistenciasDelMes: [Asistencia] = []
    @State private var historialPagosAlumno: [PagoLocal] = []
    @State private var mostrandoRegistrarPagoEfectivo = false

    @State private var mostrarToast = false
    @State private var mensajeToast = ""

    var totalPagado: Double {
        historialPagosAlumno.reduce(0) { $0 + $1.importe }
    }

    var clasesCubiertas: Int {
        Int(totalPagado / 15)
    }

    var resumenAsistencias: String {
        let mes = nombreMes(fecha)
        let asistencias = asistenciasDelMes.filter { $0.asistio }.count
        let faltas = asistenciasDelMes.filter { !$0.asistio }.count
        return "\(mes) \(Calendar.current.component(.year, from: fecha)) – \(asistencias) asistencias ✅ / \(faltas) faltas ❌"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Alumno: \(alumno.nombre)")
                    .font(.title3.bold())

                Text("Categoría: \(alumno.categoria)")
                    .foregroundColor(.secondary)

                Text("Fecha seleccionada: \(formatearFechaCompleta(fecha))")
                    .foregroundColor(.secondary)

                if let asistencia = asistenciaActual {
                    Text("Asistencia registrada:")
                        .bold()

                    HStack(spacing: 12) {
                        Button(action: {
                            asistencia.asistio = true
                            asistencia.justificada = nil
                            guardarCambios()
                            mostrarMensajeToast("✅ Asistencia registrada")
                            vibracionYsonido()
                        }) {
                            Text("Asistió")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(asistencia.asistio ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            asistencia.asistio = false
                            asistencia.justificada = false
                            guardarCambios()
                            mostrarMensajeToast("❌ Falta registrada")
                            vibracionYsonido()
                        }) {
                            Text("No asistió")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(asistencia.asistio == false ? Color.red.opacity(0.2) : Color.gray.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }

                    if asistencia.asistio == false {
                        Picker("Justificación", selection: Binding(
                            get: { asistencia.justificada ?? false },
                            set: {
                                asistencia.justificada = $0
                                guardarCambios()
                                vibracionYsonido()
                            }
                        )) {
                            Text("Injustificada").tag(false)
                            Text("Justificada").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }

                } else {
                    Text("No hay asistencia registrada para esta fecha.")
                        .foregroundColor(.red)

                    HStack(spacing: 12) {
                        Button(action: {
                            let nueva = Asistencia(
                                fecha: fecha,
                                alumnoID: alumno.id,
                                categoriaID: categoria.id,
                                asistio: true,
                                justificada: nil
                            )
                            modelContext.insert(nueva)
                            asistenciaActual = nueva
                            asistenciasDelMes.append(nueva)
                            guardarCambios()
                            mostrarMensajeToast("✅ Asistencia registrada")
                            vibracionYsonido()
                        }) {
                            Text("Registrar asistencia")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            let nueva = Asistencia(
                                fecha: fecha,
                                alumnoID: alumno.id,
                                categoriaID: categoria.id,
                                asistio: false,
                                justificada: false
                            )
                            modelContext.insert(nueva)
                            asistenciaActual = nueva
                            asistenciasDelMes.append(nueva)
                            guardarCambios()
                            mostrarMensajeToast("❌ Falta registrada")
                            vibracionYsonido()
                        }) {
                            Text("Registrar falta")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Total pagado este mes: ") + Text(totalPagado, format: .currency(code: "EUR"))
                    Text("Clases cubiertas: \(clasesCubiertas)")
                        .foregroundColor(.red)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Resumen de asistencias del mes:")
                        .bold()
                    Text(resumenAsistencias)
                        .foregroundColor(.primary)

                    if asistenciasDelMes.isEmpty {
                        Text("No hay asistencias registradas este mes.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(asistenciasDelMes.sorted(by: { $0.fecha < $1.fecha })) { asistencia in
                            HStack {
                                Text(formatearFechaCompleta(asistencia.fecha))
                                    .font(.subheadline)
                                Spacer()
                                Text(asistencia.asistio ? "✅" : "❌")
                            }
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Historial de pagos del alumno:")
                        .bold()

                    if historialPagosAlumno.isEmpty {
                        Text("No hay pagos registrados.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(historialPagosAlumno.sorted(by: { $0.fecha > $1.fecha })) { pago in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(formatearFechaCompleta(pago.fecha)) — \(pago.concepto)")
                                    .font(.subheadline)
                                Text("Importe: ") + Text(pago.importe, format: .currency(code: "EUR"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 6)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { mostrandoRegistrarPagoEfectivo = true }) {
                        Label("Registrar pago en efectivo", systemImage: "eurosign.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Detalles del Alumno")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cargarAsistencia()
        }
        .sheet(isPresented: $mostrandoRegistrarPagoEfectivo) {
            NavigationStack {
                RegistrarPagoEfectivoView(alumno: alumno)
            }
        }
        .overlay(
            VStack {
                if mostrarToast {
                    Text(mensajeToast)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                }
                Spacer()
            }
            .animation(.easeInOut, value: mostrarToast)
        )
    }

    private func guardarCambios() {
        do {
            try modelContext.save()
        } catch {
            print("Error al guardar cambios: \(error)")
        }
    }

    private func cargarAsistencia() {
        let todas = try? modelContext.fetch(FetchDescriptor<Asistencia>())
        asistenciaActual = todas?.first(where: {
            $0.alumnoID == alumno.id &&
            $0.categoriaID == categoria.id &&
            Calendar.current.isDate($0.fecha, inSameDayAs: fecha)
        })

        asistenciasDelMes = todas?.filter {
            $0.alumnoID == alumno.id &&
            Calendar.current.isDate($0.fecha, equalTo: fecha, toGranularity: .month)
        } ?? []

        historialPagosAlumno = pagos.filter { $0.alumnoID == alumno.id }
    }

    private func formatearFechaCompleta(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .full
        return formatter.string(from: fecha)
    }

    private func nombreMes(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.monthSymbols[Calendar.current.component(.month, from: fecha) - 1].capitalized
    }

    private func vibracionYsonido() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        AudioServicesPlaySystemSound(1104)
    }

    private func mostrarMensajeToast(_ mensaje: String) {
        mensajeToast = mensaje
        mostrarToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                mostrarToast = false
            }
        }
    }
}
